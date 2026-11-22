import SwiftUI

struct TaskTableView: View {
    @ObservedObject var store: TaskStore
    @Binding var editingTarget: EditingTarget?
    @Binding var scrollToRowID: UUID?
    let isReorderMode: Bool
    let onSelectCell: (EditingTarget) -> Void
    let onDismissEditing: () -> Void

    private let headerHeight: CGFloat = 46

    var body: some View {
        GeometryReader { geo in
            let availableWidth = max(geo.size.width - 32, 280)
            let fixedPrefixWidth = store.colWidths.title
                + store.colWidths.col1
                + store.colWidths.col2
                + store.colWidths.col3
                + 4
            let effectiveCol4Width = max(store.colWidths.col4, availableWidth - fixedPrefixWidth)
            let totalTableWidth = fixedPrefixWidth + effectiveCol4Width
            let cardHeight = max(geo.size.height - 12, 160)

            ScrollViewReader { hProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        Color.clear
                            .frame(width: 1, height: 1)
                            .id("tableLeftEdge")

                        VStack(spacing: 0) {
                            // 1. Permanently Pinned Table Header
                            tableHeader(effectiveCol4Width: effectiveCol4Width)

                            Rectangle()
                                .fill(AppColors.border)
                                .frame(height: 1)

                            // 2. Vertically Scrollable Task Rows
                            ScrollViewReader { vProxy in
                                ScrollView(.vertical, showsIndicators: false) {
                                    VStack(spacing: 0) {
                                        if store.filteredRows.isEmpty {
                                            emptySearchView(width: totalTableWidth)
                                        } else {
                                            ForEach(Array(store.filteredRows.enumerated()), id: \.element.id) { index, row in
                                                TaskRowView(
                                                    row: row,
                                                    rowIndex: index,
                                                    totalCount: store.filteredRows.count,
                                                    isReorderMode: isReorderMode,
                                                    store: store,
                                                    editingTarget: editingTarget,
                                                    effectiveCol4Width: effectiveCol4Width,
                                                    onSelectCell: onSelectCell,
                                                    onDismissEditing: onDismissEditing
                                                )
                                                .id(row.id)

                                                Rectangle()
                                                    .fill(AppColors.border)
                                                    .frame(height: 1)
                                            }
                                        }

                                        // Bottom breathing space so bottom rows (e.g. Row 7/8) scroll cleanly above keyboard & editor bar
                                        Color.clear
                                            .frame(height: editingTarget != nil ? max(cardHeight * 0.85, 500) : 24)
                                            .transaction { $0.animation = nil }
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                if editingTarget != nil {
                                                    onDismissEditing()
                                                }
                                            }
                                    }
                                }
                                .onValueChange(of: scrollToRowID) { targetID in
                                    guard let targetID = targetID else { return }
                                    Task { @MainActor in
                                        try? await Task.sleep(nanoseconds: 100_000_000)
                                        withAnimation(.easeOut(duration: 0.24)) {
                                            vProxy.scrollTo(targetID, anchor: UnitPoint(x: 0.5, y: 0.25))
                                        }
                                        scrollToRowID = nil
                                    }
                                }
                                .onValueChange(of: editingTarget) { newTarget in
                                    if newTarget == nil, let firstID = store.filteredRows.first?.id, store.filteredRows.count <= 10 {
                                        Task { @MainActor in
                                            try? await Task.sleep(nanoseconds: 80_000_000)
                                            withAnimation(.easeOut(duration: 0.22)) {
                                                vProxy.scrollTo(firstID, anchor: .top)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: totalTableWidth, height: cardHeight, alignment: .top)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        .padding(.leading, 15)
                        .padding(.trailing, 16)
                        .padding(.bottom, 12)
                    }
                }
                .onValueChange(of: editingTarget) { newTarget in
                    if newTarget == nil {
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 60_000_000)
                            withAnimation(.easeOut(duration: 0.25)) {
                                hProxy.scrollTo("tableLeftEdge", anchor: .leading)
                            }
                        }
                    }
                }
            }
        }
    }

    private func tableHeader(effectiveCol4Width: CGFloat) -> some View {
        HStack(spacing: 0) {
            // Header 1: 任務名稱
            HStack(spacing: 5) {
                Text("≡")
                    .font(.system(size: 13))
                    .opacity(0.75)
                Text("任務名稱")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(AppColors.textTertiary)
            .padding(.horizontal, 12)
            .frame(width: store.colWidths.title, height: headerHeight, alignment: .leading)

            headerDivider

            // Header 2: 掛機
            columnClearHeader(.col1, width: store.colWidths.col1)

            headerDivider

            // Header 3: 副本
            columnClearHeader(.col2, width: store.colWidths.col2)

            headerDivider

            // Header 4: 活動
            columnClearHeader(.col3, width: store.colWidths.col3)

            headerDivider

            // Header 5: 備註可掛
            HStack(spacing: 5) {
                Text("≡")
                    .font(.system(size: 13))
                    .opacity(0.75)
                Text("備註可掛")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(AppColors.textTertiary)
            .padding(.horizontal, 12)
            .frame(width: effectiveCol4Width, height: headerHeight, alignment: .leading)
        }
        .background(AppColors.headerSurface)
    }

    private var headerDivider: some View {
        Rectangle()
            .fill(AppColors.border)
            .frame(width: 1, height: headerHeight)
    }

    private func columnClearHeader(_ column: TaskColumn, width: CGFloat) -> some View {
        let restorable = store.isColumnRestorable(column)
        return Button {
            if editingTarget != nil {
                onDismissEditing()
            }
            store.handleClearColumn(column)
        } label: {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "checkmark.square")
                        .font(.system(size: 9.5, weight: .medium))
                        .opacity(0.75)
                    Text(column.label)
                        .font(.system(size: 11.5, weight: .semibold))
                }
                .foregroundColor(AppColors.textTertiary)

                Text(restorable ? "還原" : "清空")
                    .font(.system(size: 9.5, weight: restorable ? .bold : .regular))
                    .foregroundColor(restorable ? AppColors.amber : AppColors.textMuted)
            }
            .frame(width: width, height: headerHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func emptySearchView(width: CGFloat) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20))
                .foregroundColor(AppColors.textMuted)
            Text("找不到符合「\(store.searchText)」的任務")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(width: width, height: 110)
    }
}
