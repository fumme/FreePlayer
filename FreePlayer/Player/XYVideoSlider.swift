//
//  JMVideoSlider.swift
//  Jimu2.0
//
//  Created by CXY on 2018/10/22.
//  Copyright © 2018年 ubt. All rights reserved.
//

import UIKit


class XYVideoSlider: UIView {
    var value = 0.0 {
        didSet {
            valueChangedClosure?(self)
            panDistance = CGFloat((viewWidth-sliderDiameter)*value)
            setProgress(value, layer: progressLayer, animated: false)
            updateSlideFrame()
        }
    }
    
    var middleValue = 0.0 {
        didSet {
            setProgress(middleValue, layer: cacheLayer)
        }
    }
    
    var finishedClosure: ((XYVideoSlider)->Void)?
    var valueChangedClosure: ((XYVideoSlider)->Void)?
    var draggingSliderClosure: ((XYVideoSlider)->Void)?
    
    // 游标直径
    fileprivate let sliderDiameter = 15.0
    
    var bgColor = UIColor.darkGray {
        didSet {
            bgLayer.strokeColor = bgColor.cgColor
            bgLayer.setNeedsDisplay()
        }
    }
    
    fileprivate let cacheColor = UIColor.lightGray
    
    var progressColor = UIColor.green {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
            progressLayer.setNeedsDisplay()
//            slider.borderColor = progressColor.cgColor
//            slider.setNeedsDisplay()
        }
    }
    
    var sliderColor = UIColor.lightGray {
        didSet {
            slider.strokeColor = sliderColor.cgColor
            slider.setNeedsDisplay()
        }
    }
    
    fileprivate let lineWidth = 10.0
    
    fileprivate var panDistance = CGFloat(0.0)
    
    fileprivate var centerY: Double {
        return Double(bounds.size.height/2.0)
    }
    
    fileprivate var viewWidth: Double {
        return Double(bounds.size.width)
    }
    
    fileprivate var viewHeight: Double {
        return Double(bounds.size.height)
    }
    
    fileprivate lazy var bgLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = CAShapeLayerLineCap.round
        layer.strokeColor = bgColor.cgColor
        layer.lineWidth = CGFloat(lineWidth)
        layer.opacity = 0.8
        layer.strokeEnd = 1
        return layer
    }()
    
    fileprivate lazy var cacheLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = CAShapeLayerLineCap.round
        layer.strokeColor = cacheColor.cgColor
        layer.opacity = 1
        layer.lineWidth = CGFloat(lineWidth)
        layer.strokeEnd = 0
        return layer
    }()
    
    fileprivate lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = CAShapeLayerLineCap.round
        layer.strokeColor = progressColor.cgColor
        layer.opacity = 1
        layer.lineWidth = CGFloat(lineWidth)
        layer.strokeEnd = 0
        return layer
    }()
    
    fileprivate lazy var slider: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.cornerRadius = CGFloat(sliderDiameter/2)
        layer.borderColor = sliderColor.cgColor
        layer.borderWidth = 7.0
        layer.backgroundColor = UIColor.white.cgColor
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(pan)
        addGestureRecognizer(tap)
        tap.require(toFail: pan)
        
        layer.addSublayer(bgLayer)
        layer.addSublayer(cacheLayer)
        layer.addSublayer(progressLayer)
        layer.addSublayer(slider)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayers()
    }
    
    @objc fileprivate func handlePan(_ ges: UIPanGestureRecognizer) {
        let deltaX = ges.translation(in: self).x
        panDistance += deltaX
        panDistance = max(0, panDistance)
        panDistance = min(panDistance, CGFloat(viewWidth-sliderDiameter))
        ges.setTranslation(.zero, in: self)
        value = Double(panDistance)/(viewWidth-sliderDiameter)
        if ges.state == .ended {
            finishedClosure?(self)
        } else if ges.state == .changed || ges.state == .began {
            draggingSliderClosure?(self)
        }
    }
    
    @objc fileprivate func handleTap(_ ges: UITapGestureRecognizer) {
        let loc = ges.location(in: self)
        panDistance = loc.x
        panDistance = max(0, panDistance)
        panDistance = min(panDistance, CGFloat(viewWidth-sliderDiameter))
        value = Double(panDistance)/(viewWidth-sliderDiameter)
        finishedClosure?(self)
    }
    
    
    fileprivate func setProgress(_ precent: Double, layer: CAShapeLayer, animated: Bool = false) {
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
    
    fileprivate func updateSlideFrame() {
        let vue = ceil((viewWidth-sliderDiameter)*value)
        UIView.animate(withDuration: 0.1) {
            self.slider.frame = CGRect(x: vue, y: (self.viewHeight-self.sliderDiameter)/2, width: self.sliderDiameter, height: self.sliderDiameter)
        }
    }
    
    fileprivate func updateLayers() {
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
        
        progressLayer.frame = bounds
        let progressLayerPath = CGMutablePath()
        progressLayerPath.move(to: CGPoint(x: orginX, y: centY))
        progressLayerPath.addLine(to: CGPoint(x: desX, y: centY))
        progressLayer.path = progressLayerPath
        
        let vue = ceil((viewWidth-sliderDiameter)*value)
        slider.frame = CGRect(x: vue, y: (viewHeight-sliderDiameter)/2, width: sliderDiameter, height: sliderDiameter)
    }

}
