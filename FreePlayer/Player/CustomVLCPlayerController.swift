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
    
    private let listPlayer = VLCMediaListPlayer()
    
    private var files = [XYFile]()
    
    var vlcPlayer: VLCMediaPlayer {
        return listPlayer.mediaPlayer
    }
    
    private lazy var gesture: UIPanGestureRecognizer = {
        let ges = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        return ges
    }()
    
    fileprivate let barHeight = 44.0
    
    private var progress = 0.0
    
    private lazy var topBar: VLCTopBar = {
        let bar = VLCTopBar()
        bar.setTitle(url?.lastPathComponent, buttonState: false)
        bar.closeWindowAction = {[weak self] in
            self?.dismiss(animated: true, completion: nil)
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
            strongSelf.playListMenu.show()
            strongSelf.playListMenu.currentItem = strongSelf.url?.lastPathComponent
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
            if onOff {
                self?.vlcPlayer.play()
            } else {
                self?.vlcPlayer.pause()
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
            self?.vlcPlayer.rate = value
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
                strongSelf.playItem(atIndex: strongSelf.index)
                
            }
        }
        
        vlcPlayer.drawable = videoView
        vlcPlayer.delegate = self
        let rate = UserDefaults.standard.float(forKey: playRateKey)
        vlcPlayer.rate = rate > 1 ? rate : 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addGestureRecognizer(gesture)
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
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autoHideBar), object: nil)
        topBar.snp.updateConstraints { (make) in
            make.top.equalTo(-barHeight)
        }
        bottomBar.snp.updateConstraints { (make) in
            make.bottom.equalTo(barHeight)
        }
        view.bringSubviewToFront(topBar)
        topBar.isHidden = false
        view.bringSubviewToFront(bottomBar)
        bottomBar.isHidden = false
        
        UIView.animate(withDuration: showAnimationDuration, animations: {
            self.topBar.snp.updateConstraints { (make) in
                make.top.equalTo(0)
            }
            self.bottomBar.snp.updateConstraints { (make) in
                make.bottom.equalTo(0)
            }
        }) { (_) in
            self.perform(#selector(self.autoHideBar), with: nil, afterDelay: 5.0)
        }
        
    }
    
    // MARK: 隐藏工具条
    @objc private func autoHideBar() {
        if bottomBar.isInAction || pad.isInAction {
            perform(#selector(autoHideBar), with: nil, afterDelay: 5.0)
            return
        }
        topBar.isHidden = true
        bottomBar.isHidden = true
        if pad.superview != nil {
            pad.removeFromSuperview()
            topBar.setTitle(url?.lastPathComponent, buttonState: false)
        }
    }
    
    // MARK: 快进
    @objc private func pan(_ gesture: UIPanGestureRecognizer) {
        if pad.superview != nil { return }
        if vlcPlayer.isPlaying && vlcPlayer.canPause {
            vlcPlayer.pause()
        }

        let deltaX = gesture.translation(in: view).x
        let ratio = CGFloat(mediaTime.intValue/1000)/SCREEN_WIDTH*deltaX/60.0
    
//        print("deltax = \(deltaX), length = \(CGFloat(player.media.length.intValue/1000)), ratio = \(ratio)")
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
    }
}


extension CustomVLCPlayerController: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        if let player = aNotification.object as? VLCMediaPlayer, player.state == .ended {
            print("ended time = \(String(describing: player.time.stringValue))")
            progress = 1
            bottomBar.update(currentTime: mediaTime.stringValue, totalTime: mediaTime.stringValue, sliderValue: progress)
            player.stop()
            bottomBar.changePlayButtonState(false)
//            bottomBar.update(currentTime: "00:00", totalTime: mediaTime.stringValue, sliderValue: progress)
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
        guard let property = keyPath, let _ = change?[NSKeyValueChangeKey.newKey] as? VLCTime else {
            return
        }
        
        if property.elementsEqual("time") {
//            print("time = \(String(describing: vlctime.stringValue))")
//            bottomBar.update(currentTime: vlctime.stringValue, totalTime: mediaTime.stringValue, sliderValue: mediaTime.intValue > 0 ? Double(vlctime.intValue)/Double(mediaTime.intValue) : 0)
        } else if property.elementsEqual("remainingTime") {
            
        }
    }
}
