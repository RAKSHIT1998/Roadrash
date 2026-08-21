import RealityKit
import UIKit

/// Bakes real readable text (street signs, storefronts) into a small texture
/// at runtime via CoreGraphics, rather than leaving signage as flat colored
/// boxes. Materials are cached by content so repeated signs of the same kind
/// (e.g. every "STOP" sign) reuse one texture instead of regenerating it.
enum SignTextureFactory {
    private static var cache: [String: UnlitMaterial] = [:]

    static func material(text: String, background: UIColor, textColor: UIColor, size: CGSize = CGSize(width: 256, height: 256)) -> UnlitMaterial {
        let key = "\(text)|\(background)|\(textColor)|\(size.width)x\(size.height)"
        if let cached = cache[key] { return cached }

        let material = buildMaterial(text: text, background: background, textColor: textColor, size: size)
        cache[key] = material
        return material
    }

    private static func buildMaterial(text: String, background: UIColor, textColor: UIColor, size: CGSize) -> UnlitMaterial {
        var fallback = UnlitMaterial()
        fallback.color = .init(tint: background)

        guard let cgImage = renderImage(text: text, background: background, textColor: textColor, size: size)?.cgImage,
              let texture = try? TextureResource(image: cgImage, withName: nil, options: .init(semantic: .color))
        else {
            return fallback
        }

        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        return material
    }

    private static func renderImage(text: String, background: UIColor, textColor: UIColor, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            background.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byWordWrapping

            let font = UIFont.systemFont(ofSize: size.height * 0.2, weight: .heavy)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraph,
            ]
            let attributedText = NSAttributedString(string: text, attributes: attributes)
            let maxWidth = size.width * 0.88
            let textSize = attributedText.boundingRect(
                with: CGSize(width: maxWidth, height: size.height),
                options: [.usesLineFragmentOrigin],
                context: nil
            ).size
            let origin = CGPoint(x: (size.width - min(textSize.width, maxWidth)) / 2, y: (size.height - textSize.height) / 2)
            attributedText.draw(with: CGRect(origin: origin, size: CGSize(width: maxWidth, height: textSize.height)), options: [.usesLineFragmentOrigin], context: nil)
        }
    }
}
