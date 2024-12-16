//
//  NiceGray.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 16/12/2024.
//

import SwiftUI

extension Color {
    static let customGray = Color(red: 0.5, green: 0.5, blue: 0.5)
}

extension UIColor {
    static let niceGray = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .light, .unspecified:
            return UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0) // Light mode color
        case .dark:
            return UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // Dark mode color
        @unknown default:
            return UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        }
    }
}
