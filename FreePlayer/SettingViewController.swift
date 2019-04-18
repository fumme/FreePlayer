//
//  SettingViewController.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/19.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit
import Kingfisher

class SettingViewController: UITableViewController {
    @IBOutlet weak var diskCacheSizeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        KingfisherManager.shared.cache.calculateDiskCacheSize { [weak self](size) in
            let m = Double(size)/1024.0/1024.0
            self?.diskCacheSizeLabel.text = String(format: "%.1fM", m)
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 4 {
            KingfisherManager.shared.cache.clearMemoryCache()
            KingfisherManager.shared.cache.clearDiskCache {[weak self] in
                self?.diskCacheSizeLabel.text = String(format: "%.1fM", 0)
            }
        }
    }
    


}
