# 🍁 楓 — 楓之谷 M 行動小助手（100% 原生 iOS SwiftUI App）

將原本的網頁版（`dct-maple.surge.sh`）完整改寫為 **100% 原生 iPhone SwiftUI App**，專為 iPhone 單手與橫向操作優化，**完全離線運作、無 Safari 鍵盤彈跳與表頭遮擋問題**。

---

## ✨ 主要功能

- **原生固定表頭 + 雙向捲動**：表頭（任務名稱 / 掛機 / 副本 / 活動 / 備註可掛）永遠固定在頂部，捲動任務列或叫出鍵盤編輯第一列時絕不遮擋。
- **Notion 風格深色介面**：完整重現深色卡片、藍色打勾動畫、iPhone 原生震動回饋（Haptics）。
- **一鍵清空與還原**：點擊欄位表頭的「掛機 / 副本 / 活動」可整欄清空，再點一次即可「還原」。
- **智慧鍵盤工具列**：編輯文字時鍵盤上方提供 `▲ 上一格` / `▼ 下一格` / `✓ 完成編輯`，收起鍵盤時自動平滑捲回左側。
- **防誤刪復原提示**：刪除任務後底部會出現 4 秒「復原」提示列，不怕手滑。
- **版面微調中心**：調整行距（緊湊 / 適中 / 寬鬆）、任務名稱與備註欄寬、開啟上下調整順序按鈕。
- **離線儲存與備份還原**：資料永久保存在 iPhone 本機，支援一鍵複製 JSON 備份與從剪貼簿還原，也能透過 iOS 原生分享匯出文字清單。

---

## 🚀 Windows 電腦免 Mac 編譯並安裝到 iPhone（完整步驟）

### 第一步：上傳到 GitHub，免費雲端編譯 `.ipa`

1. 到 [GitHub](https://github.com/new) 建立一個新的倉庫（Repository），名稱可填 `maple-ios-app`（公開 Public 或私人 Private 皆可）。
2. 在本專案資料夾開啟終端機（PowerShell），推送程式碼（把 `<你的帳號>` 換成你的 GitHub 帳號）：
   ```powershell
   git add .
   git commit -m "Initial native iOS SwiftUI app"
   git branch -M main
   git remote add origin https://github.com/<你的帳號>/maple-ios-app.git
   git push -u origin main
   ```
3. 推送後，到你的 GitHub 倉庫點上方 **Actions** 分頁，會看到 **Build iOS IPA (Unsigned)** 自動開始執行（約需 2～3 分鐘）。
4. 出現綠色勾勾 ✅ 後，點進該次執行紀錄，滑到最下方 **Artifacts** 區塊，點選 **`MapleAssistant-iOS-IPA`** 下載並解壓縮，即可得到 **`MapleAssistant.ipa`**！

---

### 第二步：在 Windows 用免費 Apple ID 安裝到 iPhone

#### 方案 A：Sideloadly（最簡單，3 分鐘裝好）
1. 在 Windows 下載並安裝免費工具 [Sideloadly](https://sideloadly.io/)（若電腦未裝過非 Microsoft Store 版本的 iTunes 與 iCloud，請依官網提示一併安裝）。
2. 用傳輸線把 iPhone 接到電腦，並點「信任這部電腦」。
3. 開啟 **Sideloadly**：
   - 把 `MapleAssistant.ipa` 拖進左側 IPA 圖示區。
   - 確認 `iDevice` 顯示你的 iPhone。
   - 在 `Apple Account` 輸入你的免費 Apple ID。
   - 按下 **Start**（首次會要求輸入 Apple ID 密碼與雙重認證碼）。
4. 安裝完成後，到 iPhone 進行首次信任：
   - **設定 → 一般 → VPN 與裝置管理** → 點選你的 Apple ID → 按 **「信任」**。
   - 若為 iOS 16 以上，需開啟：**設定 → 隱私權與安全性 → 開發者模式（開啟並重開機）**。
5. 回到主畫面，點開 **🍁 楓** 即可使用！

> 💡 **免費 Apple ID 7 天續簽說明**：蘋果規定免費 Apple ID 自簽 App 每 7 天需續簽一次。Sideloadly 支援 **Wi-Fi 自動續簽**（在 Sideloadly 勾選 `Enable Wi-Fi sideloading` 並開著電腦即可自動續簽，**資料不會消失**）。

#### 方案 B：SideStore（手機上免電腦自動續簽，適合長期使用）
若希望之後完全不用接 Windows 電腦就能在 iPhone 上續簽，可先安裝 [SideStore](https://sidestore.io/)，再把 `MapleAssistant.ipa` 匯入 SideStore 安裝，即可直接在手機上一鍵或排程續簽！

---

## 🛠️ 本機專案結構

```text
maple-ios-app/
├── project.yml                           # XcodeGen 專案設定檔（iOS 16+）
├── Config/Info.plist                     # iOS App 設定（顯示名稱「楓」、深色啟動畫面）
├── .github/workflows/build-ios-ipa.yml   # GitHub Actions 免費 macOS 雲端編譯腳本
└── MapleAssistant/
    ├── MapleAssistantApp.swift           # App 進入點
    ├── Models/TaskModels.swift           # 資料結構與預設任務
    ├── ViewModels/TaskStore.swift        # 狀態管理、本機儲存、備份還原、防誤刪復原
    ├── Views/
    │   ├── ContentView.swift             # 主畫面、頂部工具列、鍵盤輔助列
    │   ├── TaskTableView.swift           # 永久固定表頭 + 雙向捲動表格
    │   ├── TaskRowView.swift             # 任務列（輸入框、勾選盒、刪除鈕）
    │   └── SettingsPanelView.swift       # 版面微調中心 & JSON 備份還原
    ├── Utils/
    │   ├── Color+Hex.swift               # Notion 深色配色表
    │   └── Haptics.swift                 # iPhone 原生震動回饋
    └── Resources/Assets.xcassets/        # 1024x1024 楓葉 App 圖示與啟動背景色
```
