import Foundation
import SwiftUI

@MainActor
final class TaskStore: ObservableObject {
    @Published var rows: [TaskRow]
    @Published var rowSpacing: RowSpacing
    @Published var colWidths: ColumnWidths
    @Published var searchText: String = ""
    @Published var isSaving: Bool = false
    @Published var recentlyDeleted: DeletedRowSnapshot? = nil
    @Published private(set) var lastColumnBackup: [TaskColumn: [UUID: Bool]] = [:]

    private let rowsKey = "maple_ios_rows_v1"
    private let spacingKey = "maple_ios_spacing_v1"
    private let colWidthsKey = "maple_ios_colWidths_v1"

    private var saveTask: Task<Void, Never>?
    private var undoHideTask: Task<Void, Never>?

    init() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: rowsKey),
           let decoded = try? JSONDecoder().decode([TaskRow].self, from: data),
           !decoded.isEmpty {
            self.rows = decoded
        } else {
            self.rows = TaskRow.makeDefaults()
        }

        if let rawSpacing = defaults.string(forKey: spacingKey),
           let decodedSpacing = RowSpacing(rawValue: rawSpacing) {
            self.rowSpacing = decodedSpacing
        } else {
            self.rowSpacing = .cozy
        }

        if let data = defaults.data(forKey: colWidthsKey),
           let decodedWidths = try? JSONDecoder().decode(ColumnWidths.self, from: data) {
            self.colWidths = decodedWidths
        } else {
            self.colWidths = ColumnWidths()
        }
    }

    var filteredRows: [TaskRow] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return rows }
        return rows.filter { row in
            row.title.lowercased().contains(query) || row.col4.lowercased().contains(query)
        }
    }

    func text(for target: EditingTarget) -> String {
        guard let row = rows.first(where: { $0.id == target.rowID }) else { return "" }
        switch target {
        case .title:
            return row.title
        case .col4:
            return row.col4
        }
    }

    func setText(_ newValue: String, for target: EditingTarget) {
        guard let idx = rows.firstIndex(where: { $0.id == target.rowID }) else { return }
        switch target {
        case .title:
            if rows[idx].title != newValue {
                rows[idx].title = newValue
                scheduleSave()
            }
        case .col4:
            if rows[idx].col4 != newValue {
                rows[idx].col4 = newValue
                scheduleSave()
            }
        }
    }

    func rowIndex(for id: UUID) -> Int? {
        filteredRows.firstIndex(where: { $0.id == id })
    }

    func toggleCheckbox(id: UUID, column: TaskColumn) {
        guard let idx = rows.firstIndex(where: { $0.id == id }) else { return }
        Haptics.light()
        withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
            rows[idx][keyPath: column.keyPath].toggle()
        }
        scheduleSave()
    }

    func isColumnRestorable(_ column: TaskColumn) -> Bool {
        guard !rows.isEmpty else { return false }
        let isAllUnchecked = rows.allSatisfy { !$0[keyPath: column.keyPath] }
        return isAllUnchecked && lastColumnBackup[column] != nil
    }

    func handleClearColumn(_ column: TaskColumn) {
        Haptics.medium()
        let isAllUnchecked = rows.allSatisfy { !$0[keyPath: column.keyPath] }
        if isAllUnchecked, let backup = lastColumnBackup[column] {
            withAnimation(.easeInOut(duration: 0.18)) {
                for idx in rows.indices {
                    rows[idx][keyPath: column.keyPath] = backup[rows[idx].id] ?? false
                }
                lastColumnBackup[column] = nil
            }
        } else {
            var snapshot: [UUID: Bool] = [:]
            for row in rows {
                snapshot[row.id] = row[keyPath: column.keyPath]
            }
            lastColumnBackup[column] = snapshot
            withAnimation(.easeInOut(duration: 0.18)) {
                for idx in rows.indices {
                    rows[idx][keyPath: column.keyPath] = false
                }
            }
        }
        scheduleSave()
    }

    @discardableResult
    func addNewRow() -> UUID {
        Haptics.light()
        if !searchText.isEmpty {
            searchText = ""
        }
        let newRow = TaskRow(title: "", col1: false, col2: false, col3: false, col4: "")
        withAnimation(.easeOut(duration: 0.2)) {
            rows.append(newRow)
        }
        scheduleSave()
        return newRow.id
    }

    func deleteRow(id: UUID) {
        guard let idx = rows.firstIndex(where: { $0.id == id }) else { return }
        Haptics.warning()
        let removed = rows[idx]
        withAnimation(.easeInOut(duration: 0.2)) {
            rows.remove(at: idx)
            recentlyDeleted = DeletedRowSnapshot(row: removed, index: idx)
        }
        scheduleSave()

        undoHideTask?.cancel()
        undoHideTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self?.recentlyDeleted = nil
            }
        }
    }

    func undoDelete() {
        guard let snapshot = recentlyDeleted else { return }
        Haptics.success()
        undoHideTask?.cancel()
        let targetIndex = min(snapshot.index, rows.count)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            rows.insert(snapshot.row, at: targetIndex)
            recentlyDeleted = nil
        }
        scheduleSave()
    }

    func moveRow(id: UUID, direction: Int) {
        guard let idx = rows.firstIndex(where: { $0.id == id }) else { return }
        let targetIdx = idx + direction
        guard targetIdx >= 0 && targetIdx < rows.count else { return }
        Haptics.light()
        withAnimation(.easeInOut(duration: 0.18)) {
            rows.swapAt(idx, targetIdx)
        }
        scheduleSave()
    }

    func resetToDefault() {
        Haptics.medium()
        undoHideTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            rows = TaskRow.makeDefaults()
            lastColumnBackup = [:]
            searchText = ""
            recentlyDeleted = nil
        }
        persistNow()
    }

    func setSpacing(_ spacing: RowSpacing) {
        Haptics.light()
        withAnimation(.easeInOut(duration: 0.18)) {
            rowSpacing = spacing
        }
        scheduleSave()
    }

    func updateTitleWidth(_ value: CGFloat) {
        colWidths.title = value.rounded()
        scheduleSave()
    }

    func updateCol4Width(_ value: CGFloat) {
        colWidths.col4 = value.rounded()
        scheduleSave()
    }

    func shareSummaryText() -> String {
        var lines: [String] = ["🍁 楓 - 任務列表"]
        for row in rows {
            let displayTitle = row.title.isEmpty ? "未命名任務" : row.title
            let c1 = row.col1 ? "✅" : "⬜"
            let c2 = row.col2 ? "✅" : "⬜"
            let c3 = row.col3 ? "✅" : "⬜"
            let note = row.col4.trimmingCharacters(in: .whitespacesAndNewlines)
            let notePart = note.isEmpty ? "" : "｜\(note)"
            lines.append("\(displayTitle)  掛\(c1) 副\(c2) 活\(c3)\(notePart)")
        }
        return lines.joined(separator: "\n")
    }

    func exportBackupJSON() -> String? {
        let payload = BackupPayload(
            version: 1,
            rows: rows,
            spacing: rowSpacing,
            colWidths: colWidths
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func importBackupJSON(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8),
              let payload = try? JSONDecoder().decode(BackupPayload.self, from: data),
              !payload.rows.isEmpty else {
            return false
        }
        Haptics.success()
        withAnimation(.easeInOut(duration: 0.2)) {
            rows = payload.rows
            rowSpacing = payload.spacing
            colWidths = payload.colWidths
            lastColumnBackup = [:]
            searchText = ""
            recentlyDeleted = nil
        }
        persistNow()
        return true
    }

    func scheduleSave() {
        isSaving = true
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            self?.persistNow()
        }
    }

    private func persistNow() {
        let defaults = UserDefaults.standard
        if let encodedRows = try? JSONEncoder().encode(rows) {
            defaults.set(encodedRows, forKey: rowsKey)
        }
        defaults.set(rowSpacing.rawValue, forKey: spacingKey)
        if let encodedWidths = try? JSONEncoder().encode(colWidths) {
            defaults.set(encodedWidths, forKey: colWidthsKey)
        }
        isSaving = false
    }
}
