//
//  XYPasteLabel.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/27.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class XYPasteLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private lazy var pasteBoard: UIPasteboard = UIPasteboard.general
    
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
    
    private lazy var menuController: UIMenuController = {
        let copyItem = UIMenuItem(title: "复制", action: #selector(copyAction(_:)))
        let menuController = UIMenuController.shared
        menuController.menuItems = [copyItem]
        return menuController
    }()
    
    private func setup() {
        numberOfLines = 0
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func tapAction(_ gesture: UITapGestureRecognizer) {
        becomeFirstResponder()
        menuController.setTargetRect(frame, in: superview!)
        menuController.setMenuVisible(true, animated: true)
    }
    
    @objc func copyAction(_ item: UIMenuItem) {
        pasteBoard.string = text
        print("复制内容为： \(pasteBoard.string!)")
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copyAction(_:)) {
            return true
        }
        return false

    }
    
}
