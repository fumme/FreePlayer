//
//  WifiFileTransferViewController.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/20.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class WifiFileTransferViewController: BaseViewController {

    @IBOutlet weak var httpLb: UILabel!
    @IBOutlet weak var ftpLb: UILabel!
    @IBOutlet weak var tipTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "WiFi传输"
        
        tipTextView.text = "1. 请确保电脑和手机连接同一个WIFI. \n2. 使用电脑浏览器打开HTTP或FTP传输地址，进行文件管理. \n\n注意：传输过程中请勿关闭此页面"
        XYWebServer.shared.configureWebUploaderServer { [weak self](ret, path) in
            if ret {
                print(path!)
                self?.httpLb.text = path!
            }
        }
        
        XYFTPServer.shared.startServer { [weak self](ret, path) in
            if ret {
                print(path!)
                self?.ftpLb.text = path!
            }
        }
    }
    
    deinit {
        XYWebServer.shared.finalizeWebUploaderServer()
        XYFTPServer.shared.stopFtpServer()
    }

}
