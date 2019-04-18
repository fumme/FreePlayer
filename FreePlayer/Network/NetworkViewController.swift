//
//  NetworkViewController.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/19.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit
import Alamofire

class NetworkViewController: UITableViewController {
    private let reachabilityManager = NetworkReachabilityManager()
    
    private var wifiConnected = false

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        
        reachabilityManager?.listener = { [weak self]status in
            guard let strongSelf = self else { return }
            switch status {
            case .reachable(.ethernetOrWiFi):
                print("The network is reachable over the WiFi connection")
                strongSelf.wifiConnected = true
                break
            case .reachable(.wwan), .notReachable, .unknown:
                print("The network is reachable over the WWAN connection")
                strongSelf.wifiConnected = false
                break
            }
        }
        reachabilityManager?.startListening()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if !wifiConnected {
                ToastView.showToast("请先连接WIFI")
                return
            }
            let wifi = WifiFileTransferViewController()
            wifi.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(wifi, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let id = segue.identifier, id.elementsEqual("WebBrowser") {
            segue.destination.hidesBottomBarWhenPushed = true
        }
    }
    
    deinit {
        reachabilityManager?.stopListening()
    }
}
