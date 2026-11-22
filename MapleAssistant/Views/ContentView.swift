import SwiftUI

struct ContentView: View {
    @StateObject private var store = TaskStore()
    @FocusState private var focusedField: FocusField?

    @State private var showSearchBar: Bool = false
    @State private var showConfigPanel: Bool = false
    @State private var isReorderMode: Bool = false
    @State private var showResetAlert: Bool = false
    @State private var scrollToRowID: UUID? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Navigation Header
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 6)

                    // Title & Subtitle Badge
                    titleSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)

                    // Controls Toolbar + Collapsible Search / Settings Panels
                    VStack(spacing: 10) {
                        controlsBar

                        if showSearchBar {
                            searchBar
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if showConfigPanel {
                            SettingsPanelView(
                                store: store,
                                isPresented: $showConfigPanel,
                                isReorderMode: $isReorderMode
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                    // Main Pinned-Header Interactive Table
                    TaskTableView(
                        store: store,
                        focusedField: $focusedField,
                        scrollToRowID: $scrollToRowID,
                        isReorderMode: isReorderMode,
                        onAddRow: {
                            addAndFocusNewRow()
                        }
                    )
                }

                // Undo Delete Floating Toast
                if let deleted = store.recentlyDeleted {
                    undoToast(for: deleted)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack(spacing: 12) {
                        Button {
                            moveFocus(step: -1)
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                        }

                        Button {
                            moveFocus(step: 1)
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }

                    Spacer()

                    Button {
                        Haptics.light()
                        focusedField = nil
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                            Text("完成編輯")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppColors.accentBlue)
                        )
                    }
                }
            }
            .alert("重設預設值", isPresented: $showResetAlert) {
                Button("取消", role: .cancel) {}
                Button("確定重設", role: .destructive) {
                    focusedField = nil
                    store.resetToDefault()
                }
            } message: {
                Text("是否將任務列表重設為預設值？這將會清除您目前的所有修改！")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 6) {
                Text("🍁")
                    .font(.system(size: 16))
                Text("Offline Ready")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textMuted)
            }

            Spacer()

            HStack(spacing: 14) {
                ShareLink(item: store.shareSummaryText()) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }

                Button {
                    Haptics.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showConfigPanel.toggle()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var titleSection: some View {
        HStack(alignment: .center) {
            Text("楓")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Text("楓之谷 M 行動小助手")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(AppColors.controlBg)
                )
                .overlay(
                    Capsule()
                        .stroke(AppColors.subtleBorder, lineWidth: 1)
                )
        }
    }

    private var controlsBar: some View {
        HStack {
            // Left: ★ 任務列表 + Sync indicator dot
            HStack(spacing: 6) {
                Text("★")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)

                Text("任務列表")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("(\(store.rows.count))")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundColor(AppColors.textTertiary)

                Circle()
                    .fill(store.isSaving ? AppColors.amber : AppColors.emerald)
                    .frame(width: 6.5, height: 6.5)
                    .shadow(color: (store.isSaving ? AppColors.amber : AppColors.emerald).opacity(0.8), radius: 3)
                    .animation(.easeInOut(duration: 0.2), value: store.isSaving)
            }

            Spacer()

            // Right: Search, Reset, Settings, + New Row
            HStack(spacing: 14) {
                Button {
                    Haptics.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSearchBar.toggle()
                        if showSearchBar {
                            focusedField = .search
                        } else {
                            store.searchText = ""
                            if focusedField == .search {
                                focusedField = nil
                            }
                        }
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(showSearchBar ? .white : AppColors.textTertiary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.light()
                    showResetAlert = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showConfigPanel.toggle()
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(showConfigPanel ? .white : AppColors.textTertiary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    addAndFocusNewRow()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Rectangle()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 1, height: 11)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(AppColors.accentBlue)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textTertiary)

            TextField("搜尋任務或備註...", text: $store.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(AppColors.accentBlue)
                .focused($focusedField, equals: .search)
                .submitLabel(.search)

            if !store.searchText.isEmpty {
                Button {
                    store.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppColors.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private func undoToast(for deleted: DeletedRowSnapshot) -> some View {
        HStack(spacing: 12) {
            Text("已刪除「\(deleted.row.title)」")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Button {
                store.undoDelete()
            } label: {
                Text("復原")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.accentBlue)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: 0x242424))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 14, y: 6)
    }

    private func addAndFocusNewRow() {
        let newID = store.addNewRow()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            scrollToRowID = newID
            focusedField = .title(newID)
        }
    }

    private func moveFocus(step: Int) {
        let allFields: [FocusField] = store.filteredRows.flatMap { row in
            [.title(row.id), .col4(row.id)]
        }
        guard let current = focusedField,
              let idx = allFields.firstIndex(of: current) else { return }
        let nextIdx = idx + step
        guard nextIdx >= 0 && nextIdx < allFields.count else { return }
        Haptics.light()
        let nextField = allFields[nextIdx]
        focusedField = nextField
        switch nextField {
        case .title(let id), .col4(let id):
            scrollToRowID = id
        case .search:
            break
        }
    }
}
