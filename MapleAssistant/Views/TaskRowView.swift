import SwiftUI

struct TaskRowView: View {
    let row: TaskRow
    let rowIndex: Int
    let totalCount: Int
    let isReorderMode: Bool
    @ObservedObject var store: TaskStore
    var focusedField: FocusState<FocusField?>.Binding
    let effectiveCol4Width: CGFloat
    let onSubmitTitle: () -> Void
    let onSubmitCol4: () -> Void

    private var isEditingRow: Bool {
        focusedField.wrappedValue == .title(row.id) || focusedField.wrappedValue == .col4(row.id)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Column 1: 任務名稱
            HStack(spacing: 4) {
                if isReorderMode {
                    VStack(spacing: 2) {
                        Button {
                            store.moveRow(id: row.id, direction: -1)
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(rowIndex == 0 ? AppColors.textMuted.opacity(0.4) : AppColors.textSecondary)
                                .frame(width: 22, height: 16)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(rowIndex == 0)

                        Button {
                            store.moveRow(id: row.id, direction: 1)
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(rowIndex >= totalCount - 1 ? AppColors.textMuted.opacity(0.4) : AppColors.textSecondary)
                                .frame(width: 22, height: 16)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(rowIndex >= totalCount - 1)
                    }
                    .padding(.leading, 4)
                }

                TextField("", text: store.bindingForTitle(id: row.id))
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .tint(AppColors.accentBlue)
                    .focused(focusedField, equals: .title(row.id))
                    .submitLabel(.next)
                    .onSubmit {
                        onSubmitTitle()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(focusedField.wrappedValue == .title(row.id) ? AppColors.controlBg : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(focusedField.wrappedValue == .title(row.id) ? Color(hex: 0x444444) : Color.clear, lineWidth: 1)
                    )
            }
            .padding(.horizontal, isReorderMode ? 4 : 6)
            .frame(width: store.colWidths.title, height: store.rowSpacing.minRowHeight, alignment: .leading)

            verticalDivider

            // Column 2: 掛機
            checkboxCell(isChecked: row.col1, column: .col1, width: store.colWidths.col1)

            verticalDivider

            // Column 3: 副本
            checkboxCell(isChecked: row.col2, column: .col2, width: store.colWidths.col2)

            verticalDivider

            // Column 4: 活動
            checkboxCell(isChecked: row.col3, column: .col3, width: store.colWidths.col3)

            verticalDivider

            // Column 5: 備註可掛 + Delete button
            HStack(spacing: 4) {
                TextField("", text: store.bindingForCol4(id: row.id))
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: 0xD4D4D4))
                    .tint(AppColors.accentBlue)
                    .focused(focusedField, equals: .col4(row.id))
                    .submitLabel(.next)
                    .onSubmit {
                        onSubmitCol4()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(focusedField.wrappedValue == .col4(row.id) ? AppColors.controlBg : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(focusedField.wrappedValue == .col4(row.id) ? Color(hex: 0x444444) : Color.clear, lineWidth: 1)
                    )

                Button {
                    if isEditingRow {
                        focusedField.wrappedValue = nil
                    }
                    store.deleteRow(id: row.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("刪除任務")
            }
            .padding(.leading, 6)
            .padding(.trailing, 4)
            .frame(width: effectiveCol4Width, height: store.rowSpacing.minRowHeight, alignment: .leading)
        }
        .background(isEditingRow ? AppColors.rowEditing : AppColors.surface)
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(AppColors.border)
            .frame(width: 1, height: store.rowSpacing.minRowHeight)
    }

    private func checkboxCell(isChecked: Bool, column: TaskColumn, width: CGFloat) -> some View {
        Button {
            if focusedField.wrappedValue != nil {
                focusedField.wrappedValue = nil
            }
            store.toggleCheckbox(id: row.id, column: column)
        } label: {
            ZStack {
                if isChecked {
                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                        .fill(AppColors.accentBlue)
                        .frame(width: 19, height: 19)
                        .shadow(color: Color.black.opacity(0.35), radius: 2, y: 1)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.white)
                        )
                        .transition(.scale(scale: 0.75).combined(with: .opacity))
                } else {
                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                        .stroke(AppColors.checkboxBorder, lineWidth: 1.5)
                        .frame(width: 19, height: 19)
                }
            }
            .frame(width: width, height: store.rowSpacing.minRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(CheckboxPressButtonStyle())
        .accessibilityLabel("\(row.title) \(column.label)")
        .accessibilityValue(isChecked ? "已完成" : "未完成")
    }
}

private struct CheckboxPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(hex: 0x262626) : Color.clear)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
