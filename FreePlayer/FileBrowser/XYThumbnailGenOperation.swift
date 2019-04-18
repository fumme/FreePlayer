//
//  XYThumnailOperation.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/25.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit
import Kingfisher

class XYThumbnailGenOperation: Operation {
    private let file: XYFile?
    private let size: CGSize?
    private var generator: XYThumbnailGenerator?
    
    var completed: ((UIImage?)->Void)?
    
    init(file: XYFile, size: CGSize = .zero) {
        self.file = file
        self.size = size
        switch file.type {
        case .PDF:
            generator = PDFThumbnailGenerator(url: file.fileURL)
        case .JPG, .PNG, .GIF:
            generator = ImageThumbnailGenerator(url: file.fileURL)
        default:
            generator = nil
        }
        if file.fileURL.isVideo {
            generator = VideoThumbnailGenerator(url: file.fileURL)
        }
        super.init()
    }
    
    override func main() {
        if isCancelled {
//            print("operation cancelled!")
            return
        }
        guard let _size = size, let _generator = generator, let _file = file else {
            return
        }
        if let image = _generator.generate(size: _size) {
            // cache image
            KingfisherManager.shared.cache.store(image, original: nil, forKey: _file.displayName, processorIdentifier: "", cacheSerializer: DefaultCacheSerializer.default, toDisk: true) { [weak self] in
                print("saved file: \( _file.displayName )")
                self?.completed?(image)
            }
        }
        
    }
}
