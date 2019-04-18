//
//  BaseNavigationController.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/20.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController, UIGestureRecognizerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = XYConst.commonBgColor
        interactivePopGestureRecognizer?.delegate = self
    }
    
    // http://chisj.github.io/blog/2015/05/27/uinavigationcontrollerfan-hui-shou-shi-shi-xiao-wen-ti/
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
//        interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        if let _ = topViewController as? XYFileListViewController {
            XYFileBrowser.shared.backToParentDirectory()
        }
        return super.popViewController(animated: animated)
    }

}
