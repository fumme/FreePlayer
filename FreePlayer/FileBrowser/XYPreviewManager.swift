//
//  XYPreviewManager.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/22.
//  Copyright © 2019年 cxy. All rights reserved.
//

import Foundation
import QuickLook

class XYPreviewManager: NSObject, QLPreviewControllerDataSource {
    
    var filePath: URL?
    
    func previewViewControllerForFile(_ file: XYFile, fromNavigation: Bool) -> UIViewController {
        if file.type == .PLIST || file.type == .JSON {
            let webviewPreviewViewContoller = XYWebviewPreviewViewContoller()
            webviewPreviewViewContoller.file = file
            return webviewPreviewViewContoller
        } else {
            let previewTransitionViewController = XYPreviewTransitionViewController()
            previewTransitionViewController.quickLookPreviewController.dataSource = self
            self.filePath = file.fileURL
            if fromNavigation == true {
                return previewTransitionViewController.quickLookPreviewController
            }
            return previewTransitionViewController
        }
    }
    
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        if let filePath = filePath {
            return filePath as QLPreviewItem
        }
        return URL(fileURLWithPath: "") as QLPreviewItem
    }
    
}
