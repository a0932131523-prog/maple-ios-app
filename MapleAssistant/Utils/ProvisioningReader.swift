import Foundation
import SwiftUI

struct ProvisioningInfo: Equatable {
    let creationDate: Date?
    let expirationDate: Date

    func remainingSeconds(from now: Date) -> TimeInterval {
        expirationDate.timeIntervalSince(now)
    }

    func compactLabel(from now: Date) -> String {
        let remaining = Int(remainingSeconds(from: now))
        if remaining <= 0 {
            return "憑證已到期"
        }
        let days = remaining / 86400
        let hours = (remaining % 86400) / 3600
        let minutes = (remaining % 3600) / 60

        if days >= 1 {
            return "續簽剩 \(days)天\(hours)時"
        } else if hours >= 1 {
            return "續簽剩 \(hours)時\(minutes)分"
        } else {
            return "續簽剩 \(max(minutes, 1))分"
        }
    }

    func detailedMessage(from now: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"

        let remaining = max(0, Int(remainingSeconds(from: now)))
        let days = remaining / 86400
        let hours = (remaining % 86400) / 3600
        let minutes = (remaining % 3600) / 60

        var lines: [String] = []
        if let created = creationDate {
            lines.append("上次續簽：\(formatter.string(from: created))")
        }
        lines.append("到期時間：\(formatter.string(from: expirationDate))")
        lines.append("剩餘時間：\(days) 天 \(hours) 小時 \(minutes) 分")
        lines.append("")
        lines.append("當電腦開機且與 iPhone 連同一個 Wi-Fi 時，Sideloadly 會自動續簽並將倒數重設回 7 天。")
        return lines.joined(separator: "\n")
    }

    func statusColor(from now: Date) -> Color {
        let hoursLeft = remainingSeconds(from: now) / 3600.0
        if hoursLeft > 48 {
            return AppColors.emerald
        } else if hoursLeft > 24 {
            return AppColors.amber
        } else {
            return AppColors.rose
        }
    }
}

enum ProvisioningReader {
    static func read() -> ProvisioningInfo? {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        let startTag = Data("<plist".utf8)
        let endTag = Data("</plist>".utf8)

        guard let startRange = data.range(of: startTag),
              let endRange = data.range(of: endTag, options: [], in: startRange.lowerBound..<data.endIndex) else {
            return nil
        }

        let plistData = data.subdata(in: startRange.lowerBound..<endRange.upperBound)
        guard let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
              let expiration = plist["ExpirationDate"] as? Date else {
            return nil
        }

        let creation = plist["CreationDate"] as? Date
        return ProvisioningInfo(creationDate: creation, expirationDate: expiration)
    }
}
