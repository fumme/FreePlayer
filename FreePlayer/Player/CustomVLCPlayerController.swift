//
//  CustomVLCPlayerController.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/26.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class CustomVLCPlayerController: BaseViewController {
    
    private var url: URL?
    
    private var index = -1
    
    private let listPlayer: VLCMediaListPlayer = {
        let player = VLCMediaListPlayer()
        player.repeatMode = .doNotRepeat
        return player
    }()
    
    private var files = [XYFile]()
    
    var vlcPlayer: VLCMediaPlayer {
        return listPlayer.mediaPlayer
    }
    
    private lazy var gesture: UIPanGestureRecognizer = {
        let ges = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        return ges
    }()
    
    private let barHeight = 44.0
    
    private var progress = 0.0
    
    private var isAnimating = false
    
    private var isShowBar = false
    
    private let timeInterval: TimeInterval = 5
    
    
    private lazy var timer = WeakTimer.scheduledWeakTimer(timeInterval: timeInterval, target: self, selector: #selector(autoHideBar), userInfo: nil, repeats: true)
    
    private lazy var topBar: VLCTopBar = {
        let bar = VLCTopBar()
        bar.setTitle(url?.lastPathComponent, buttonState: false)
        bar.closeWindowAction = {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.dismiss(animated: true, completion: nil)
        }
        bar.showPadAction = {[weak self] onOff in
            guard let strongSelf = self else { return }
            if onOff {
                strongSelf.view.addSubview(strongSelf.pad)
                strongSelf.pad.snp.makeConstraints{ make in
                    make.center.equalToSuperview()
                    make.height.equalTo(150)
                    make.width.equalTo(300)
                }
                strongSelf.pad.selectedRate = strongSelf.vlcPlayer.rate
            } else {
                strongSelf.pad.removeFromSuperview()
            }
        }
        
        bar.showPlayListMenuAction = {[weak self] onOff in
            guard let strongSelf = self else { return }
            strongSelf.playListMenu.currentItem = strongSelf.url?.lastPathComponent
            strongSelf.playListMenu.show()
        }
        bar.isHidden = true
        return bar
    }()
    
    private lazy var playListMenu: VLCPlayListViewController = {
        let menu = VLCPlayListViewController()
        menu.selectionAction = {[weak self] idx in
            guard let strongSelf = self else { return }
            if let media = strongSelf.listPlayer.mediaList.media(at: UInt(idx)) {
                strongSelf.listPlayer.play(media)
                strongSelf.url = strongSelf.files[idx].fileURL
                strongSelf.topBar.setTitle(strongSelf.url?.lastPathComponent, buttonState: false)
                strongSelf.index = idx
            }
        }
        return menu
    }()
    
    private lazy var bottomBar: VLCBottomBar = {
        let bar = VLCBottomBar()
        bar.isHidden = true
        bar.playOrPauseAction = {[weak self] onOff in
            guard let strongSelf = self else { return }
            if onOff {
                strongSelf.vlcPlayer.play()
            } else {
                strongSelf.vlcPlayer.pause()
            }
        }
        bar.slidingBeganAction = {[weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.vlcPlayer.isPlaying {
                strongSelf.vlcPlayer.pause()
            }
        }
        bar.slidingEndedAction = {[weak self] value in
            guard let strongSelf = self else { return }
            let deltaProgress = Double(value) - strongSelf.progress
            let delta = Int32(deltaProgress * Double(strongSelf.mediaTime.intValue)/1000.0)
            if delta < 0 {
                strongSelf.vlcPlayer.jumpBackward(-delta)
            } else if delta > 0 {
                strongSelf.vlcPlayer.jumpForward(delta)
            }
            strongSelf.vlcPlayer.play()
        }
        
        bar.playNextAction = {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.playItem(atIndex: strongSelf.index + 1)
        }
        
        bar.dragingStateChanged = {[weak self] ret in
            guard let strongSelf = self else { return }
            strongSelf.timer.fireDate = ret ? Date.distantFuture : Date(timeIntervalSinceNow: strongSelf.timeInterval)
        }
        return bar
    }()
    
    
    private lazy var videoView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private lazy var pad: VLCControlPad = {
        let pad = VLCControlPad()
        pad.sliderValueChanged = { [weak self] value in
            guard let strongSelf = self else { return }
            strongSelf.vlcPlayer.rate = value
        }
        return pad
    }()
    
    private var mediaTime: VLCTime {
        return vlcPlayer.media.length
    }
    
    init(url: URL) {
        super.init(nibName: nil, bundle: nil)
        
        self.url = url
        print("url == \(url)")
        
        XYFileBrowser.shared.contentsInCurrentDirectory(isVideo: true) { [weak self](files) in
            guard let strongSelf = self else { return }
            if files.count > 0 {
                strongSelf.files = files
                
                var count = 0
                let medias = files.map { (file) -> VLCMedia in
                    if file.fileURL.absoluteString.elementsEqual(url.absoluteString) {
                        strongSelf.index = count
                    }
                    count += 1
                    return VLCMedia(url: file.fileURL)
                }
                strongSelf.listPlayer.mediaList = VLCMediaList(array: medias)
                strongSelf.vlcPlayer.drawable = strongSelf.videoView
                strongSelf.vlcPlayer.delegate = self
                let rate = UserDefaults.standard.float(forKey: playRateKey)
                strongSelf.vlcPlayer.rate = rate > 1 ? rate : 1
                strongSelf.playItem(atIndex: strongSelf.index)
                
            }
        }
       
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        videoView.addGestureRecognizer(gesture)
        view.addSubview(videoView)
        videoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(topBar)
        topBar.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(barHeight)
        }
        
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(barHeight)
        }
        
        addObserver()

    }
    
    private func playItem(atIndex idx: Int) {
        if idx >= 0 && idx < listPlayer.mediaList.count {
            if let media = listPlayer.mediaList.media(at: UInt(idx)) {
                listPlayer.play(media)
                url = files[idx].fileURL
                topBar.setTitle(url?.lastPathComponent, buttonState: false)
                index = idx
            }
        }
    }
    
    func play() {
        vlcPlayer.play()
        bottomBar.changePlayButtonState(true)
    }
    
    private func addObserver() {
        vlcPlayer.addObserver(self, forKeyPath: "time", options: .new, context: nil)
        vlcPlayer.addObserver(self, forKeyPath: "remainingTime", options: .new, context: nil)
    }

    
    // MARK: 显示工具条
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        timer.fireDate = Date(timeIntervalSinceNow: self.timeInterval)
        
        if isAnimating || isShowBar { return }
        
        view.bringSubviewToFront(topBar)
        topBar.isHidden = false
        view.bringSubviewToFront(bottomBar)
        bottomBar.isHidden = false
    
        topBar.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(-barHeight)
            make.height.equalTo(barHeight)
        }
        
        bottomBar.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(barHeight)
            make.bottom.equalTo(barHeight)
        }
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: showAnimationDuration, animations: {
            self.isAnimating = true
            self.topBar.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(0)
                make.height.equalTo(self.barHeight)
            }
            
            self.bottomBar.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(self.barHeight)
                make.bottom.equalTo(0)
            }
            self.view.layoutIfNeeded()
        }) { (_) in
            self.isAnimating = false
            self.isShowBar = true
            self.timer.fireDate = Date(timeIntervalSinceNow: self.timeInterval)
        }
        
    }
    
    // MARK: 隐藏工具条
    @objc private func autoHideBar() {
        if bottomBar.isInAction || pad.isInAction {
            return
        }
        topBar.isHidden = true
        bottomBar.isHidden = true
        if pad.superview != nil {
            pad.removeFromSuperview()
            topBar.setTitle(url?.lastPathComponent, buttonState: false)
        }
        isShowBar = false
    }
    
    // MARK: 快进
    @objc private func pan(_ gesture: UIPanGestureRecognizer) {
        if pad.superview != nil { return }
        if vlcPlayer.isPlaying && vlcPlayer.canPause {
            vlcPlayer.pause()
        }

        let deltaX = gesture.translation(in: view).x
        let ratio = CGFloat(mediaTime.intValue/1000)/SCREEN_WIDTH*deltaX/10.0
    
        if Int32(abs(ratio)) < 1 {
            vlcPlayer.play()
            return
        }
        
        if gesture.state == .ended {
            if ratio < 0 {
                vlcPlayer.jumpBackward(Int32(-ratio))
                ToastView.showToast("<<后退\(Int32(-ratio))s")
            } else if ratio > 0 {
                vlcPlayer.jumpForward(Int32(ratio))
                ToastView.showToast(">>快进\(Int32(ratio))s")
            }
            vlcPlayer.play()
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    
    deinit {
        vlcPlayer.removeObserver(self, forKeyPath: "time")
        vlcPlayer.removeObserver(self, forKeyPath: "remainingTime")
        vlcPlayer.drawable = nil
        if vlcPlayer.isPlaying {
            vlcPlayer.stop()
        }
        print("\(self.classForCoder) deinit")
    }
}


extension CustomVLCPlayerController: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        guard let player = aNotification.object as? VLCMediaPlayer else { return }
        if player.state == .ended {
//            print("---ended---")
            progress = 1
            bottomBar.update(currentTime: mediaTime.stringValue, totalTime: mediaTime.stringValue, sliderValue: progress)
            player.stop()
            bottomBar.changePlayButtonState(false)
            playItem(atIndex: index + 1)
        } else if player.state == .playing {
//            print("---playing---")
        } else if player.state == .buffering {
//            print("---buffering---")
            bottomBar.changePlayButtonState(true)
        } else if player.state == .opening {
//            print("---opening---")
        }
    }
    
    func mediaPlayerTitleChanged(_ aNotification: Notification) {
        
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        guard let player = aNotification.object as? VLCMediaPlayer else {
            return
        }
        
        progress = mediaTime.intValue > 0 ? Double(player.time.intValue)/Double(mediaTime.intValue) : 0
        bottomBar.update(currentTime: player.time.stringValue, totalTime: mediaTime.stringValue, sliderValue: progress)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let property = keyPath else { return }
        
        if property.elementsEqual("time") {

        } else if property.elementsEqual("remainingTime") {
            
        }
        
    }
}
