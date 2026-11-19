import Lottie
import SwiftUI

/// Lógica de reproducción del wrapper de Lottie, pura y testeable.
///
/// Reglas de AGENTS.md:
/// - Reduce Motion activo → siempre fallback estático.
/// - Asset ausente → fallback estático hasta que se aporte el `.json`.
/// - Asset presente y movimiento permitido → animación real.
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

    /// ¿Existe el asset `name`.json en el bundle indicado?
    ///
    /// Los `.json` de Lottie viven en `Resources/Lottie/` (folder reference):
    /// al añadirlos ahí se copian al bundle y las animaciones se activan
    /// solas, sin cambios de código.
    static func assetExists(named name: String, bundle: Bundle = .main) -> Bool {
        bundle.url(forResource: name, withExtension: "json") != nil
    }
}

/// Modo de repetición propio para no exponer tipos de Lottie fuera de
/// `Core/Lottie` (encapsulación exigida por AGENTS.md).
nonisolated enum ComicLottieLoopMode: Sendable {
    /// Reproduce una vez y se queda en el último fotograma.
    case playOnce
    /// Repite en bucle continuo.
    case loop
}

/// Slot decorativo de animación con estética comic.
///
/// El fallback es intercambiable para que cada pantalla elija su relevo
/// estático (icono, ráfaga con "VS", etc.). Todo el slot es decorativo:
/// nunca forma parte del árbol de accesibilidad.
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

/// Relevo estático por defecto: icono del sistema con color comic.
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
    /// Inicialización abreviada con icono del sistema como fallback.
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
