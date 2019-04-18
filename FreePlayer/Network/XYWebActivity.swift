//
//  XYWebActivity.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/22.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class XYWebActivity: UIActivity {
    var URLToOpen: URL?
    var schemePrefix: String?
    
    override var activityType : UIActivity.ActivityType? {
        let typeArray = "\(type(of: self))".components(separatedBy: ".")
        let _type: String = typeArray[typeArray.count-1]
        return UIActivity.ActivityType(rawValue: _type)
    }
    
    override var activityImage : UIImage {
        if let type = activityType?.rawValue {
            return XYWebBrowserController.bundledImage(named: "\(type)")!
        }
        else{
            assert(false, "Unknow type")
            return UIImage()
        }
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for activityItem in activityItems {
            if activityItem is URL {
                URLToOpen = activityItem as? URL
            }
        }
    }
}
