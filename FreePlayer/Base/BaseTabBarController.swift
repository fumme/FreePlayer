//
//  BaseTabBarController.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/21.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class BaseTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = XYConst.commonBgColor
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

}
