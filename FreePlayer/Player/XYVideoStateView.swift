//
//  JMVideoStateView.swift
//  Jimu2.0
//
//  Created by CXY on 2018/10/30.
//  Copyright © 2018年 ubt. All rights reserved.
//

import UIKit
import AudioToolbox
import SnapKit

enum XYVideoPlayState: Int {
    case waiting
    case playing
    case loading
    case noNetwork
    case noContent
    func tipText() -> String {
        var ret = ""
        switch self {
        case .waiting:
            ret = "小主人请稍等......"
        case .loading:
            ret = "请稍等......"
        case .noNetwork:
            ret = "连不上网络啦，点这试试"
        case .playing:
            ret = ""
        case .noContent:
            ret = "视频飞走了，点这试试"
        }
        return ret
    }
    
    func images() -> [String] {
        var ret = [String]()
        switch self {
        case .waiting, .loading:
            for i in 0...29 {
                let path = String(format: "ImageResources.bundle/video_loading_%05d", i)
                ret.append(path)
            }
        case .noNetwork, .noContent:
            for i in 0...32 {
                let path = String(format: "ImageResources.bundle/video_fresh_%05d", i)
                ret.append(path)
            }
        case .playing:
            ret = []
        }
        return ret
    }
}

class XYVideoStateView: UIView {
    
    var state: XYVideoPlayState {
        didSet {
            tipLabel.text = state.tipText()
        }
    }
    
    var noNetWorkRetryClosure: ((XYVideoStateView)->())?
    var tapClosure: ((XYVideoStateView)->())?
    
    fileprivate lazy var loadingImages: [UIImage] = {
        var ret = [UIImage]()
        for imgname in XYVideoPlayState.loading.images() {
            if let image = UIImage(named: imgname) {
                ret.append(image)
            }
        }
        return ret
    }()
    
    fileprivate lazy var nonetworkImages: [UIImage] = {
        var ret = [UIImage]()
        for imgname in XYVideoPlayState.noNetwork.images() {
            if let image = UIImage(named: imgname) {
                ret.append(image)
            }
        }
        return ret
    }()
    
    fileprivate var imageArray: [UIImage] {
        let ret = [UIImage]()
        switch state {
        case .waiting, .loading:
            return loadingImages
        case .noNetwork, .noContent:
            return nonetworkImages
        default:
            return ret
        }
    }
    
    fileprivate lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    fileprivate lazy var tipLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: HorizontalPixel(11))
        lb.textColor = UIColor(hex: 0x24A8FF)
        lb.textAlignment = .center
        return lb
    }()
    
    override init(frame: CGRect) {
        self.state = .playing
        super.init(frame: frame)

        addSubview(imageView)
        addSubview(tipLabel)
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(HorizontalPixel(116))
            make.height.equalTo(VerticalPixel(50))
            make.centerY.equalToSuperview().offset(-VerticalPixel(10))
        }
        tipLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(VerticalPixel(5))
            make.left.right.equalToSuperview()
            make.height.equalTo(VerticalPixel(16))
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func handleTap(_ tap: UITapGestureRecognizer) {
        if (state == .noNetwork || state == .noContent) && imageView.frame.contains(tap.location(in: self)) {
            noNetWorkRetryClosure?(self)
        } else {
            tapClosure?(self)
        }
    }

    
    func startAnimating() {
        imageView.animationImages = imageArray
        imageView.animationDuration = 1.5
        imageView.startAnimating()
        if state == .noContent {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    func stopAnimating() {
        imageView.stopAnimating()
    }
    
    func show(onView view: UIView) {
        view.addSubview(self)
        self.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        state = .waiting
        startAnimating()
    }
    
    func hide() {
        stopAnimating()
        removeFromSuperview()
    }

}
