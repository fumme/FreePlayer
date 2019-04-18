//
//  XYChromeWebActivity.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/22.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class XYChromeWebActivity: XYWebActivity {
    override var activityTitle : String {
        return NSLocalizedString("Open in Chrome", tableName: "SwiftWebVC", comment: "")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for activityItem in activityItems {
            if activityItem is URL, UIApplication.shared.canOpenURL(URL(string: "googlechrome://")!) {
                return true;
            }
        }
        return false;
    }
    
    override func perform() {
        guard let inputURL = URLToOpen, let scheme = inputURL.scheme else {
            return
        }
        
        // Replace the URL Scheme with the Chrome equivalent.
        var chromeScheme: String? = nil;
        if scheme == "http" {
            chromeScheme = "googlechrome"
        } else if scheme == "https" {
            chromeScheme = "googlechromes"
        }
        
        // Proceed only if a valid Google Chrome URI Scheme is available.
        if chromeScheme != nil {
            let absoluteString = inputURL.absoluteString as NSString
            let rangeForScheme = absoluteString.range(of: ":")
            let urlNoScheme: String! = absoluteString.substring(from: rangeForScheme.location)
            let chromeURLString: String! = chromeScheme!+urlNoScheme
            let chromeURL: URL! = URL(string: chromeURLString)
            
            // Open the URL with Chrome.
            UIApplication.shared.openURL(chromeURL)
        }
    }
}
