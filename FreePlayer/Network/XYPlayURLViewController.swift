//
//  XYPlayURLViewController.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/22.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit
import AVKit

class XYPlayURLViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    private lazy var playUrls = [XYPlayUrl]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "文件链接"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "XYPlayURLCell")
        tableView.tableFooterView = UIView()
        queryDB()
    }
    
    private func queryDB() {
        XYDataBaseManager.default.getAllRecords { [weak self](ret) in
            guard let strongSelf = self else  { return }
            if let urls = ret {
                print("urls.count == \(urls.count)")
                strongSelf.playUrls = urls
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    private func playURL(_ url: URL) {
        do {
            let item = try AVPlayerItem.mc_playerItem(withRemoteURL: url)
            let player = AVPlayer(playerItem: item)
            if #available(iOS 10.0, *) {
                player.automaticallyWaitsToMinimizeStalling = false
            } else {
            }
            let playerController = AVPlayerViewController()
            playerController.player = player
            present(playerController, animated: true) {
                player.play()
            }
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let path = textField.text, !path.isEmpty, let url = URL(string: path) {
            XYDataBaseManager.default.isPlayURLExist(path) { [weak self](ret) in
                if !ret {
                    XYDataBaseManager.default.savePlayUrl(link: path) { (err) in
                        if err == nil {
                            self?.queryDB()
                        } else {
                            ToastView.showToast(err!.localizedDescription)
                        }
                    }
                } else {
                    ToastView.showToast("已存在")
                }
            }
            playURL(url)
        } else {
            ToastView.showToast("含有非法字符")
        }
        return true
    }

}

extension XYPlayURLViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playUrls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "XYPlayURLCell", for: indexPath)
        cell.selectionStyle = .none
        cell.textLabel?.text = playUrls[indexPath.row].link
        cell.imageView?.image = UIImage(named: "urls_icon_url")
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let url = playUrls[indexPath.row]
            XYDataBaseManager.default.delete(link: url.link!) { [weak self](error) in
                guard let strongSelf = self, error == nil else {
                    return
                }
                strongSelf.queryDB()
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let link = playUrls[indexPath.row].link, let url = URL(string: link) {
            playURL(url)
        }
        
    }
    
}
