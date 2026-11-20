import Foundation

/// Presentation layer for each combat mode: localized keys and icon.
extension CombatMode {
    var titleKey: LocalizableStringKey {
        switch self {
        case .oneVsOne: .duelsModeOneVsOneTitle
        case .twoVsTwo: .duelsModeTwoVsTwoTitle
        case .threeVsThree: .duelsModeThreeVsThreeTitle
        }
    }

    var subtitleKey: LocalizableStringKey {
        switch self {
        case .oneVsOne: .duelsModeOneVsOneSubtitle
        case .twoVsTwo: .duelsModeTwoVsTwoSubtitle
        case .threeVsThree: .duelsModeThreeVsThreeSubtitle
        }
    }

    var accessibilityKey: LocalizableStringKey {
        switch self {
        case .oneVsOne: .accessibilityDuelsModeOneVsOne
        case .twoVsTwo: .accessibilityDuelsModeTwoVsTwo
        case .threeVsThree: .accessibilityDuelsModeThreeVsThree
        }
    }

    var systemImage: String {
        switch self {
        case .oneVsOne: "person.fill"
        case .twoVsTwo: "person.2.fill"
        case .threeVsThree: "person.3.fill"
        }
    }
}
