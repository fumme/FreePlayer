//
//  XYMediaPlayerController.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/25.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class CustomAVPlayerController: UIViewController {
    
    private var path: String?
    
    init(path: String) {
        super.init(nibName: nil, bundle: nil)
        self.path = path
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = XYMediaPlayerView(frame: UIScreen.main.bounds)
    }
    
    
    private var player: XYMediaPlayerView? {
        if let layer = view as? XYMediaPlayerView {
            return layer
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    
    func play() {
        if let filePath = path {
            player?.play(url: URL(fileURLWithPath: filePath))
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

}
