import SwiftUI

/// Remote hero image with placeholder, loading and error states.
///
/// Images resolve through the shared `HeroImageStore` (environment key
/// `\.heroImages`): concurrent rows share one download and repeated
/// searches reuse the cached result instead of starting over.
struct HeroImageView: View {
    let url: URL?
    let size: CGFloat

    @Environment(\.heroImages) private var heroImages

    /// The loaded image and the URL it belongs to: a stale image is
    /// never shown for a different URL.
    @State private var loaded: (url: URL, image: UIImage)?
    @State private var isFailed = false

    init(url: URL?, size: CGFloat = 64) {
        self.url = url
        self.size = size
    }

    private var displayImage: UIImage? {
        guard let loaded, loaded.url == url else { return nil }
        return loaded.image
    }

    var body: some View {
        Group {
            if let displayImage {
                Image(uiImage: displayImage)
                    .resizable()
                    .scaledToFill()
            } else if url != nil, !isFailed {
                ZStack {
                    placeholder
                    ProgressView()
                        .tint(ComicPalette.yellow)
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .background(ComicPalette.ink)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ComicPalette.paper.opacity(0.18), lineWidth: 2)
        }
        .accessibilityHidden(true)
        .task(id: url) {
            await load()
        }
    }

    @MainActor
    private func load() async {
        guard let url else {
            loaded = nil
            isFailed = false
            return
        }

        isFailed = false
        if let image = await heroImages.image(for: url) {
            loaded = (url, image)
        } else {
            loaded = nil
            isFailed = true
        }
    }

    private var placeholder: some View {
        Image(systemName: "person.fill")
            .font(.system(size: size * 0.44, weight: .black))
            .foregroundStyle(ComicPalette.paper.opacity(0.28))
            .frame(width: size, height: size)
    }
}
