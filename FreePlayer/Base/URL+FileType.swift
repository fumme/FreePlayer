//
//  URL+FileType.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/25.
//  Copyright © 2019年 cxy. All rights reserved.
//

import MobileCoreServices

extension URL {
    var fileUTType: CFString? {
        let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)
        return unmanagedFileUTI?.takeRetainedValue()
    }
    
    var isVideo: Bool {
        guard let fileUTI = fileUTType else { return false }
        return UTTypeConformsTo(fileUTI, kUTTypeMovie) || UTTypeConformsTo(fileUTI, kUTTypeVideo) || UTTypeConformsTo(fileUTI, kUTTypeQuickTimeMovie) || UTTypeConformsTo(fileUTI, kUTTypeMPEG) || UTTypeConformsTo(fileUTI, kUTTypeMPEG2Video) || UTTypeConformsTo(fileUTI, kUTTypeMPEG2TransportStream) || UTTypeConformsTo(fileUTI, kUTTypeMPEG4) || UTTypeConformsTo(fileUTI, kUTTypeAppleProtectedMPEG4Video) || UTTypeConformsTo(fileUTI, kUTTypeAVIMovie)
    }
    
    var isImage: Bool {
        guard let fileUTI = fileUTType else { return false }
        return UTTypeConformsTo(fileUTI, kUTTypeImage)
    }
    
    var isText: Bool {
        guard let fileUTI = fileUTType else { return false }
        return UTTypeConformsTo(fileUTI, kUTTypeText)
    }
    
    var isDoc: Bool {
        guard let fileUTI = fileUTType else { return false }
        return UTTypeConformsTo(fileUTI, kUTTypeRTF)
    }
}
