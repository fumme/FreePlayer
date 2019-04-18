//
//  XYUtils.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/20.
//  Copyright © 2019年 cxy. All rights reserved.
//


func checkIsDirectory(_ filePath: String) -> Bool {
    var isDir: ObjCBool = false
    FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir)
    return isDir.boolValue
}


