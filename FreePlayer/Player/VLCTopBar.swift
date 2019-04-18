//
//  VLCTopBar.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/27.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class VLCTopBar: UIView {

    var closeWindowAction: (()->Void)?
    var showPadAction: ((Bool)->Void)?
    var showPlayListMenuAction: ((Bool)->Void)?
    
    init() {
        super.init(frame: CGRect(x: 0, y: SCREEN_HEIGHT-44, width: SCREEN_WIDTH, height: 44))
        setupUI()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    private func setupUI() {
        clipsToBounds = false
        backgroundColor = .darkGray
        addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 34, height: 34))
        }
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(closeButton.snp.right).offset(10)
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        titleLabel.text = "title"
        
        addSubview(playlistButton)
        playlistButton.snp.makeConstraints { (make) in
            make.right.equalTo(-15)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 31, height: 31))
        }
        
        addSubview(changeRateButton)
        changeRateButton.snp.makeConstraints { (make) in
            make.right.equalTo(playlistButton.snp.left).offset(-10)
            make.centerY.equalToSuperview()
            make.size.equalTo(playlistButton)
        }
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func close() {
        closeWindowAction?()
    }
    
    @objc private func changeRate(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        showPadAction?(btn.isSelected)
    }
    
    @objc private func showPlayListMenu(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        showPlayListMenuAction?(btn.isSelected)
    }
    
    func setTitle(_ title: String?, buttonState: Bool) {
        titleLabel.text = title
        changeRateButton.isSelected = buttonState
    }
    
    // MARK: lazy load
    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ImageResources.bundle/player_close"), for: .normal)
        btn.addTarget(self, action: #selector(close), for: .touchUpInside)
        return btn
    }()
    
    private lazy var changeRateButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ImageResources.bundle/player_icon_video_steam"), for: .normal)
        btn.setImage(UIImage(named: "ImageResources.bundle/player_icon_video_steam_active"), for: .selected)
        btn.addTarget(self, action: #selector(changeRate(_:)), for: .touchUpInside)
        return btn
    }()
    
    private lazy var playlistButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ImageResources.bundle/menu"), for: .normal)
        btn.addTarget(self, action: #selector(showPlayListMenu(_:)), for: .touchUpInside)
        return btn
    }()
    
    private lazy var titleLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = .white
        lb.font = UIFont.systemFont(ofSize: 14)
        return lb
    }()
}
