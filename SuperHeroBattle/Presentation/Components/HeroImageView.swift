import SwiftUI

/// Remote image with placeholder and loading/error states.
struct HeroImageView: View {
    let url: URL?
    let size: CGFloat

    init(url: URL?, size: CGFloat = 64) {
        self.url = url
        self.size = size
    }

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ZStack {
                            placeholder
                            ProgressView()
                                .tint(ComicPalette.yellow)
                        }
                    @unknown default:
                        placeholder
                    }
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
    }

    private var placeholder: some View {
        Image(systemName: "person.fill")
            .font(.system(size: size * 0.44, weight: .black))
            .foregroundStyle(ComicPalette.paper.opacity(0.28))
            .frame(width: size, height: size)
    }
}
