//
//  ToastView.swift
//  FreePlayer
//
//  Created by CXY on 2019/1/21.
//  Copyright © 2019 CXY. All rights reserved.
//

import UIKit

class ToastView: UIView {
    
    private var activityContentView: UIView = {
        let v = UIView()
        return v
    }()
    
    private var activityContentBG: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.init(white: 0, alpha: 0.6)
        v.layer.cornerRadius = 6
        return v
    }()
    
    private var activity: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView()
        return aiv
    }()
    
    private var isActivity: Bool {
        didSet {
            if self.isActivity {
                if !self.activity.isAnimating {
                    self.activity.startAnimating()
                }
            } else {
                if self.activity.isAnimating {
                    self.activity.stopAnimating()
                }
            }
        }
    }
    
    private var activityLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(type: .middle)
        l.textColor = UIColor.white
        l.textAlignment = .center
        l.numberOfLines = 3
        return l
    }()
    
    
    private var toastContentView: UIView = {
        let v = UIView()
        return v
    }()
    
    private var toastContentBG: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.init(white: 0, alpha: 0.6)
        v.layer.cornerRadius = 5
        return v
    }()
    
    private var toastLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(type: .middle)
        l.textColor = UIColor.white
        l.textAlignment = .center
        return l
    }()
    
    private static let shared = ToastView()
    private override init(frame: CGRect) {
        self.isActivity = false
        
        super.init(frame: frame)
        
        self.addActivityContentView()
    }
    
    private func addActivityContentView() {
        let maxWidth = SCREEN_WIDTH / 3.5
        
        self.addSubview(activityContentView)
        activityContentView.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.lessThanOrEqualTo(maxWidth)
        }
        
        activityContentView.addSubview(activityContentBG)
        activityContentBG.snp.makeConstraints { (maker) in
            maker.left.top.right.bottom.equalToSuperview()
        }
        
        activityContentView.addSubview(activity)
        activity.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(20)
            maker.centerX.equalToSuperview()
            maker.left.greaterThanOrEqualTo(34)
        }
        
        activityContentView.addSubview(activityLabel)
        activityLabel.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(20)
            maker.right.equalToSuperview().offset(-20)
            maker.top.equalTo(activity.snp.bottom).offset(20)
            maker.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func updateActivityLayout() {
        let label = activityLabel.text
        if label == nil || label!.isEmpty {
            activityLabel.snp.updateConstraints { (maker) in
                maker.left.equalToSuperview().offset(20)
                maker.right.equalToSuperview().offset(-20)
                maker.top.equalTo(activity.snp.bottom).offset(20)
                maker.bottom.equalToSuperview()
            }
        } else {
            activityLabel.snp.updateConstraints { (maker) in
                maker.left.equalToSuperview().offset(20)
                maker.right.equalToSuperview().offset(-20)
                maker.top.equalTo(activity.snp.bottom).offset(20)
                maker.bottom.equalToSuperview().offset(-20)
            }
        }
    }
    
    private func _showToast(_ toast: String, duration: TimeInterval = 2) {
        if UIApplication.shared.keyWindow != nil {
            self.toastFlags += 1
            
            if toastContentView.superview == nil {
                let maxWidth = SCREEN_WIDTH / 2
                
                UIApplication.shared.keyWindow!.addSubview(toastContentView)
                toastContentView.snp.makeConstraints { (maker) in
                    maker.center.equalToSuperview()
                    maker.width.lessThanOrEqualTo(maxWidth)
                }
            }
            
            if toastContentBG.superview == nil {
                toastContentView.addSubview(toastContentBG)
                toastContentBG.snp.makeConstraints { (maker) in
                    maker.left.top.right.bottom.equalToSuperview()
                }
                
                toastContentView.addSubview(toastLabel)
                toastLabel.snp.makeConstraints { (maker) in
                    maker.left.equalToSuperview().offset(10)
                    maker.right.equalToSuperview().offset(-10)
                    maker.top.equalToSuperview().offset(8)
                    maker.bottom.equalToSuperview().offset(-8)
                }
            }
            
            self.toastLabel.text = toast
            
            self.removeToastView(after: duration, flags: self.toastFlags)
        }
    }
    
    private var toastFlags: Int = 0
    private func removeToastView(after: TimeInterval = 2, flags: Int) {
        if after > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + after) {
                if flags == self.toastFlags {
                    self.removeToastView()
                }
            }
        }
    }
    private func removeToastView() {
        if self.toastContentView.superview != nil {
            self.toastContentView.removeFromSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func showToast(_ toast: String, duration: TimeInterval = 2) {
        ToastView.hideActivity()
        
        ToastView.shared._showToast(toast)
    }
    
    class func showActivity(label: String? = nil) {
        if UIApplication.shared.keyWindow != nil {
            ToastView.shared.removeToastView()
            
            if ToastView.shared.superview == nil {
                UIApplication.shared.keyWindow!.addSubview(ToastView.shared)
                ToastView.shared.snp.makeConstraints { (maker) in
                    maker.left.top.right.bottom.equalToSuperview()
                }
            }
            
            ToastView.shared.activityLabel.text = label
            ToastView.shared.isActivity = true
            
            ToastView.shared.updateActivityLayout()
        }
    }
    
    class func hideActivity() {
        if ToastView.shared.superview != nil {
            ToastView.shared.isActivity = false
            ToastView.shared.removeFromSuperview()
        }
    }

}
