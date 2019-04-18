//
//  XYFTPServer.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/22.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class XYFTPServer: NSObject {
    static let shared = XYFTPServer()
    private override init() {
        super.init()
    }
    
    private var ftpPort: UInt32 = 2989
    private var ftpServer: XMFTPServer?
    
    func startServer(onPort port: UInt32 = 2989, finished: ((Bool, String?)->Void)?) {
        if let server = XMFTPServer(port: ftpPort, withDir: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!, notify: nil) {
            let ftpAddr = "ftp://"+XMFTPHelper.localIPAddress()+":"+String(ftpPort)
            print(ftpAddr)
            ftpServer = server
            finished?(true, ftpAddr)
        } else {
            finished?(false, nil)
        }
    }
    
    func stopFtpServer() {
        ftpServer?.stop()
    }
    
}
