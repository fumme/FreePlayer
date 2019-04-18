//
//  XYSafariWebActivity.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/22.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class XYSafariWebActivity: XYWebActivity {
    override var activityTitle : String {
        return NSLocalizedString("Open in Safari", tableName: "SwiftWebVC", comment: "")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for activityItem in activityItems {
            if let activityItem = activityItem as? URL, UIApplication.shared.canOpenURL(activityItem) {
                return true
            }
        }
        return false
    }
    
    override func perform() {
        let completed: Bool = UIApplication.shared.openURL(URLToOpen! as URL)
        activityDidFinish(completed)
    }
}
