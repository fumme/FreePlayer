//
//  VLCPlayListViewController.swift
//  FreePlayer
//
//  Created by CXY on 2019/4/15.
//  Copyright © 2019 cxy. All rights reserved.
//

import UIKit

let showAnimationDuration: TimeInterval = 1

class VLCPlayListViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var bgImg: UIImageView!
    
    @IBOutlet weak var tailingConstraint: NSLayoutConstraint!
    
    private lazy var data = [String]()
    
    var currentItem: String?
    
    var selectionAction: ((Int)->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tailingConstraint.constant = -200
        bgImg.alpha = 0
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        XYFileBrowser.shared.contentsInCurrentDirectory(isVideo: true) { [weak self](files) in
            guard let strongSelf = self else { return }
            strongSelf.data = files.map({ (file) -> String in
                return file.displayName
            })
            strongSelf.tableView.reloadData()
        }
    }
    
    func show() {
        guard view.superview == nil else {
            return
        }
        guard let delegate = UIApplication.shared.delegate as? AppDelegate, let window = delegate.window else { return }
        window.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.bgImg.alpha = 0.65

        UIView.animate(withDuration: showAnimationDuration, animations: {
            self.tailingConstraint.constant = 0
            self.view.setNeedsDisplay()
        }) { (_) in
            self.tableView.reloadData()
            guard let item = self.currentItem else {
                return
            }
            if let idx = self.data.index(of: item) {
                self.tableView.scrollToRow(at: IndexPath(row: idx, section: 0), at: .top, animated: true)
            }
        }
    }
    
    
    func dismiss() {
        UIView.animate(withDuration: showAnimationDuration, animations: {
            self.tailingConstraint.constant = -200
            
            self.view.setNeedsDisplay()
        }) { (_) in
            self.bgImg.alpha = 0
            self.view.removeFromSuperview()
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss()
    }


}



extension VLCPlayListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.contentView.backgroundColor = .black
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
        if data[indexPath.row].elementsEqual(currentItem ?? "") {
            cell.textLabel?.textColor = .red
        } else {
            cell.textLabel?.textColor = .white
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if data[indexPath.row].elementsEqual(currentItem ?? "") {

        } else {
            selectionAction?(indexPath.row)
            dismiss()
        }
       
    }
    
}

