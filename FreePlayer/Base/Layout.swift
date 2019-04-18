//
//  Layout.swift
//  Jimu2.0
//
//  Created by 郭峰 on 2018/6/14.
//  Copyright © 2018年 ubt. All rights reserved.
//

import UIKit

let SCREEN_SCALE = UIScreen.main.scale
let SCREEN_WIDTH = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
let SCREEN_HEIGHT = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
let SCREEN_BOUNDS = UIScreen.main.bounds



enum Device {
    case iPhone4            /// 4/4s          320*480  @2x
    case iPhone5            /// 5/5C/5S/SE    320*568  @2x
    case iPhone6            /// 6/6S/7/8      375*667  @2x
    case iPhone6p           /// 6P/6SP/7P/8P  414*736  @3x
    case iPhoneX            /// X/XS          375*812  @3x
    case iPhoneX_Max        /// XS Max        414*896  @3x
    case iPhoneXR           /// XR            414*896  @2x
    case iPad_768_1024      /// iPad(5th generation)/iPad Air/iPad Air2/iPad pro(9.7)  768*1024  @2x
    case iPad_834_1112      /// iPad pro(10.5)  834*1112   @2x
    case iPad_1024_1366     /// iPad pro(12.9)  1024*1366  @2x
    
    static func type() -> Device {
        
        switch SCREEN_WIDTH {
        case 480.0:
            return .iPhone4
        case 568.0:
            return .iPhone5
        case 667.0:
            return .iPhone6
        case 736.0:
            return .iPhone6p
        case 812.0:
            return .iPhoneX
        case 896.0:
            if SCREEN_SCALE == 3 {
                return .iPhoneX_Max
            } else {
                return .iPhoneXR
            }
        case 1024.0:
            return .iPad_768_1024
        case 1112.0:
            return .iPad_834_1112
        case 1366.0:
            return .iPad_1024_1366
        default:
            return .iPad_768_1024
        }
    }
    
    static var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.delegate?.window??.safeAreaInsets ?? .zero
        }
        return .zero
    }
    
    static var safeScreenWidth: CGFloat {
        return UIScreen.main.bounds.width-safeAreaInsets.left-safeAreaInsets.right
    }
    
    static var safeScreenHeight: CGFloat {
        return UIScreen.main.bounds.height-safeAreaInsets.top-safeAreaInsets.bottom
    }
    
}


struct JMLayout {
    var isFromLeft: Bool = true
    var left: CGFloat = 0
    var right: CGFloat = 0
    var isFromTop: Bool = true
    var top: CGFloat = 0
    var bottom: CGFloat = 0
    var width: CGFloat = 0
    var height: CGFloat = 0
    var zPosition: CGFloat = 0
    
    init(isFromLeft: Bool = true, left: CGFloat = 0, right: CGFloat = 0, isFromTop: Bool = true, top: CGFloat = 0, bottom: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0, zPosition: CGFloat = 0) {
        self.isFromLeft = isFromLeft
        self.left = left
        self.right = right
        self.isFromTop = isFromTop
        self.top = top
        self.bottom = bottom
        self.width = width
        self.height = height
        self.zPosition = zPosition
    }
}


let Device_Type = Device.type()

let IS_iPad = (UI_USER_INTERFACE_IDIOM() == .pad)
let IS_iPhoneX = (Device_Type == .iPhoneX || Device_Type == .iPhoneX_Max || Device_Type == .iPhoneXR)
fileprivate var _is_iPhone6_flags = -1
fileprivate var _is_iPhone6 = true
var IS_iPhone6: Bool {
    if _is_iPhone6_flags == -1 {
        if !IS_iPad && !IS_iPhoneX {
            _is_iPhone6_flags = 1
        } else {
            _is_iPhone6_flags = 0
            _is_iPhone6 = false
        }
    }
    return _is_iPhone6
}

let Width_Scale_iPhone6 = SCREEN_WIDTH / 667.0
let Width_Scale_iPhoneX = SCREEN_WIDTH / 812.0
let Width_Scale_iPad = SCREEN_WIDTH / 1024.0

let Height_Scale_iPhone6 = SCREEN_HEIGHT / 375.0
let Height_Scale_iPhoneX = SCREEN_HEIGHT / 375.0
let Height_Scale_iPad = SCREEN_HEIGHT / 768.0

func HorizontalPixel(_ iPhone6: CGFloat, iPhoneX: CGFloat = 0, iPad: CGFloat = 0) -> CGFloat {
    if IS_iPhone6 {
        return iPhone6 * Width_Scale_iPhone6
    } else if IS_iPhoneX {
        if iPhoneX == 0 {
            return iPhone6 * Width_Scale_iPhoneX
        } else {
            return iPhoneX * Width_Scale_iPhoneX
        }
    } else {
        if iPad == 0 {
            return iPhone6 * Width_Scale_iPad
        } else {
            return iPad * Width_Scale_iPad
        }
    }
}

func VerticalPixel(_ iPhone6: CGFloat, iPhoneX: CGFloat = 0, iPad: CGFloat = 0) -> CGFloat {
    if IS_iPhone6 {
        return iPhone6 * Height_Scale_iPhone6
    } else if IS_iPhoneX {
        if iPhoneX == 0 {
            return iPhone6 * Height_Scale_iPhoneX
        } else {
            return iPhoneX * Height_Scale_iPhoneX
        }
    } else {
        if iPad == 0 {
            return iPhone6 * Height_Scale_iPad
        } else {
            return iPad * Height_Scale_iPad
        }
    }
}

