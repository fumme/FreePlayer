//
//  XYFileAttributesViewController.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/28.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class XYFileAttributesViewController: BaseViewController {
    
    private var file: XYFile?
    
    init(file: XYFile?) {
        super.init(nibName: nil, bundle: nil)
        self.file = file
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "文件属性"
    }
    

}
