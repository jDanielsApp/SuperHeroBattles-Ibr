import Foundation

/// Claves de los `Localizable.strings` clásicos. No se usan String Catalogs.
nonisolated enum LocalizableStringKey: String, CaseIterable, Sendable {
    case appName = "app.name"

    case homeTagline = "home.tagline"
    case homePublishers = "home.publishers"
    case homeDataSource = "home.dataSource"
    case homeVersus = "home.versus"
    case homeGuideTitle = "home.guide.title"
    case homeGuideSubtitle = "home.guide.subtitle"
    case homeDuelsTitle = "home.duels.title"
    case homeDuelsSubtitle = "home.duels.subtitle"
    case homeSettings = "home.settings"

    case guideTitle = "guide.title"

    case searchPlaceholder = "search.placeholder"
    case searchAction = "search.action"
    case searchClear = "search.clear"
    case searchIdleTitle = "search.idle.title"
    case searchIdleMessage = "search.idle.message"
    case searchLoading = "search.loading"
    case searchEmptyTitle = "search.empty.title"
    case searchEmptyMessage = "search.empty.message"
    case searchErrorTitle = "search.error.title"
    case searchErrorRetry = "search.error.retry"
    case searchErrorNotConfigured = "search.error.notConfigured"
    case searchErrorOffline = "search.error.offline"
    case searchErrorUnauthorized = "search.error.unauthorized"
    case searchErrorRateLimited = "search.error.rateLimited"
    case searchErrorServer = "search.error.server"
    case searchErrorUnexpected = "search.error.unexpected"
    case searchPublisherUnknown = "search.publisher.unknown"

    case duelsTitle = "duels.title"
    case duelsPlaceholderTitle = "duels.placeholder.title"
    case duelsPlaceholderMessage = "duels.placeholder.message"

    case settingsTitle = "settings.title"
    case settingsLanguage = "settings.language"
    case settingsLanguageSystem = "settings.language.system"
    case settingsLanguageEnglish = "settings.language.english"
    case settingsLanguageSpanish = "settings.language.spanish"
    case settingsAbout = "settings.about"
    case settingsVersion = "settings.version"

    case commonComingSoon = "common.comingSoon"

    case accessibilityHomeGuide = "accessibility.home.guide"
    case accessibilityHomeDuels = "accessibility.home.duels"
    case accessibilityHomeSettings = "accessibility.home.settings"

    case accessibilitySearchField = "accessibility.search.field"
    case accessibilitySearchSubmit = "accessibility.search.submit"
    case accessibilitySearchClear = "accessibility.search.clear"
    case accessibilitySearchLoading = "accessibility.search.loading"
}
