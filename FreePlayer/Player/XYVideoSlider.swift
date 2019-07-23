//
//  JMVideoSlider.swift
//  Jimu2.0
//
//  Created by CXY on 2018/10/22.
//  Copyright © 2018年 cxy. All rights reserved.
//

import UIKit

private class XYSlider: UISlider {
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.trackRect(forBounds: bounds)
        let height: CGFloat = 10.0
        return CGRect(x: rect.origin.x, y: (bounds.size.height-height)/2, width: rect.size.width, height: height)
    }
}


class XYVideoSlider: UIView {
    
    var bgColor = UIColor.darkGray {
        didSet {
            bgLayer.strokeColor = bgColor.cgColor
        }
    }
    
    var sliderColor = UIColor.clear {
        didSet {
            slider.backgroundColor = sliderColor
        }
    }
    
    var progressColor = UIColor.green {
        didSet {
            slider.minimumTrackTintColor = progressColor
        }
    }
    
    var middleValue = 0.0 {
        didSet {
            setProgress(middleValue, layer: cacheLayer)
        }
    }
    
    var value: Double {
        set {
            slider.value = Float(newValue)
        }
        get {
            return Double(slider.value)
        }
    }
    
    var startPan: ((XYVideoSlider)->Void)?
    
    var paning: ((XYVideoSlider)->Void)?
    
    var endedPan: ((XYVideoSlider)->Void)?

    private let cacheColor = UIColor.lightGray

    // 游标直径
    private let sliderDiameter = 25.0
    
    private let lineWidth = 10.0
    
    private var panDistance = CGFloat(0.0)
    
    private var centerY: Double {
        return Double(bounds.size.height/2.0)
    }
    
    private var viewWidth: Double {
        return Double(bounds.size.width)
    }
    
    private var viewHeight: Double {
        return Double(bounds.size.height)
    }
    
    private lazy var bgLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = CAShapeLayerLineCap.round
        layer.strokeColor = bgColor.cgColor
        layer.lineWidth = CGFloat(lineWidth)
        layer.opacity = 0.8
        layer.strokeEnd = 1
        return layer
    }()
    
    private lazy var cacheLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = CAShapeLayerLineCap.round
        layer.strokeColor = cacheColor.cgColor
        layer.opacity = 1
        layer.lineWidth = CGFloat(lineWidth)
        layer.strokeEnd = 0
        return layer
    }()
    
    private lazy var slider: XYSlider = {
        let slider = XYSlider()
        slider.setThumbImage(#imageLiteral(resourceName: "slider_sound"), for: .normal)
        slider.backgroundColor = .clear
        slider.maximumTrackTintColor = .clear
        slider.addTarget(self, action: #selector(touchDown(_:)), for: .touchDown)
        slider.addTarget(self, action: #selector(dragging(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        return slider
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(bgLayer)
        layer.addSublayer(cacheLayer)
        
        addSubview(slider)
        slider.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(sliderDiameter)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc private func touchDown(_ slider: UISlider) {
        startPan?(self)
    }
    
    @objc private func dragging(_ slider: UISlider) {
        paning?(self)
    }
    
    @objc private func touchUpInside(_ slider: UISlider) {
        endedPan?(self)
    }

    private func setProgress(_ precent: Double, layer: CAShapeLayer, animated: Bool = false) {
        if precent < 0 || precent > 1 {
            return
        }
        if animated {
            CATransaction.begin()
            CATransaction.setDisableActions(!animated)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear))
            CATransaction.setAnimationDuration(0.1)
            layer.strokeEnd = CGFloat(precent)
            CATransaction.commit()
        } else {
            layer.strokeEnd = CGFloat(precent)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayers()
    }
    
    private func updateLayers() {
        if let supView = superview, supView.isHidden {
            return
        }
        let orginX = lineWidth/2
        let desX = viewWidth-lineWidth/2
        let centY = self.centerY
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: orginX, y: centY))
        path.addLine(to: CGPoint(x: desX, y: centY))
        bgLayer.frame = bounds
        bgLayer.path = path
        
        cacheLayer.frame = bounds
        let cacheLayerPath = CGMutablePath()
        cacheLayerPath.move(to: CGPoint(x: orginX, y: centY))
        cacheLayerPath.addLine(to: CGPoint(x: desX, y: centY))
        cacheLayer.path = cacheLayerPath

    }

}
