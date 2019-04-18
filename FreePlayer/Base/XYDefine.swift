//
//  XYDefine.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/21.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

public struct XYConst {
    static let commonBgColor = UIColor(red: 49, green: 194, blue: 124, alpha: 1)
    static let coreDataEntityName = "XYPlayUrl"
    static let coreDataMomdName = coreDataEntityName.appending(".momd")
    static let documentURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
    static let dbCacheURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
    static let documentPath = documentURL.path
    static let dataBaseDirectoryName = "QVPlayerDB"
    static let dbFileName = "list.sqlite"
    static let commonLightWhiteColor = UIColor(hex: 0xf2f2f2)
}
