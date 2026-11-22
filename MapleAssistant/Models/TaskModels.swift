import Foundation
import CoreGraphics

enum TaskColumn: String, CaseIterable, Codable, Hashable {
    case col1
    case col2
    case col3

    var label: String {
        switch self {
        case .col1: return "掛機"
        case .col2: return "副本"
        case .col3: return "活動"
        }
    }

    var keyPath: WritableKeyPath<TaskRow, Bool> {
        switch self {
        case .col1: return \.col1
        case .col2: return \.col2
        case .col3: return \.col3
        }
    }
}

struct TaskRow: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var col1: Bool
    var col2: Bool
    var col3: Bool
    var col4: String

    init(
        id: UUID = UUID(),
        title: String,
        col1: Bool = false,
        col2: Bool = false,
        col3: Bool = false,
        col4: String = ""
    ) {
        self.id = id
        self.title = title
        self.col1 = col1
        self.col2 = col2
        self.col3 = col3
        self.col4 = col4
    }

    static func makeDefaults() -> [TaskRow] {
        [
            TaskRow(title: "1本🥇💰", col1: true, col2: true, col3: true, col4: ""),
            TaskRow(title: "3分🥇", col1: false, col2: true, col3: true, col4: "tms"),
            TaskRow(title: "5分🥇", col1: true, col2: true, col3: true, col4: "本 5 7"),
            TaskRow(title: "8隱", col1: true, col2: true, col3: true, col4: ""),
            TaskRow(title: "9惡🥇", col1: false, col2: false, col3: false, col4: ""),
            TaskRow(title: "10夜🥇💰", col1: true, col2: true, col3: true, col4: ""),
            TaskRow(title: "11主🥇", col1: true, col2: true, col3: true, col4: ""),
            TaskRow(title: "12蘋🥇", col1: true, col2: true, col3: true, col4: "")
        ]
    }
}

enum RowSpacing: String, CaseIterable, Codable, Identifiable {
    case compact
    case cozy
    case loose

    var id: String { rawValue }

    var label: String {
        switch self {
        case .compact: return "緊湊"
        case .cozy: return "適中"
        case .loose: return "寬鬆"
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .compact: return 4
        case .cozy: return 8
        case .loose: return 14
        }
    }

    var minRowHeight: CGFloat {
        switch self {
        case .compact: return 40
        case .cozy: return 48
        case .loose: return 60
        }
    }
}

struct ColumnWidths: Codable, Equatable {
    var title: CGFloat = 160
    var col1: CGFloat = 60
    var col2: CGFloat = 60
    var col3: CGFloat = 60
    var col4: CGFloat = 160

    var totalWidth: CGFloat {
        title + col1 + col2 + col3 + col4
    }
}

enum FocusField: Hashable {
    case search
    case title(UUID)
    case col4(UUID)
}

struct DeletedRowSnapshot: Equatable {
    let row: TaskRow
    let index: Int
}

struct BackupPayload: Codable {
    let version: Int
    let rows: [TaskRow]
    let spacing: RowSpacing
    let colWidths: ColumnWidths
}
