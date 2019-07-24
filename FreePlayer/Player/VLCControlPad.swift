//
//  VLCControlPad.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/27.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

let playRateKey = "playRateKey"

class VLCControlPad: UIView {
    
    var sliderValueChanged: ((Float)->Void)?
    
    private var inDraging = false
    
    var isInAction: Bool {
        return inDraging
    }
    
    var selectedRate: Float = 1.0 {
        didSet {
            rateTitleLabel.text = "播放速度\(String(format: "%.1f", selectedRate))x"
            rateSlider.setValue(selectedRate, animated: true)
            UserDefaults.standard.set(selectedRate, forKey: playRateKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(rateSlider)
        addSubview(rateTitleLabel)
        addSubview(resetBtn)
        backgroundColor = .darkGray
        layer.cornerRadius = 8
        layer.masksToBounds = true
        alpha = 0.9
        rateTitleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(10)
            make.height.equalTo(13)
        }
        rateSlider.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(rateTitleLabel.snp.bottom).offset(10)
            make.height.equalTo(20)
        }
        
        resetBtn.snp.makeConstraints { (make) in
            make.width.equalTo(50)
            make.height.equalTo(25)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-20)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        rateTitleLabel.text = "播放速度\(String(format: "%.1f", slider.value))x"
        selectedRate = slider.value
        sliderValueChanged?(slider.value)
    }
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
            
                inDraging = true
                
            case .moved:
                sliderValueChanged(rateSlider)
                inDraging = true
                
            case .ended:
            
                inDraging = false
                
            default:
                break
            }
        }
    }
    @objc private func resetRate() {
        rateSlider.value = 1
        sliderValueChanged(rateSlider)
    }

    private lazy var rateTitleLabel: UILabel = {
        let lb = UILabel()
        lb.textAlignment = .center
        lb.font = UIFont.systemFont(ofSize: 12)
        lb.textColor = .white
        lb.text = "播放速度1.0x"
        return lb
    }()
    
    private lazy var rateSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.5
        slider.maximumValue = 2.0
        slider.value = 1.0
        slider.backgroundColor = .darkGray
        slider.minimumTrackTintColor = .red
        slider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        return slider
    }()
    
    private lazy var resetBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("重置", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.addTarget(self, action: #selector(resetRate), for: .touchUpInside)
        return btn
    }()
    
}
