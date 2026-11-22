import argparse
import datetime
import json
import os


def main():
    parser = argparse.ArgumentParser(description="Generate SideStore / AltStore source.json and landing page")
    parser.add_argument("--repo", required=True, help="owner/repo")
    parser.add_argument("--version", required=True, help="CFBundleShortVersionString")
    parser.add_argument("--build", required=True, help="CFBundleVersion")
    parser.add_argument("--ipa", required=True, help="Path to built MapleAssistant.ipa")
    parser.add_argument("--notes", default="", help="Release notes")
    parser.add_argument("--prev", default="", help="Optional previous source.json path")
    parser.add_argument("--out-dir", required=True, help="Output directory for gh-pages")
    args = parser.parse_args()

    owner, repo_name = args.repo.split("/", 1)
    pages_base = f"https://{owner}.github.io/{repo_name}"
    source_url = f"{pages_base}/source.json"
    icon_url = f"{pages_base}/icon.png"
    download_url = f"https://github.com/{args.repo}/releases/download/v{args.version}/MapleAssistant.ipa"
    ipa_size = os.path.getsize(args.ipa)
    now_iso = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    release_notes = args.notes.strip() or f"版本 v{args.version} (Build {args.build}) 更新"

    new_version_entry = {
        "version": args.version,
        "buildVersion": str(args.build),
        "date": now_iso,
        "localizedDescription": release_notes,
        "downloadURL": download_url,
        "size": ipa_size,
        "minOSVersion": "16.0",
    }

    versions = [new_version_entry]
    if args.prev and os.path.isfile(args.prev):
        try:
            with open(args.prev, "r", encoding="utf-8") as f:
                prev_data = json.load(f)
            prev_apps = prev_data.get("apps", [])
            if prev_apps:
                for v in prev_apps[0].get("versions", []):
                    if v.get("version") == args.version and str(v.get("buildVersion", "")) == str(args.build):
                        continue
                    if v.get("version") == args.version:
                        continue
                    versions.append(v)
        except Exception as exc:
            print(f"Warning: could not read previous source.json: {exc}")

    # Keep latest 15 releases
    versions = versions[:15]

    app_description = (
        "100% 原生 SwiftUI 打造的楓之谷 M 行動小助手。\n\n"
        "• 永久固定表頭，支援直向與橫向順暢捲動\n"
        "• Notion 風格底部編輯列，點選即時開打與同欄上下跳轉\n"
        "• 一鍵清空與還原欄位、iPhone 原生震動回饋\n"
        "• 內建 7 天憑證時分秒即時倒數提醒\n"
        "• 完整離線運作，支援剪貼簿 JSON 備份還原"
    )

    source_payload = {
        "name": "楓 - 專屬更新來源",
        "subtitle": "楓之谷 M 行動小助手（原生 iOS App）",
        "description": "楓之谷 M 行動小助手專屬 SideStore / AltStore 更新來源，免電腦一鍵更新與續簽。",
        "identifier": "com.dct.mapleassistant.source",
        "sourceURL": source_url,
        "iconURL": icon_url,
        "website": f"{pages_base}/",
        "tintColor": "E85D2A",
        "featuredApps": ["com.dct.mapleassistant"],
        "apps": [
            {
                "name": "楓",
                "bundleIdentifier": "com.dct.mapleassistant",
                "developerName": "DCT",
                "subtitle": "楓之谷 M 行動小助手 — Notion 風格任務管理",
                "localizedDescription": app_description,
                "iconURL": icon_url,
                "tintColor": "2383E2",
                "category": "utilities",
                "version": args.version,
                "versionDate": now_iso,
                "versionDescription": release_notes,
                "downloadURL": download_url,
                "size": ipa_size,
                "versions": versions,
                "appPermissions": {
                    "entitlements": [],
                    "privacy": {},
                },
                "permissions": [],
            }
        ],
        "news": [],
    }

    os.makedirs(args.out_dir, exist_ok=True)
    source_path = os.path.join(args.out_dir, "source.json")
    with open(source_path, "w", encoding="utf-8") as f:
        json.dump(source_payload, f, ensure_ascii=False, indent=2)

    sidestore_deep_link = f"sidestore://source?url={source_url}"
    size_kb = round(ipa_size / 1024.0, 1)

    html = f"""<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <title>楓 — SideStore 專屬更新來源</title>
  <style>
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      min-height: 100dvh;
      background: #0f0f0f;
      color: #e3e3e3;
      font-family: -apple-system, BlinkMacSystemFont, "PingFang TC", "Microsoft JhengHei", sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px 18px;
    }}
    .card {{
      width: 100%;
      max-width: 420px;
      background: #161616;
      border: 1px solid #2f2f2f;
      border-radius: 20px;
      padding: 28px 22px;
      text-align: center;
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.55);
    }}
    .icon {{
      width: 92px;
      height: 92px;
      border-radius: 22px;
      box-shadow: 0 10px 28px rgba(232, 93, 42, 0.25);
      margin-bottom: 14px;
    }}
    h1 {{ margin: 0 0 6px; font-size: 26px; color: #fff; }}
    .sub {{ margin: 0 0 14px; font-size: 13px; color: #9b9b9b; }}
    .badge {{
      display: inline-block;
      background: #222;
      border: 1px solid #333;
      color: #10b981;
      font-size: 12px;
      font-weight: 600;
      padding: 4px 12px;
      border-radius: 999px;
      margin-bottom: 20px;
    }}
    .btn {{
      display: block;
      width: 100%;
      padding: 14px 16px;
      border-radius: 12px;
      font-size: 15px;
      font-weight: 700;
      text-decoration: none;
      border: none;
      cursor: pointer;
      margin-bottom: 10px;
      transition: opacity 0.15s;
    }}
    .btn:active {{ opacity: 0.8; }}
    .btn-primary {{ background: #2383e2; color: #fff; }}
    .btn-secondary {{ background: #242424; color: #e3e3e3; border: 1px solid #333; }}
    .url-box {{
      margin-top: 14px;
      background: #111;
      border: 1px solid #2a2a2a;
      border-radius: 10px;
      padding: 10px 12px;
      font-size: 11px;
      color: #8b8b8b;
      word-break: break-all;
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    }}
    .msg {{
      min-height: 18px;
      font-size: 12px;
      color: #10b981;
      margin-top: 8px;
    }}
  </style>
</head>
<body>
  <div class="card">
    <img class="icon" src="icon.png" alt="楓 App Icon">
    <h1>🍁 楓</h1>
    <p class="sub">楓之谷 M 行動小助手・SideStore 專屬更新來源</p>
    <div class="badge">最新版本 v{args.version} (Build {args.build})・{size_kb} KB</div>

    <a class="btn btn-primary" href="{sidestore_deep_link}">⚡ 一鍵加入 SideStore 來源</a>
    <button class="btn btn-secondary" onclick="copySource()">📋 複製來源網址（手動貼進 SideStore）</button>
    <a class="btn btn-secondary" href="{download_url}">📦 直接下載最新 IPA</a>

    <div class="url-box" id="srcUrl">{source_url}</div>
    <div class="msg" id="msg"></div>
  </div>
  <script>
    function copySource() {{
      const text = document.getElementById('srcUrl').textContent;
      if (navigator.clipboard) {{
        navigator.clipboard.writeText(text).then(() => {{
          document.getElementById('msg').textContent = '✅ 已複製來源網址！打開 SideStore → Sources → + 貼上即可';
        }});
      }}
    }}
  </script>
</body>
</html>
"""

    with open(os.path.join(args.out_dir, "index.html"), "w", encoding="utf-8") as f:
        f.write(html)

    print(f"Generated {source_path} (v{args.version} build {args.build}, {ipa_size} bytes, {len(versions)} version(s))")


if __name__ == "__main__":
    main()
