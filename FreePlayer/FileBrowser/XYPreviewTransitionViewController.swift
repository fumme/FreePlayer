//
//  XYPreviewTransitionViewController.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/22.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit
import QuickLook

class XYPreviewTransitionViewController: BaseViewController {

    let quickLookPreviewController = QLPreviewController()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(containerView)
        containerView.frame = view.bounds
        self.addChild(quickLookPreviewController)
        containerView.addSubview(quickLookPreviewController.view)
        quickLookPreviewController.view.frame = containerView.bounds
        quickLookPreviewController.didMove(toParent: self)
    }


}
