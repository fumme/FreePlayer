//
//  UIFont+Type.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/25.
//  Copyright © 2019年 cxy. All rights reserved.
//


enum FontType {
    case smaller
    case small
    case middle
    case large
    case title
    case title2
}

extension UIFont {
    class func systemFont(type: FontType) -> UIFont {
        var size: CGFloat = 10
        
        switch type {
        case .smaller:
            if Device_Type == .iPhone4 || Device_Type == .iPhone5 {
                size = 10
            } else if IS_iPad {
                size = 14
            } else {
                size = 12
            }
        case .small:
            if Device_Type == .iPhone4 || Device_Type == .iPhone5 {
                size = 12
            } else if IS_iPad {
                size = 17
            } else {
                size = 14
            }
        case .middle:
            if Device_Type == .iPhone4 || Device_Type == .iPhone5 {
                size = 14
            } else if IS_iPad {
                size = 19
            } else {
                size = 16
            }
        case .large:
            if Device_Type == .iPhone4 || Device_Type == .iPhone5 {
                size = 16
            } else if IS_iPad {
                size = 24
            } else {
                size = 18
            }
        case .title:
            if Device_Type == .iPhone4 || Device_Type == .iPhone5 {
                size = 18
            } else if IS_iPad {
                size = 30
            } else {
                size = 22
            }
        case .title2:
            if Device_Type == .iPhone4 || Device_Type == .iPhone5 {
                size = 17
            } else if IS_iPad {
                size = 27
            } else {
                size = 20
            }
        }
        
        return UIFont.systemFont(ofSize: size)
    }
}
