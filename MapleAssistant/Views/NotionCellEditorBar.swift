import SwiftUI

struct NotionCellEditorBar: View {
    @ObservedObject var store: TaskStore
    @Binding var target: EditingTarget?
    let onJumpRow: (Int) -> Void
    let onSwitchColumn: (EditingTarget) -> Void
    let onDone: () -> Void

    @FocusState private var isFocused: Bool
    @State private var draftText: String = ""
    @State private var activeTarget: EditingTarget? = nil

    private var currentRowIndex: Int? {
        guard let target = target else { return nil }
        return store.rowIndex(for: target.rowID)
    }

    private var canMoveUp: Bool {
        guard let idx = currentRowIndex else { return false }
        return idx > 0
    }

    private var canMoveDown: Bool {
        guard let idx = currentRowIndex else { return false }
        return idx < store.filteredRows.count - 1
    }

    private var currentRowLabel: String {
        guard let idx = currentRowIndex else { return "" }
        return "第 \(idx + 1) 列"
    }

    private var placeholderText: String {
        guard let target = target else { return "" }
        return target.isTitle ? "輸入任務名稱..." : "輸入備註可掛..."
    }

    var body: some View {
        VStack(spacing: 10) {
            // Top Notion-style property switcher & row navigation bar
            HStack(spacing: 8) {
                if let currentTarget = target {
                    HStack(spacing: 4) {
                        columnPill(
                            label: "任務名稱",
                            isActive: currentTarget.isTitle
                        ) {
                            onSwitchColumn(.title(currentTarget.rowID))
                        }

                        columnPill(
                            label: "備註可掛",
                            isActive: !currentTarget.isTitle
                        ) {
                            onSwitchColumn(.col4(currentTarget.rowID))
                        }
                    }

                    if !currentRowLabel.isEmpty {
                        Text(currentRowLabel)
                            .font(.system(size: 11, weight: .medium).monospacedDigit())
                            .foregroundColor(AppColors.textTertiary)
                    }
                }

                Spacer(minLength: 4)

                // Up / Down jump buttons (Notion / spreadsheet column jump)
                HStack(spacing: 4) {
                    Button {
                        onJumpRow(-1)
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(canMoveUp ? AppColors.textPrimary : AppColors.textMuted.opacity(0.45))
                            .frame(width: 30, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(AppColors.controlBg)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMoveUp)

                    Button {
                        onJumpRow(1)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(canMoveDown ? AppColors.textPrimary : AppColors.textMuted.opacity(0.45))
                            .frame(width: 30, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(AppColors.controlBg)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMoveDown)
                }

                // Done button
                Button {
                    Haptics.light()
                    isFocused = false
                    onDone()
                } label: {
                    Text("完成")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(AppColors.accentBlue)
                        )
                }
                .buttonStyle(.plain)
            }

            // Full-width Notion-style input box (cursor blinks immediately on first tap!)
            HStack(spacing: 8) {
                TextField(placeholderText, text: $draftText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: (target?.isTitle ?? false) ? .semibold : .regular))
                    .foregroundColor(.white)
                    .tint(AppColors.accentBlue)
                    .focused($isFocused)
                    .submitLabel(canMoveDown ? .next : .done)
                    .onSubmit {
                        if canMoveDown {
                            onJumpRow(1)
                            Task { @MainActor in
                                isFocused = true
                            }
                        } else {
                            isFocused = false
                            onDone()
                        }
                    }

                if !draftText.isEmpty {
                    Button {
                        Haptics.light()
                        draftText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color(hex: 0x161616))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(AppColors.accentBlue.opacity(0.75), lineWidth: 1.2)
            )
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color(hex: 0x1E1E1E))
        .overlay(
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1),
            alignment: .top
        )
        .shadow(color: Color.black.opacity(0.55), radius: 12, y: -4)
        .onAppear {
            if let current = target {
                activeTarget = current
                draftText = store.text(for: current)
            }
            isFocused = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 50_000_000)
                if target != nil {
                    isFocused = true
                }
            }
        }
        .onValueChange(of: target) { newTarget in
            guard let newTarget = newTarget else {
                isFocused = false
                activeTarget = nil
                return
            }
            if newTarget != activeTarget {
                activeTarget = newTarget
                draftText = store.text(for: newTarget)
            }
            if !isFocused {
                isFocused = true
            }
        }
        .onValueChange(of: draftText) { newText in
            if let current = activeTarget, current == target {
                store.setText(newText, for: current)
            }
        }
    }

    private func columnPill(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Text(label)
                .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                .foregroundColor(isActive ? .white : AppColors.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isActive ? AppColors.accentBlue.opacity(0.9) : AppColors.controlBg)
                )
        }
        .buttonStyle(.plain)
    }
}
