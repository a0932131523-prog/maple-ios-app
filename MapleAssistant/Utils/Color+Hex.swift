import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

enum AppColors {
    static let background = Color(hex: 0x0F0F0F)
    static let surface = Color(hex: 0x111111)
    static let headerSurface = Color(hex: 0x161616)
    static let panel = Color(hex: 0x1F1F1F)
    static let controlBg = Color(hex: 0x222222)
    static let segmentedBg = Color(hex: 0x2A2A2A)
    static let segmentedActive = Color(hex: 0x373737)
    static let border = Color(hex: 0x2F2F2F)
    static let subtleBorder = Color(hex: 0x262626)
    static let textPrimary = Color(hex: 0xE3E3E3)
    static let textSecondary = Color(hex: 0x9B9B9B)
    static let textTertiary = Color(hex: 0x808080)
    static let textMuted = Color(hex: 0x5A5A5A)
    static let accentBlue = Color(hex: 0x2383E2)
    static let checkboxBorder = Color(hex: 0x4C4C4C)
    static let rowEditing = Color(hex: 0x2383E2, alpha: 0.11)
    static let emerald = Color(hex: 0x10B981)
    static let amber = Color(hex: 0xF59E0B)
    static let rose = Color(hex: 0xF43F5E)
}

extension View {
    @ViewBuilder
    func onValueChange<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value, perform: action)
        }
    }
}
