//
//  XYWebServer.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/20.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class XYWebServer: NSObject {
    static let shared = XYWebServer()
    private override init() {
        super.init()
    }
    
    private lazy var webServer = GCDWebServer()
    private lazy var webUploader: GCDWebUploader = {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return GCDWebUploader(uploadDirectory: documentsPath)
    }()
    
    func configureWebUploaderServer(_ finished: ((Bool, String?)->Void)?) {
        if webUploader.start(withPort: 8484, bonjourName: "QVPlayer"), let url = webUploader.serverURL?.absoluteString, !url.isEmpty {
            finished?(true, url)
        } else {
            finished?(false, nil)
        }
    }
    
    func finalizeWebUploaderServer() {
        if webUploader.isRunning {
            webUploader.stop()
        }
    }
    
    private func configureWebServer() {
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: {request in
            return GCDWebServerDataResponse(html:"<html><body><p>Hello World</p></body></html>")
        })
        webServer.start(withPort: 8080, bonjourName: "GCD Web Server")
        print("Visit \(String(describing: webServer.serverURL)) in your web browser")
    }
    
    private func finalizeWebServer() {
        if webServer.isRunning {
            webServer.stop()
        }
    }
}
