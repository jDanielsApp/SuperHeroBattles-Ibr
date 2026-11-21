import SwiftUI

private struct HeroImagesKey: EnvironmentKey {
    /// Process-wide default: previews and views outside the composed
    /// hierarchy still share one coalescing cache instead of one
    /// download per view. `AppContainer` injects the real instance for
    /// the live app.
    static let defaultValue: any HeroImageLoading = HeroImageStore()
}

extension EnvironmentValues {
    /// Hero image loader shared by every `HeroImageView`.
    var heroImages: any HeroImageLoading {
        get { self[HeroImagesKey.self] }
        set { self[HeroImagesKey.self] = newValue }
    }
}
