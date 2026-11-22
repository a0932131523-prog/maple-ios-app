import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = TaskStore()
    @FocusState private var isSearchFocused: Bool

    @State private var editingTarget: EditingTarget? = nil
    @State private var showSearchBar: Bool = false
    @State private var showConfigPanel: Bool = false
    @State private var isReorderMode: Bool = false
    @State private var showResetAlert: Bool = false
    @State private var showCertInfoAlert: Bool = false
    @State private var provisioningInfo: ProvisioningInfo? = ProvisioningReader.read()
    @State private var scrollToRowID: UUID? = nil

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background
                .ignoresSafeArea()

            // LAYER 1: Main UI — pinned to top & completely immune to keyboard resizing/clipping
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 6)

                titleSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

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

                TaskTableView(
                    store: store,
                    editingTarget: $editingTarget,
                    scrollToRowID: $scrollToRowID,
                    isReorderMode: isReorderMode,
                    onSelectCell: { target in
                        selectCellForEditing(target)
                    },
                    onDismissEditing: {
                        dismissEditing()
                    }
                )
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)

            // LAYER 2: Floating bottom overlay (respects keyboard safe area so it sits flush above keyboard!)
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                if let deleted = store.recentlyDeleted, editingTarget == nil {
                    undoToast(for: deleted)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if editingTarget != nil {
                    NotionCellEditorBar(
                        store: store,
                        target: $editingTarget,
                        onJumpRow: { step in
                            jumpEditingRow(by: step)
                        },
                        onSwitchColumn: { newTarget in
                            editingTarget = newTarget
                        },
                        onDone: {
                            dismissEditing()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .alert("重設預設值", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) {}
            Button("確定重設", role: .destructive) {
                dismissEditing()
                store.resetToDefault()
            }
        } message: {
            Text("是否將任務列表重設為預設值？這將會清除您目前的所有修改！")
        }
        .alert("憑證續簽倒數", isPresented: $showCertInfoAlert) {
            Button("知道了", role: .cancel) {}
        } message: {
            if let info = provisioningInfo {
                Text(info.detailedMessage(from: Date()))
            } else {
                Text("目前找不到簽章憑證到期資訊，App 可正常離線使用。")
            }
        }
        .onValueChange(of: scenePhase) { phase in
            if phase == .active {
                provisioningInfo = ProvisioningReader.read()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            Button {
                Haptics.light()
                provisioningInfo = ProvisioningReader.read()
                showCertInfoAlert = true
            } label: {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    HStack(spacing: 6) {
                        Text("🍁")
                            .font(.system(size: 15))

                        if let info = provisioningInfo {
                            let color = info.statusColor(from: context.date)
                            Circle()
                                .fill(color)
                                .frame(width: 6.5, height: 6.5)
                                .shadow(color: color.opacity(0.7), radius: 2.5)

                            Text(info.compactLabel(from: context.date))
                                .font(.system(size: 11.5, weight: .semibold).monospacedDigit())
                                .foregroundColor(color == AppColors.emerald ? AppColors.textSecondary : color)
                        } else {
                            Text("離線可用")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(AppColors.controlBg.opacity(0.85))
                    )
                    .overlay(
                        Capsule()
                            .stroke(AppColors.subtleBorder, lineWidth: 1)
                    )
                }
            }
            .buttonStyle(.plain)

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
                    dismissEditing()
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

            HStack(spacing: 14) {
                Button {
                    Haptics.light()
                    dismissEditing()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSearchBar.toggle()
                        if showSearchBar {
                            isSearchFocused = true
                        } else {
                            store.searchText = ""
                            isSearchFocused = false
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
                    dismissEditing()
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
                    dismissEditing()
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
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    isSearchFocused = false
                }

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
        let displayTitle = deleted.row.title.isEmpty ? "未命名任務" : deleted.row.title
        return HStack(spacing: 12) {
            Text("已刪除「\(displayTitle)」")
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

    private func selectCellForEditing(_ target: EditingTarget) {
        Haptics.light()
        isSearchFocused = false
        if showConfigPanel {
            withAnimation(.easeInOut(duration: 0.18)) {
                showConfigPanel = false
            }
        }
        withAnimation(.easeOut(duration: 0.18)) {
            editingTarget = target
        }
        // Auto-scroll when tapping row 4+ (index >= 3) so lower rows sit cleanly above keyboard & editor bar
        if let idx = store.rowIndex(for: target.rowID), idx >= 3 {
            scrollToRowID = target.rowID
        }
    }

    private func dismissEditing() {
        isSearchFocused = false
        withAnimation(.easeOut(duration: 0.18)) {
            editingTarget = nil
        }
    }

    private func addAndFocusNewRow() {
        isSearchFocused = false
        let newID = store.addNewRow()
        withAnimation(.easeOut(duration: 0.18)) {
            editingTarget = .title(newID)
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 60_000_000)
            scrollToRowID = newID
        }
    }

    private func jumpEditingRow(by step: Int) {
        guard let current = editingTarget,
              let idx = store.rowIndex(for: current.rowID) else { return }
        let nextIdx = idx + step
        let list = store.filteredRows
        guard nextIdx >= 0 && nextIdx < list.count else { return }

        Haptics.light()
        let nextRowID = list[nextIdx].id
        let nextTarget: EditingTarget = current.isTitle ? .title(nextRowID) : .col4(nextRowID)
        editingTarget = nextTarget
        scrollToRowID = nextRowID
    }
}
