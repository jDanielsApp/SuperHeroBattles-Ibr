import Lottie
import SwiftUI

/// Pure, testable playback logic for the Lottie wrapper.
///
/// Rules:
/// - Reduce Motion enabled → always a static fallback.
/// - Missing asset → static fallback until the `.json` is provided.
/// - Asset present and motion allowed → real animation.
nonisolated enum ComicLottie {
    enum Decision: Equatable, Sendable {
        case animation
        case staticFallback
    }

    static func decision(assetExists: Bool, reduceMotion: Bool) -> Decision {
        guard assetExists, !reduceMotion else {
            return .staticFallback
        }
        return .animation
    }

    /// Does the `name`.json asset exist in the given bundle?
    ///
    /// Lottie `.json` files live in `Resources/Lottie/` (folder reference):
    /// dropping one in there copies it into the bundle, and the animation
    /// turns on by itself with no code changes.
    static func assetExists(named name: String, bundle: Bundle = .main) -> Bool {
        bundle.url(forResource: name, withExtension: "json") != nil
    }
}

/// Custom loop mode so that no Lottie types are exposed outside
/// `Core/Lottie`.
nonisolated enum ComicLottieLoopMode: Sendable {
    /// Plays once and holds on the last frame.
    case playOnce
    /// Repeats in a continuous loop.
    case loop
}

/// Decorative animation slot with comic book styling.
///
/// The fallback is swappable so each screen can choose its own static
/// stand-in (an icon, a "VS" burst, etc.). The whole slot is decorative:
/// it never becomes part of the accessibility tree.
struct ComicLottieView<Fallback: View>: View {
    let animationName: String
    var loopMode: ComicLottieLoopMode = .playOnce
    @ViewBuilder let fallback: () -> Fallback

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        animationName: String,
        loopMode: ComicLottieLoopMode = .playOnce,
        @ViewBuilder fallback: @escaping () -> Fallback
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.fallback = fallback
    }

    var body: some View {
        Group {
            if ComicLottie.decision(
                assetExists: ComicLottie.assetExists(named: animationName),
                reduceMotion: reduceMotion
            ) == .animation,
                let animation = LottieAnimation.named(animationName) {
                LottieView(animation: animation)
                    .resizable()
                    .playing(loopMode: lottieLoopMode)
            } else {
                fallback()
            }
        }
        .accessibilityHidden(true)
    }

    private var lottieLoopMode: LottieLoopMode {
        switch loopMode {
        case .playOnce: .playOnce
        case .loop: .loop
        }
    }
}

/// Default static stand-in: a system icon in comic book colors.
struct ComicIconFallback: View {
    let icon: String
    var color: Color = ComicPalette.yellow
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.78, weight: .black))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

extension ComicLottieView where Fallback == ComicIconFallback {
    /// Convenience initializer using a system icon as the fallback.
    init(
        animationName: String,
        fallbackIcon: String,
        fallbackColor: Color = ComicPalette.yellow,
        fallbackSize: CGFloat = 56,
        loopMode: ComicLottieLoopMode = .playOnce
    ) {
        self.init(animationName: animationName, loopMode: loopMode) {
            ComicIconFallback(
                icon: fallbackIcon,
                color: fallbackColor,
                size: fallbackSize
            )
        }
    }
}
