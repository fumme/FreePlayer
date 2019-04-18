//
//  XYThumbnailGenerator.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/22.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit
import ImageIO
import AVFoundation

protocol XYThumbnailGenerator {
    func generate(size: CGSize) -> UIImage?
}

final class ImageThumbnailGenerator: XYThumbnailGenerator {
    private let url: URL

    init(url: URL) {
        self.url = url
    }

    func generate(size: CGSize) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil) else {
            return nil
        }

        let options: [NSString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: Double(max(size.width, size.height) * UIScreen.main.scale),
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true
        ]

        return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as NSDictionary).flatMap { UIImage(cgImage: $0) }
    }
}

final class BorderDecorator: XYThumbnailGenerator {
    private let color: UIColor
    private let thumbnailGenerator: XYThumbnailGenerator
    private let borderWidth: CGFloat

    init(thumbnailGenerator: XYThumbnailGenerator, color: UIColor = .gray, borderWidth: CGFloat = 1.0/UIScreen.main.scale) {
        self.color = color
        self.thumbnailGenerator = thumbnailGenerator
        self.borderWidth = borderWidth
    }

    func generate(size: CGSize) -> UIImage? {
        guard size.width >= 2 && size.height >= 2 else { return nil }
        guard let contentImage = self.thumbnailGenerator.generate(size: CGSize(width: size.width - 2*borderWidth, height: size.height - 2*borderWidth)),
        let cgContentImage = contentImage.cgImage else { return nil }

        var rect = AVMakeRect(aspectRatio: contentImage.size, insideRect: CGRect(origin: CGPoint.zero, size: size))
        rect.origin = CGPoint.zero
        rect.size.width = round(rect.width)
        rect.size.height = round(rect.height)

        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        defer { UIGraphicsEndImageContext() }

        context.setFillColor(color.cgColor)
        context.fill(rect)
        context.translateBy(x: 0, y: rect.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.draw(cgContentImage, in: rect.insetBy(dx: borderWidth, dy: borderWidth))

        return context.makeImage().flatMap { UIImage(cgImage: $0, scale: UIScreen.main.scale, orientation: .up) }
    }
}

final class StaticImageThumbnailGenerator: XYThumbnailGenerator {
    private let image: UIImage

    init(image: UIImage) {
        self.image = image
    }

    func generate(size: CGSize) -> UIImage? {
        return image
    }
}

final class VideoThumbnailGenerator: XYThumbnailGenerator, VLCMediaThumbnailerDelegate {
    
    private let url: URL
    private var thumbnailer: VLCMediaThumbnailer!
    private let group = DispatchGroup()

    init(url: URL) {
        self.url = url
    }

    func generate(size: CGSize) -> UIImage? {
//        let scale = UIScreen.main.scale
//        let asset = AVURLAsset(url: url)
//        let generator = AVAssetImageGenerator(asset: asset)
//        generator.appliesPreferredTrackTransform = true
//        generator.maximumSize = CGSize(width: size.width * scale, height: size.height * scale)
//
//        let kPreferredTimescale: Int32 = 1000
//        var actualTime: CMTime = CMTime(seconds: 0, preferredTimescale: kPreferredTimescale)
//        //generates thumbnail at first second of the video
//        let cgImage = try? generator.copyCGImage(at: CMTime(seconds: 1, preferredTimescale: kPreferredTimescale), actualTime: &actualTime)
//        return cgImage.flatMap { UIImage(cgImage: $0, scale: scale, orientation: .up) }
        
        let media = VLCMedia(url : url)
        thumbnailer = VLCMediaThumbnailer(media: media, andDelegate: self)
        thumbnailer.thumbnailHeight = size.height
        thumbnailer.thumbnailWidth = size.width
        
        group.enter()
        Thread.detachNewThreadSelector(#selector(genVideoThumbnailProcess), toTarget: self, with: nil)
        group.wait()
        return UIImage(cgImage: thumbnailer.thumbnail)
    }
    
    // sub Thread
    @objc private func genVideoThumbnailProcess() {
        thumbnailer.fetchThumbnail()
    }
    
    // deleate method invoked in main thread
    func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer!) {
        group.leave()
    }
    
    func mediaThumbnailer(_ mediaThumbnailer: VLCMediaThumbnailer!, didFinishThumbnail thumbnail: CGImage!) {
        group.leave()
    }
}

final class PDFThumbnailGenerator: XYThumbnailGenerator {
    private let url: URL

    init(url: URL) {
        self.url = url
    }

    func generate(size: CGSize) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL), let page = document.page(at: 1) else { return nil }

        let originalPageRect: CGRect = page.getBoxRect(.mediaBox)
        var targetPageRect = AVMakeRect(aspectRatio: originalPageRect.size, insideRect: CGRect(origin: CGPoint.zero, size: size))
        targetPageRect.origin = CGPoint.zero

        UIGraphicsBeginImageContextWithOptions(targetPageRect.size, true, 0)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.setFillColor(gray: 1.0, alpha: 1.0)
        context.fill(targetPageRect)

        context.saveGState()
        context.translateBy(x: 0.0, y: targetPageRect.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.concatenate(page.getDrawingTransform(.mediaBox, rect: targetPageRect, rotate: 0, preserveAspectRatio: true))
        context.drawPDFPage(page)
        context.restoreGState()

        return context.makeImage().flatMap { UIImage(cgImage: $0, scale: UIScreen.main.scale, orientation: .up) }
    }
}
