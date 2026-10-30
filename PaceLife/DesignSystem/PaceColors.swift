import SwiftUI
import UIKit

/// The approved semantic palette from docs/DESIGN_SYSTEM.md.
/// Dynamic UIKit colors follow both the system appearance and SwiftUI's
/// preferredColorScheme; no view needs to duplicate a light/dark decision.
@MainActor
enum PaceColor {
    static var brand: Color { adaptive(0x072D20, 0x8EF5D8) }
    static var accent: Color { adaptive(0x16784C, 0x86F3D3) }
    static var accentStrong: Color { adaptive(0x075237, 0x88F7D8) }
    static var onAccent: Color { adaptive(0xFFFFFF, 0x06211A) }
    static var accentSoft: Color { adaptive(0xDDF8EC, 0x0F2A24) }
    static var actionFill: Color { adaptive(0x07774B, 0x88F7D8) }
    static var selectionFill: Color { adaptive(0xD3F9EA, 0x8EF8DC) }
    static var onSelection: Color { adaptive(0x063D29, 0x06211A) }
    static var goalReachedFill: Color { adaptive(0x3BBF79, 0x7FEFC5) }
    static var onGoalReached: Color { adaptive(0x07301F, 0x06211A) }
    static var background: Color { adaptive(0xF8F9F7, 0x0B1315) }
    static var surface: Color { adaptive(0xFFFFFF, 0x111A1D) }
    static var surfaceSecondary: Color { adaptive(0xFFFFFF, 0x152024) }
    static var border: Color { adaptive(0xE7EAE6, 0x232E32) }
    static var fieldBackground: Color { adaptive(0xF1F2F5, 0x172125) }
    static var track: Color { adaptive(0xE1E4E2, 0x343C3E) }
    static var textPrimary: Color { adaptive(0x0B120F, 0xF3F7F5) }
    static var textSecondary: Color { adaptive(0x5F6684, 0xA3AEB8) }
    static var chartLow: Color { adaptive(0xA7DDBF, 0x4E9F86) }
    static var streak: Color { adaptive(0xE8590C, 0xFF922B) }
    static var success: Color { adaptive(0x1E8A50, 0x6EE7A0) }
    static var warning: Color { adaptive(0xB86E00, 0xFFB940) }
    static var danger: Color { adaptive(0xC62828, 0xFF6B66) }

    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xff) / 255,
                green: CGFloat((hex >> 8) & 0xff) / 255,
                blue: CGFloat(hex & 0xff) / 255,
                alpha: 1
            )
        })
    }
}

enum PaceSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
