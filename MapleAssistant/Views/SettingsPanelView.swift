import SwiftUI
import UIKit

struct SettingsPanelView: View {
    @ObservedObject var store: TaskStore
    @Binding var isPresented: Bool
    @Binding var isReorderMode: Bool

    @State private var feedbackMessage: String? = nil
    @State private var feedbackIsError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                    Text("版面微調中心")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Rectangle().fill(AppColors.border).frame(height: 1)

            // Row Spacing
            HStack {
                Text("行距調整：")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(RowSpacing.allCases) { spacing in
                        Button {
                            store.setSpacing(spacing)
                        } label: {
                            Text(spacing.label)
                                .font(.system(size: 11, weight: store.rowSpacing == spacing ? .semibold : .regular))
                                .foregroundColor(store.rowSpacing == spacing ? .white : AppColors.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(store.rowSpacing == spacing ? AppColors.segmentedActive : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AppColors.segmentedBg)
                )
            }

            Rectangle().fill(AppColors.border).frame(height: 1)

            // Column Width Sliders
            VStack(alignment: .leading, spacing: 8) {
                Text("欄位寬度調整 (px)：")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("任務名稱")
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text("\(Int(store.colWidths.title))px")
                                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                                .foregroundColor(.white)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(store.colWidths.title) },
                                set: { store.updateTitleWidth(CGFloat($0)) }
                            ),
                            in: 90...280,
                            step: 5
                        )
                        .tint(AppColors.accentBlue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("備註可掛")
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text("\(Int(store.colWidths.col4))px")
                                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                                .foregroundColor(.white)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(store.colWidths.col4) },
                                set: { store.updateCol4Width(CGFloat($0)) }
                            ),
                            in: 90...280,
                            step: 5
                        )
                        .tint(AppColors.accentBlue)
                    }
                }
            }

            Rectangle().fill(AppColors.border).frame(height: 1)

            // Reorder Toggle
            Toggle(isOn: $isReorderMode.animation(.easeInOut(duration: 0.18))) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textSecondary)
                    Text("調整任務順序（顯示上下移動鈕）")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .tint(AppColors.accentBlue)

            Rectangle().fill(AppColors.border).frame(height: 1)

            // Backup & Restore via Clipboard
            VStack(alignment: .leading, spacing: 8) {
                Text("資料備份與還原：")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)

                HStack(spacing: 10) {
                    Button {
                        if let json = store.exportBackupJSON() {
                            UIPasteboard.general.string = json
                            Haptics.success()
                            showFeedback("已複製備份到剪貼簿", isError: false)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11))
                            Text("複製備份")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(AppColors.segmentedBg)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        if let text = UIPasteboard.general.string,
                           store.importBackupJSON(text) {
                            showFeedback("已成功從剪貼簿還原！", isError: false)
                        } else {
                            Haptics.warning()
                            showFeedback("剪貼簿內容不是有效的備份格式", isError: true)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 11))
                            Text("從剪貼簿還原")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(AppColors.segmentedBg)
                        )
                    }
                    .buttonStyle(.plain)
                }

                if let msg = feedbackMessage {
                    Text(msg)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(feedbackIsError ? AppColors.rose : AppColors.emerald)
                        .transition(.opacity)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColors.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppColors.subtleBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 14, y: 6)
    }

    private func showFeedback(_ message: String, isError: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            feedbackMessage = message
            feedbackIsError = isError
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation(.easeOut(duration: 0.2)) {
                if feedbackMessage == message {
                    feedbackMessage = nil
                }
            }
        }
    }
}
