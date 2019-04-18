//
//  XYFile.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/19.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

public enum XYFileType: String {
    /// Directory
    case Directory = "directory"
    
    /// GIF file
    case GIF = "gif"
    /// JPG file
    case JPG = "jpg"
    
    /// PNG file
    case PNG = "png"
    
    /// PLIST file
    case JSON = "json"
    /// PDF file
    case PDF = "pdf"
    /// PLIST file
    case PLIST = "plist"
    
    case TXT = "txt"
    
    case JS = "js"
    
    case XML = "xml"
    
    case WORD = "doc"
    
    case WORDS = "docx"
    
    case PPT = "ppt"
    
    case EXCEL = "xls"
    
    
    /// ZIP file
    case ZIP = "zip"
    
    case RAR = "rar"
    
    /// Audio file
    case MP3 = "mp3"
    
    /// Video file
    case MP4 = "mp4"
    case AVI = "avi"
    case WMV = "wmv"
    case MPEG = "mpeg"
    case MOV = "mov"
    
    /// default file
    case Default = "unknown"
    
    /**
     Get representative image for file type
     
     - returns: UIImage for file type
     */
    public func image() -> UIImage? {
        let bundle =  Bundle(path: Bundle.main.path(forResource: "FileBrowser.bundle", ofType: nil)!)
        var fileName = ""
//        var type = ""
//        switch self {
//            case .Directory: fileName = "folder@2x.png"
//            case .JPG, .PNG, .GIF: fileName = "image@2x.png"
//            case .PDF: fileName = "pdf@2x.png"
//            case .ZIP: fileName = "zip@2x.png"
//            default: fileName = "file@2x.png"
//        }
        fileName = "file_type_".appending(rawValue)
        let file = UIImage(named: fileName, in: bundle, compatibleWith: nil)
        return file ?? XYFileType.Default.image()
    }
    
    var isVideo: Bool {
        return [XYFileType.MP4, XYFileType.AVI, XYFileType.WMV, XYFileType.MPEG, XYFileType.MOV].contains(self)
    }
}


class XYFile: NSObject {
    
    var displayName = ""
    
    var isDirectory = false
    
    var fileExtension: String?
    
    var fileAttributes: NSDictionary? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: filePath) as NSDictionary
            return attributes
        } catch {
            
        }
        return nil
    }
    
    var filePath = ""
    
    var fileURL: URL {
        return URL(fileURLWithPath: filePath)
    }
    
    var type = XYFileType.Default
    
    var isImage: Bool {
        return fileURL.isImage
    }
    
    var isVideo: Bool {
        return fileURL.isVideo
    }
    
    var isText: Bool {
        return fileURL.isText
    }
    
    var isDocument: Bool {
        return fileURL.isDoc
    }
    
    var hasThumbnail: Bool {
        var ret = false
        switch type {
            case .JPG, .PNG, .GIF, .PDF: ret = true
            default: ret = false
        }
        if isVideo || isImage || isDocument {
            ret = true
        }
        return ret
    }
    
    // 目录下文件数
    var directoryContentsCount: Int {
        if isDirectory {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: filePath)
                return contents.count
            } catch {
                print(error.localizedDescription)
            }
        }
        return 0
    }
    
    // 文件字节数
    var fileSize: String {
        if !isDirectory {
            if let size = fileAttributes?.fileSize() {
                return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            }
        }
        return ""
    }
    
    
    func delete(finished: ((Bool)->Void)? = nil) {
        DispatchQueue.global().async {
            do {
                try FileManager.default.removeItem(at: self.fileURL)
                DispatchQueue.main.async {
                    finished?(true)
                }
            } catch {
                print("An error occured when trying to delete file:\(self.filePath) Error:\(error)")
                DispatchQueue.main.async {
                    finished?(false)
                }
            }
            
        }
        
    }

    init(filePath: String) {
        super.init()
        self.filePath = filePath
        let isDirectory = checkIsDirectory(filePath)
        self.isDirectory = isDirectory
        if self.isDirectory {
            self.fileExtension = nil
            self.type = .Directory
        } else {
            fileExtension = fileURL.pathExtension
            if let fileExtension = fileExtension {
                self.type = XYFileType(rawValue: fileExtension) ?? .Default
            }
        }
        self.displayName = fileURL.lastPathComponent
    }
}



