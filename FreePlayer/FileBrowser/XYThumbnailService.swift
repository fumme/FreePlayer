//
//  XYThunmailService.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/25.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit
import Kingfisher

class XYThumbnailService: NSObject {
    
    static let `default` = XYThumbnailService()
    private override init() {
        super.init()
    }
    
    private lazy var operationCache = [String: XYThumbnailGenOperation]()
    
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 10
        queue.name = Bundle.main.bundleIdentifier
        return queue
    }()
    
    static func startService(file: XYFile, size: CGSize, finished: @escaping ((UIImage?)->Void)) {
        KingfisherManager.shared.retrieveImage(with: ImageResource(downloadURL: file.fileURL, cacheKey: file.displayName), options: [.onlyFromCache], progressBlock: nil) { (img, err, cachetype, url) in
            if let image = img {
//                print("存在cache \(file.fileURL) \(file.filePath)")
                finished(image)
                return
            }
            
            XYThumbnailService.stopService(file: file)
            let operation = XYThumbnailGenOperation(file: file, size: size)
            operation.completed = { image in
                XYThumbnailService.default.operationCache.removeValue(forKey: file.filePath)
                finished(image)
                operation.completed = nil
            }
            XYThumbnailService.default.operationCache[file.filePath] = operation
            XYThumbnailService.default.queue.addOperation(operation)
        }
        
    }
    
    static func stopService(file: XYFile) {
        if let operation = XYThumbnailService.default.operationCache[file.filePath] {
            if operation.isCancelled { return }
            operation.completed = nil
            operation.cancel()
            if operation.isCancelled {
                XYThumbnailService.default.operationCache.removeValue(forKey: file.filePath)
            }
        }
    }

}
