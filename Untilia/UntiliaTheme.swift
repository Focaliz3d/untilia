//
//  UntiliaTheme.swift
//  Untilia
//

import SwiftUI

extension Color {
    static let untiliaInk = Color(red: 0.025, green: 0.02, blue: 0.08)
    static let untiliaCyan = Color(red: 0.29, green: 0.88, blue: 1.0)
    static let untiliaViolet = Color(red: 0.47, green: 0.32, blue: 1.0)
    static let untiliaMagenta = Color(red: 0.95, green: 0.27, blue: 0.78)
    static let untiliaLavender = Color(red: 0.75, green: 0.58, blue: 1.0)
}

enum UntiliaTheme: Int, CaseIterable, Identifiable {
    case twilight
    case forest
    case dunes

    var id: Int { rawValue }

    var imageName: String {
        switch self {
        case .twilight: return "SunsetLandscape"
        case .forest: return "ForestLandscape"
        case .dunes: return "DunesLandscape"
        }
    }

    var iconName: String {
        switch self {
        case .twilight: return "moon.stars.fill"
        case .forest: return "leaf.fill"
        case .dunes: return "sun.max.fill"
        }
    }

    var accent: Color {
        switch self {
        case .twilight: return .untiliaLavender
        case .forest: return Color(red: 0.31, green: 0.92, blue: 0.76)
        case .dunes: return Color(red: 1.0, green: 0.64, blue: 0.32)
        }
    }

    var buttonColor: Color {
        switch self {
        case .twilight: return Color(red: 0.72, green: 0.28, blue: 0.62)
        case .forest: return Color(red: 0.20, green: 0.58, blue: 0.49)
        case .dunes: return Color(red: 0.70, green: 0.39, blue: 0.22)
        }
    }

    var ringColors: [Color] {
        switch self {
        case .twilight:
            return [.untiliaCyan, .untiliaViolet, .untiliaMagenta, .untiliaCyan]
        case .forest:
            return [Color(red: 0.25, green: 0.84, blue: 0.72), Color(red: 0.34, green: 0.98, blue: 0.72), Color(red: 0.22, green: 0.67, blue: 0.78), Color(red: 0.25, green: 0.84, blue: 0.72)]
        case .dunes:
            return [Color(red: 1.0, green: 0.77, blue: 0.34), Color(red: 1.0, green: 0.47, blue: 0.28), Color(red: 0.92, green: 0.31, blue: 0.29), Color(red: 1.0, green: 0.77, blue: 0.34)]
        }
    }

    var backgroundGradient: [Color] {
        switch self {
        case .twilight:
            return [.untiliaInk, Color(red: 0.10, green: 0.04, blue: 0.18)]
        case .forest:
            return [Color(red: 0.015, green: 0.10, blue: 0.14), Color(red: 0.015, green: 0.16, blue: 0.14)]
        case .dunes:
            return [Color(red: 0.10, green: 0.035, blue: 0.10), Color(red: 0.26, green: 0.07, blue: 0.06)]
        }
    }

    var cardGradient: [Color] {
        switch self {
        case .twilight:
            return [Color(red: 0.18, green: 0.17, blue: 0.38), Color(red: 0.10, green: 0.09, blue: 0.25)]
        case .forest:
            return [Color(red: 0.0, green: 0.31, blue: 0.29), Color(red: 0.0, green: 0.18, blue: 0.20)]
        case .dunes:
            return [Color(red: 0.22, green: 0.12, blue: 0.16), Color(red: 0.13, green: 0.055, blue: 0.09)]
        }
    }

    var surfaceColor: Color {
        switch self {
        case .twilight: return Color(red: 0.12, green: 0.09, blue: 0.25)
        case .forest: return Color(red: 0.05, green: 0.16, blue: 0.18)
        case .dunes: return Color(red: 0.18, green: 0.08, blue: 0.13)
        }
    }

    var surfaceHighlight: Color {
        switch self {
        case .twilight: return Color(red: 0.24, green: 0.14, blue: 0.38)
        case .forest: return Color(red: 0.10, green: 0.27, blue: 0.26)
        case .dunes: return Color(red: 0.32, green: 0.14, blue: 0.18)
        }
    }
}
