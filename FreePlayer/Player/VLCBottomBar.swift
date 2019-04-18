//
//  VLCBottomBar.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/27.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class VLCBottomBar: UIView {

    private let timeLabelWidth = 60
    private let bottomBarHeight = 56.0
    private let playButtonWidth = 40.0
    private let autoHideBarInterval = TimeInterval(10)
    private let barAnimationDuration = 0.3
    private let barAnimationAlpha = 0.7
    
    var playOrPauseAction: ((Bool)->Void)?
    var playNextAction: (()->Void)?
    var slidingBeganAction: (()->Void)?
    var slidingEndedAction: ((Float)->Void)?
    
    private var inDraging = false
    
    var isInAction: Bool {
        return inDraging
    }
    
    var currentTimeLabelHidden = false {
        didSet {
            currentTimeLabelWidthConstraint?.constant = CGFloat(currentTimeLabelHidden ? 0 : timeLabelWidth)
            progressLabel.isHidden = currentTimeLabelHidden
        }
    }
    
    var totalTimeLabelHidden = false {
        didSet {
            totalTimeLabelWidthConstraint?.constant = CGFloat(totalTimeLabelHidden ? 0 : timeLabelWidth)
            totalDurationLabel.isHidden = totalTimeLabelHidden
        }
    }
    
    var zoomButtonHidden = false {
        didSet {
            zoomButtonWidthConstraint?.constant = zoomButtonHidden ? 0 : 40
            zoomScreenBtn.isHidden = zoomButtonHidden
        }
    }
    
    private var currentTimeLabelWidthConstraint: NSLayoutConstraint?
    private var totalTimeLabelWidthConstraint: NSLayoutConstraint?
    private var zoomButtonWidthConstraint: NSLayoutConstraint?
    private var loadingViewBottomConstraint: NSLayoutConstraint?
    
    
    private lazy var playOrPauseBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .clear
        btn.layer.opacity = 1
        btn.contentMode = .center
        btn.setBackgroundImage(UIImage(named: "ImageResources.bundle/play"), for: .normal)
        btn.setBackgroundImage(UIImage(named: "ImageResources.bundle/pause"), for: .selected)
        btn.addTarget(self, action: #selector(playOrPause(_:)), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private lazy var playNextBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .clear
        btn.layer.opacity = 1
        btn.contentMode = .center
        btn.setBackgroundImage(UIImage(named: "ImageResources.bundle/next"), for: .normal)
        btn.addTarget(self, action: #selector(playNextVideo(_:)), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private lazy var progressLabel: UILabel = {
        let lb = UILabel()
        lb.textAlignment = .center
        lb.text = "00:00"
        lb.font = UIFont.systemFont(ofSize: 12)
        lb.textColor = .white
        lb.translatesAutoresizingMaskIntoConstraints = false
        return lb
    }()
    
    private lazy var slider: XYVideoSlider = {
        let slider = XYVideoSlider()
        slider.bgColor = .white
        slider.progressColor = .yellow
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.draggingSliderClosure = { [weak self] sd  in
            self?.sliderChanging()
        }
        slider.finishedClosure = { [weak self] sd  in
            self?.sliderEndedChange()
        }
        slider.valueChangedClosure = { [weak self] sd  in
            self?.sliderValueChanged()
        }
        return slider
    }()
    
    private lazy var totalDurationLabel: UILabel = {
        let lb = UILabel()
        lb.textAlignment = .center
        lb.text = "00:00"
        lb.font = UIFont.systemFont(ofSize: 12)
        lb.textColor = .white
        lb.translatesAutoresizingMaskIntoConstraints = false
        return lb
    }()
    
    private lazy var zoomScreenBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ImageResources.bundle/btn_zoom_out"), for: .normal)
        btn.setImage(UIImage(named: "ImageResources.bundle/btn_zoom_in"), for: .selected)
//        btn.addTarget(self, action: #selector(fullScreen(_:)), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.darkGray
        layer.opacity = 1
        // add play button
        addSubview(playOrPauseBtn)
        
        addSubview(playNextBtn)
        // add progress label
        addSubview(progressLabel)
        // add zoom in/out button
        addSubview(zoomScreenBtn)
        // add total duration label
        addSubview(totalDurationLabel)
        // add slider
        addSubview(slider)
        
        layoutUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func layoutUI() {
        // layout play button
        let playBtnWidthConst = NSLayoutConstraint(item: playOrPauseBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: CGFloat(HorizontalPixel(CGFloat(playButtonWidth))))
        let playBtnHeightConst = NSLayoutConstraint(item: playOrPauseBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: CGFloat(HorizontalPixel(CGFloat(playButtonWidth))))
        let playBtnCenXConst = NSLayoutConstraint(item: playOrPauseBtn, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: HorizontalPixel(18))
        let playBtnCenYConst = NSLayoutConstraint(item: playOrPauseBtn, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)
        addConstraints([playBtnWidthConst, playBtnHeightConst, playBtnCenXConst, playBtnCenYConst])
        
        let nextBtnLeftConstraint = NSLayoutConstraint(item: playNextBtn, attribute: .left, relatedBy: .equal, toItem: playOrPauseBtn, attribute: .right, multiplier: 1.0, constant: HorizontalPixel(14))
        let nextBtnCenterYConstraint = NSLayoutConstraint(item: playNextBtn, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)
        let nextBtnWidthConstraint = NSLayoutConstraint(item: playNextBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: CGFloat(HorizontalPixel(CGFloat(playButtonWidth))))
        let nextBtnHeightConstraint = NSLayoutConstraint(item: playNextBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: CGFloat(HorizontalPixel(CGFloat(playButtonWidth))))
        addConstraints([nextBtnLeftConstraint, nextBtnCenterYConstraint, nextBtnWidthConstraint, nextBtnHeightConstraint])
        
        let progressLbLeftConst = NSLayoutConstraint(item: progressLabel, attribute: .left, relatedBy: .equal, toItem: playNextBtn, attribute: .right, multiplier: 1.0, constant: HorizontalPixel(14))
        let progressLbTopConst = NSLayoutConstraint(item: progressLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0)
        let progressLbBottomConst = NSLayoutConstraint(item: progressLabel, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
        let progressLbWidthConst = NSLayoutConstraint(item: progressLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: CGFloat(timeLabelWidth))
        currentTimeLabelWidthConstraint = progressLbWidthConst
        addConstraints([progressLbLeftConst, progressLbTopConst, progressLbBottomConst, progressLbWidthConst])
        // layout zoom button
        let zoomBtnWidthConst = NSLayoutConstraint(item: zoomScreenBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 40)
        zoomButtonWidthConstraint = zoomBtnWidthConst
        let zoomBtnHeightConst = NSLayoutConstraint(item: zoomScreenBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 40)
        let zoomBtnRightConst = NSLayoutConstraint(item: zoomScreenBtn, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0)
        let zoomBtnCenterYConst = NSLayoutConstraint(item: zoomScreenBtn, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)
        addConstraints([zoomBtnWidthConst, zoomBtnHeightConst, zoomBtnRightConst, zoomBtnCenterYConst])
        // layout total label
        let totalDurationLbRightConst = NSLayoutConstraint(item: totalDurationLabel, attribute: .right, relatedBy: .equal, toItem: zoomScreenBtn, attribute: .left, multiplier: 1.0, constant: -HorizontalPixel(62))
        let totalDurationLbTopConst = NSLayoutConstraint(item: totalDurationLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0)
        let totalDurationLbBottomConst = NSLayoutConstraint(item: totalDurationLabel, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
        let totalDurationLbWidthConst = NSLayoutConstraint(item: totalDurationLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: CGFloat(timeLabelWidth))
        totalTimeLabelWidthConstraint = totalDurationLbWidthConst
        addConstraints([totalDurationLbRightConst, totalDurationLbTopConst, totalDurationLbBottomConst, totalDurationLbWidthConst])
        // layout slider
        let sliderLeftConst = NSLayoutConstraint(item: slider, attribute: .left, relatedBy: .equal, toItem: progressLabel, attribute: .right, multiplier: 1.0, constant: 0)
        let sliderRightConst = NSLayoutConstraint(item: slider, attribute: .right, relatedBy: .equal, toItem: totalDurationLabel, attribute: .left, multiplier: 1.0, constant: 0)
        let sliderTopConst = NSLayoutConstraint(item: slider, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0)
        let sliderBottomconst = NSLayoutConstraint(item: slider, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
        addConstraints([sliderLeftConst, sliderRightConst, sliderTopConst, sliderBottomconst])
    }
    
    
    
    // MARK: slider事件
    private func sliderChanging() {
        inDraging = true
        slidingBeganAction?()
    }
    
    private func sliderValueChanged() {
        inDraging = false
    }
    
    private func sliderEndedChange() {
        inDraging = false
        slidingEndedAction?(Float(slider.value))
    }
    
    // MARK: 播放/暂停事件
    @objc private func playOrPause(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        playOrPauseAction?(btn.isSelected)
    }
    
    @objc private func playNextVideo(_ btn: UIButton) {
        playNextAction?()
    }
    
    func update(currentTime: String, totalTime: String, sliderValue: Double) {
        progressLabel.text = currentTime
        totalDurationLabel.text = totalTime
        slider.value = sliderValue
    }
    
    func changePlayButtonState(_ state: Bool) {
        playOrPauseBtn.isSelected = state
    }
    
    override var isHidden: Bool {
        didSet {
            slider.layoutSubviews()
        }
    }


}
