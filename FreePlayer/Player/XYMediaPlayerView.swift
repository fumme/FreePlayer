//
//  JMVideoLayer.swift
//  Jimu2.0
//
//  Created by CXY on 2018/10/22.
//  Copyright © 2018年 cxy. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

class XYMediaPlayerView: UIView {
    // 是否自动隐藏工具栏
    fileprivate var shouldAutoHideBar = false
    // 是否工具栏覆盖在layer上
    var shouldAVPlayerLayerFill = false
    
    fileprivate var isPlayingBeforeInBackground = false
    
    fileprivate var isPlaying: Bool {
        return player.rate > 0
    }
    
    fileprivate var isPlayingBeforePhoneCall = false
    
    fileprivate let timeLabelWidth = 60
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
    
    fileprivate let reachabilityManager = NetworkReachabilityManager()
    
    fileprivate var currentTimeLabelWidthConstraint: NSLayoutConstraint?
    fileprivate var totalTimeLabelWidthConstraint: NSLayoutConstraint?
    fileprivate var zoomButtonWidthConstraint: NSLayoutConstraint?
    fileprivate var loadingViewBottomConstraint: NSLayoutConstraint?
    
    fileprivate var videoUrl: URL? {
        didSet {
            player.currentItem?.removeObserver(self, forKeyPath: "status")
            player.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
            if videoUrl == nil {
                playerItem = nil
            } else {
                playerItem = AVPlayerItem(url: videoUrl!)
            }
            DispatchQueue.global().async {
                self.player.replaceCurrentItem(with: self.playerItem)
            }
        }
    }
    
    fileprivate var videoLength: Double {
        guard let duration = player.currentItem?.duration else {
            return 0.0
        }
        return CMTimeGetSeconds(duration)
    }
    
    fileprivate var attachView: UIView?
    fileprivate var bottomBaHeight = 56.0
    fileprivate var playButtonWidth = 40.0
    fileprivate var autoHideBarInterval = TimeInterval(10)
    fileprivate var barAnimationDuration = 0.3
    fileprivate var barAnimationAlpha = 0.7
    
    /// 是否显示工具栏
    fileprivate var isBarHidden = true
    
    /// 是否操作工具栏中
    fileprivate var inOperation = false
    
    fileprivate lazy var player = AVPlayer(playerItem: playerItem)

    fileprivate lazy var playerLayer: AVPlayerLayer = {
        let layer = AVPlayerLayer(player: player)
        layer.backgroundColor = UIColor.black.cgColor
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    fileprivate var playerItem: AVPlayerItem?
    
    fileprivate lazy var playOrPauseBtn: UIButton = {
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
    
    fileprivate lazy var activityIndicatorView: XYVideoStateView = {
        let indicator = XYVideoStateView()
        indicator.backgroundColor = .black
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.noNetWorkRetryClosure = { [weak self] _ in
            guard let sSelf = self else { return }
            if let tmp = self?.reachabilityManager?.isReachable, !tmp {
                return
            }
            sSelf.activityIndicatorView.isHidden = true
            sSelf.activityIndicatorView.stopAnimating()
            sSelf.playOrPause(sSelf.playOrPauseBtn)
        }
        indicator.tapClosure = { [weak self] _ in
            guard let sSelf = self else { return }
            sSelf.fullScreen(sSelf.zoomScreenBtn)
        }
        return indicator
    }()
    
    fileprivate lazy var progressLabel: UILabel = {
        let lb = UILabel()
        lb.textAlignment = .center
        lb.text = "00:00:00"
        lb.font = UIFont.systemFont(ofSize: 12)
        lb.textColor = .white
        lb.translatesAutoresizingMaskIntoConstraints = false
        return lb
    }()
    
    fileprivate lazy var slider: XYVideoSlider = {
        let slider = XYVideoSlider()
        slider.bgColor = UIColor(hex: 0x2DA0FF)
        slider.progressColor = UIColor(hex: 0x2DA0FF)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.paning = { [weak self] sd  in
            self?.sliderChanging()
        }
        slider.endedPan = { [weak self] sd  in
            self?.sliderEndedChange()
        }
        slider.startPan = { [weak self] sd  in
            self?.sliderValueChanged()
        }
        return slider
    }()
    
    fileprivate lazy var totalDurationLabel: UILabel = {
        let lb = UILabel()
        lb.textAlignment = .center
        lb.text = "00:00:00"
        lb.font = UIFont.systemFont(ofSize: 12)
        lb.textColor = .white
        lb.translatesAutoresizingMaskIntoConstraints = false
        return lb
    }()
    
    fileprivate lazy var zoomScreenBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ImageResources.bundle/btn_zoom_out"), for: .normal)
        btn.setImage(UIImage(named: "ImageResources.bundle/btn_zoom_in"), for: .selected)
        btn.addTarget(self, action: #selector(fullScreen(_:)), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: -UI工具栏
    fileprivate lazy var bottomBar: UIView = {
        let bar = UIView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = .black
        bar.layer.opacity = 0.7
        // add play button
        bar.addSubview(playOrPauseBtn)
        // add progress label
        bar.addSubview(progressLabel)
        // add zoom in/out button
        bar.addSubview(zoomScreenBtn)
        // add total duration label
        bar.addSubview(totalDurationLabel)
        // add slider
        bar.addSubview(slider)
        return bar
    }()
    
    fileprivate lazy var topBar: UIView = {
        let view = UIView()
        return view
    }()
    
    // MARK: -初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        
        addSubview(activityIndicatorView)
        addSubview(bottomBar)
        // layoout bottom bar
        let leading = NSLayoutConstraint(item: bottomBar, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: bottomBar, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        let tailing = NSLayoutConstraint(item: bottomBar, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: bottomBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: CGFloat(bottomBaHeight))
        addConstraints([leading, bottom, tailing, height])
        // layout indicator
        let indicatorLeftConstr = NSLayoutConstraint(item: activityIndicatorView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0)
        let indicatorTopConstr = NSLayoutConstraint(item: activityIndicatorView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0)
        let indicatorRightConstr = NSLayoutConstraint(item: activityIndicatorView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0)
        let indicatorBottomConstr = NSLayoutConstraint(item: activityIndicatorView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: shouldAVPlayerLayerFill ? 0 : CGFloat(-bottomBaHeight))
        loadingViewBottomConstraint = indicatorBottomConstr
        addConstraints([indicatorLeftConstr, indicatorTopConstr, indicatorRightConstr, indicatorBottomConstr])
        
        // layout play button
        let playBtnWidthConst = NSLayoutConstraint(item: playOrPauseBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: CGFloat(HorizontalPixel(CGFloat(playButtonWidth))))
        let playBtnHeightConst = NSLayoutConstraint(item: playOrPauseBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: CGFloat(HorizontalPixel(CGFloat(playButtonWidth))))
        let playBtnCenXConst = NSLayoutConstraint(item: playOrPauseBtn, attribute: .left, relatedBy: .equal, toItem: bottomBar, attribute: .left, multiplier: 1.0, constant: HorizontalPixel(18))
        let playBtnCenYConst = NSLayoutConstraint(item: playOrPauseBtn, attribute: .centerY, relatedBy: .equal, toItem: bottomBar, attribute: .centerY, multiplier: 1.0, constant: 0)
        bottomBar.addConstraints([playBtnWidthConst, playBtnHeightConst, playBtnCenXConst, playBtnCenYConst])
        // layout progress label
        let bar = bottomBar
        let progressLbLeftConst = NSLayoutConstraint(item: progressLabel, attribute: .left, relatedBy: .equal, toItem: playOrPauseBtn, attribute: .right, multiplier: 1.0, constant: HorizontalPixel(14))
        let progressLbTopConst = NSLayoutConstraint(item: progressLabel, attribute: .top, relatedBy: .equal, toItem: bar, attribute: .top, multiplier: 1.0, constant: 0)
        let progressLbBottomConst = NSLayoutConstraint(item: progressLabel, attribute: .bottom, relatedBy: .equal, toItem: bar, attribute: .bottom, multiplier: 1.0, constant: 0)
        let progressLbWidthConst = NSLayoutConstraint(item: progressLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: CGFloat(timeLabelWidth))
        currentTimeLabelWidthConstraint = progressLbWidthConst
        bar.addConstraints([progressLbLeftConst, progressLbTopConst, progressLbBottomConst, progressLbWidthConst])
        // layout zoom button
        let zoomBtnWidthConst = NSLayoutConstraint(item: zoomScreenBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 40)
        zoomButtonWidthConstraint = zoomBtnWidthConst
        let zoomBtnHeightConst = NSLayoutConstraint(item: zoomScreenBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 40)
        let zoomBtnRightConst = NSLayoutConstraint(item: zoomScreenBtn, attribute: .right, relatedBy: .equal, toItem: bar, attribute: .right, multiplier: 1.0, constant: 0)
        let zoomBtnCenterYConst = NSLayoutConstraint(item: zoomScreenBtn, attribute: .centerY, relatedBy: .equal, toItem: bar, attribute: .centerY, multiplier: 1.0, constant: 0)
        bar.addConstraints([zoomBtnWidthConst, zoomBtnHeightConst, zoomBtnRightConst, zoomBtnCenterYConst])
        // layout total label
        let totalDurationLbRightConst = NSLayoutConstraint(item: totalDurationLabel, attribute: .right, relatedBy: .equal, toItem: zoomScreenBtn, attribute: .left, multiplier: 1.0, constant: -HorizontalPixel(62))
        let totalDurationLbTopConst = NSLayoutConstraint(item: totalDurationLabel, attribute: .top, relatedBy: .equal, toItem: bar, attribute: .top, multiplier: 1.0, constant: 0)
        let totalDurationLbBottomConst = NSLayoutConstraint(item: totalDurationLabel, attribute: .bottom, relatedBy: .equal, toItem: bar, attribute: .bottom, multiplier: 1.0, constant: 0)
        let totalDurationLbWidthConst = NSLayoutConstraint(item: totalDurationLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: CGFloat(timeLabelWidth))
        totalTimeLabelWidthConstraint = totalDurationLbWidthConst
        bar.addConstraints([totalDurationLbRightConst, totalDurationLbTopConst, totalDurationLbBottomConst, totalDurationLbWidthConst])
        // layout slider
        let sliderLeftConst = NSLayoutConstraint(item: slider, attribute: .left, relatedBy: .equal, toItem: progressLabel, attribute: .right, multiplier: 1.0, constant: 0)
        let sliderRightConst = NSLayoutConstraint(item: slider, attribute: .right, relatedBy: .equal, toItem: totalDurationLabel, attribute: .left, multiplier: 1.0, constant: 0)
        let sliderTopConst = NSLayoutConstraint(item: slider, attribute: .top, relatedBy: .equal, toItem: bar, attribute: .top, multiplier: 1.0, constant: 0)
        let sliderBottomconst = NSLayoutConstraint(item: slider, attribute: .bottom, relatedBy: .equal, toItem: bar, attribute: .bottom, multiplier: 1.0, constant: 0)
        bar.addConstraints([sliderLeftConst, sliderRightConst, sliderTopConst, sliderBottomconst])
        
        //
        startNetworkReachabilityObserver()
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        
    
        bringSubviewToFront(activityIndicatorView)
        activityIndicatorView.state = .loading
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
    }

    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -私有方法
    // MARK: 开始网络状态监听
    fileprivate func startNetworkReachabilityObserver() {
        reachabilityManager?.listener = { [weak self]status in
            guard let _ = self else { return }
            switch status {
            case .notReachable:
//                print("The network is not reachable")
//                sSelf.activityIndicatorView.state = .noNetwork
//                sSelf.activityIndicatorView.isHidden = false
//                sSelf.activityIndicatorView.startAnimating()
//                if sSelf.isPlaying {
//                    sSelf.playOrPause(sSelf.playOrPauseBtn)
//                }
                break
            case .unknown :
//                print("It is unknown whether the network is reachable")
                break
            case .reachable(.ethernetOrWiFi):
//                print("The network is reachable over the WiFi connection")
                break
            case .reachable(.wwan):
//                print("The network is reachable over the WWAN connection")
                break

            }
        }
        
        // start listening
        reachabilityManager?.startListening()
        startApplicationNotificationObserver()
    }
    
    // MARK: 停止网络状态监听
    fileprivate func endNetworkReachabilityObserver() {
        reachabilityManager?.stopListening()
    }
    
    // MARK: App状态监听
    fileprivate func startApplicationNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicaitonEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicaitonEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(avSessionInterrupt(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    @objc fileprivate func applicaitonEnterBackground(_ notif: Notification) {
        isPlayingBeforeInBackground = isPlaying
        if isPlayingBeforeInBackground {
            playOrPause(playOrPauseBtn)
        }
    }
    
    @objc fileprivate func applicaitonEnterForeground(_ notif: Notification) {
        if isPlayingBeforeInBackground {
            playOrPause(playOrPauseBtn)
        }
    }

    
    @objc fileprivate func avSessionInterrupt(_ notif: Notification) {
        guard let info = notif.userInfo, let interType = info[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
    
        switch interType {
        case AVAudioSession.InterruptionType.began.rawValue:
            // 暂停播放,实际上已经暂停了
            if isPlayingBeforePhoneCall {
                playOrPauseBtn.isSelected = false
                player.pause()
            }
            break
        case AVAudioSession.InterruptionType.ended.rawValue:
            break
        default:
            break
        }
        
        guard let secReason = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
        switch secReason {
        case AVAudioSession.InterruptionOptions.shouldResume.rawValue:
            perform(#selector(restorePlayingState), with: nil, afterDelay: 1.5)
            break
        default:
            break
        }
    }
    
    @objc fileprivate func restorePlayingState() {
        if isPlayingBeforePhoneCall {
            playOrPause(playOrPauseBtn)
        }
    }

    fileprivate func timeString(time: Int) -> String {
        let seconds = time%60
        let minutes = (time/60)%60
        let hours = time/3600
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: 监控视频播放进度
    fileprivate func addProgressObserver() {
        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, preferredTimescale: Int32(NSEC_PER_SEC)), queue: DispatchQueue.main) { [weak self](time) in
            guard let total = self?.player.currentItem?.duration else { return }
            let current = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(total)
            if duration > 0 {
                let percent = current/duration
                if let hid = self?.bottomBar.isHidden, !hid {
                    self?.slider.value = percent
                }
                self?.totalDurationLabel.text = self?.timeString(time: Int(ceil(duration)))
                // 四舍五入处理
                self?.progressLabel.text = self?.timeString(time: lroundf(Float(current)))
                if percent == 1.0 {// 完成后重新开始 若是大屏，切换到小屏
                    if (self?.zoomScreenBtn.isSelected)! == true {
                        self?.fullScreen((self?.zoomScreenBtn)!)
                    }
                    self?.playOrPauseBtn.isSelected = false
                    self?.isPlayingBeforePhoneCall = false
                    self?.showOrHiddenBottomBar()
                    let begintime = CMTimeMake(value: 0, timescale: 1)
                    self?.player.seek(to: begintime, completionHandler: { (fin) in
                        if fin {
                            self?.slider.value = 0
                        }
                    })
                }
            }
        }
    }
    
    // 监听AVPlayerItem对象的status/loadedTimeRanges属性变化，status对应播放状态，loadedTimeRanges网络缓冲状态，当loadedTimeRanges的改变时，每缓冲一部分数据就会更新此属性，可以获得本次缓冲加载的视频范围（包含起始时间、本次网络加载时长）
    fileprivate func addPlayerItemObserver() {
        guard let item = player.currentItem else { return }
        item.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        item.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let path = keyPath, let dict = change, let duration = player.currentItem?.duration, let item = player.currentItem else { return }
        if path.elementsEqual("status") {
            if let status = dict[NSKeyValueChangeKey.newKey] as? Int {
                if status == AVPlayer.Status.readyToPlay.rawValue {// 显示总时长
                    let total = CMTimeGetSeconds(duration)
                    if total > 0 {
                        self.totalDurationLabel.text = timeString(time: Int(total))
                    }
                }
            }
        } else if path.elementsEqual("loadedTimeRanges") {// 计算缓存时长
            let array = item.loadedTimeRanges
            guard let timeRange = array.first?.timeRangeValue else { return }
            let start = CMTimeGetSeconds(timeRange.start)
            let length = CMTimeGetSeconds(timeRange.duration)
            // 缓冲总长度
            let totalBuffer = start + length
            let videoLength = CMTimeGetSeconds(duration)
            let ratio = totalBuffer/videoLength
//            print("缓冲总长度:\(totalBuffer), 视频总长度:\(videoLength), 进度：\(ratio)")
            // 设置缓存进度
            // slider.middleValue = ratio
            if slider.value >= ratio {
                if (reachabilityManager?.isReachable)! {
                    activityIndicatorView.isHidden = false
                    activityIndicatorView.state = .loading
                    activityIndicatorView.startAnimating()
                } else {
                    activityIndicatorView.isHidden = false
                    activityIndicatorView.state = .noNetwork
                    activityIndicatorView.startAnimating()
                }
            } else {
                activityIndicatorView.isHidden = true
                activityIndicatorView.stopAnimating()
            }
        }
    }
    
    // MARK: 播放/暂停事件
    @objc fileprivate func playOrPause(_ btn: UIButton) {
        if player.rate == 0 {
            btn.isSelected = true
            player.play()
            isPlayingBeforePhoneCall = true
        } else if player.rate == 1 {
            btn.isSelected = false
            player.pause()
            isPlayingBeforePhoneCall = false
        }
    }
    
    // MARK: 全屏播放事件
    @objc fileprivate func fullScreen(_ btn: UIButton) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let keyWindow = appDelegate.window else {
            return
        }
        btn.isSelected = !btn.isSelected
        if superview != nil && btn.isSelected {// zoom out
            attachView = superview
            removeFromSuperview()
            keyWindow.addSubview(self)
            if let frame = attachView?.convert(self.frame, to: keyWindow) {
                self.frame = frame
                UIView.animate(withDuration: 0.3, animations: {
                    self.playerLayer.frame = keyWindow.bounds
                    self.bottomBar.isHidden = true
                }) { (_) in
                    self.addConstraints(superview: keyWindow)
                    self.loadingViewBottomConstraint?.constant = 0
                }
            }
        } else {// zoom in
            if let superview = attachView, let frame = superview.superview?.convert(superview.frame, to: keyWindow) {
                self.frame = frame
                playerLayer.frame = frame
                removeFromSuperview()
                superview.addSubview(self)
                addConstraints(superview: superview)
                if shouldAVPlayerLayerFill {
                    playerLayer.frame = frame
                    loadingViewBottomConstraint?.constant = 0
                } else {
                    playerLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height-CGFloat(bottomBaHeight))
                    loadingViewBottomConstraint?.constant = CGFloat(-bottomBaHeight)
                }
                bottomBar.isHidden = false
            }
        }
    }
    
    // MARK: 添加VFL约束
    fileprivate func addConstraints(superview: UIView) {
        let horConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["view": self])
        let verConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["view": self])
        superview.addConstraints(horConstraints)
        superview.addConstraints(verConstraints)
    }

    fileprivate func pause() {
        player.pause()
    }
    
    // MARK: 点击事件
    @objc fileprivate func handleTap(_ tap: UITapGestureRecognizer) {
        if inOperation { return }
        if shouldAutoHideBar {
            showOrHiddenBottomBar()
        } else {
            let postion = tap.location(in: self)
            if activityIndicatorView.bounds.contains(postion) {// zoom out
                fullScreen(zoomScreenBtn)
            }
        }
        
    }
    
    // MARK: 显示工具栏
    @objc fileprivate func showOrHiddenBottomBar() {
        if shouldAutoHideBar {
            if isBarHidden {
                showBar()
            } else {
                hiddenBar()
            }
        }
    }
    
    @objc fileprivate func showBar() {
        UIView.animate(withDuration: barAnimationDuration, animations: {
            self.bottomBar.layer.opacity = Float(self.barAnimationAlpha)
            self.playOrPauseBtn.layer.opacity = Float(self.barAnimationAlpha)
        }) { (fin) in
            if fin {
                self.isBarHidden = !self.isBarHidden
                self.perform(#selector(self.autoHideBar), with: nil, afterDelay: self.autoHideBarInterval)
            }
        }
    }
    
    @objc fileprivate func autoHideBar() {
        if !self.isBarHidden && !self.inOperation && shouldAutoHideBar {
            self.hiddenBar()
        }
    }
    
    @objc fileprivate func hiddenBar() {
        inOperation = false
        UIView.animate(withDuration: barAnimationDuration, animations: {
            self.bottomBar.layer.opacity = 0
            self.playOrPauseBtn.layer.opacity = 0
        }) { (fin) in
            if fin {
                self.isBarHidden = !self.isBarHidden
            }
        }
    }
    
    // MARK: slider事件
    fileprivate func sliderChanging() {
        inOperation = true
        player.pause()
    }
    
    fileprivate func sliderValueChanged() {
        progressLabel.text = timeString(time: Int(lround(slider.value*videoLength)))
    }
    
    fileprivate func sliderEndedChange() {
        inOperation = false
        XYMediaPlayerView.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.autoHideBar), object: nil)
        self.perform(#selector(self.autoHideBar), with: nil, afterDelay: autoHideBarInterval)
        player.pause()
        let begintime = CMTimeMake(value: Int64(lround(slider.value*videoLength)), timescale: 1)
        player.seek(to: begintime, completionHandler: { (fin) in
            if fin {
                self.player.play()
                self.playOrPauseBtn.isSelected = true
                self.isPlayingBeforePhoneCall = true
            }
        })
    }
    
    deinit {
        print("\(self)", #function)
        endNetworkReachabilityObserver()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    
    // MARK: -公有方法
    // MARK: 开始播放
    func play(url: URL) {
        player.rate = 0
        slider.value = 0
        videoUrl = url
        if playerLayer.superlayer == nil {
            layer.addSublayer(playerLayer)
            if shouldAVPlayerLayerFill {
                playerLayer.frame = bounds
            } else {
                playerLayer.frame = CGRect(x: 0, y: 0, width: Double(bounds.size.width), height: Double(bounds.size.height)-bottomBaHeight)
            }
        
            bringSubviewToFront(activityIndicatorView)
            bringSubviewToFront(bottomBar)
        }
        activityIndicatorView.state = .loading
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
        addProgressObserver()
        addPlayerItemObserver()
        playOrPause(playOrPauseBtn)
    }
    
    func destroyPlayer() {
        player.pause()
        player.currentItem?.cancelPendingSeeks()
        player.currentItem?.asset.cancelLoading()
        player.currentItem?.removeObserver(self, forKeyPath: "status")
        player.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
    }
}



