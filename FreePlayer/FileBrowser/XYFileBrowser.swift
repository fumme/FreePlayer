//
//  XYFileBrowser.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/19.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

private struct Stack<T> {
    private var items = [T]()
    mutating func push(_ item: T) {
        items.append(item)
    }
    
    mutating func pop() -> T {
        return items.removeLast()
    }
    
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    var top: T? {
        return items.last
    }
    
    var secondTop: T? {
        if items.count < 2 {
            return nil
        }
        return items[items.count-2]
    }
}

private extension Stack {
    var filePath: String {
        var path = ""
        for item in items {
            if item is String {
                path = path.appendingFormat("/%@", item as! String)
            }
        }
        return path
    }
}

private class XYFileMonitor: NSObject {
    private var path = ""
    var changed: ((DispatchSource.FileSystemEvent)->Void)?
    
    func beginMonitoringFile(atPath path: String) {
        var fileDescriptor = open(path, O_EVTONLY)
        let defaultQueue = DispatchQueue.global()
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: DispatchSource.FileSystemEvent(rawValue: DispatchSource.FileSystemEvent.attrib.rawValue | DispatchSource.FileSystemEvent.delete.rawValue | DispatchSource.FileSystemEvent.extend.rawValue | DispatchSource.FileSystemEvent.link.rawValue | DispatchSource.FileSystemEvent.rename.rawValue | DispatchSource.FileSystemEvent.revoke.rawValue | DispatchSource.FileSystemEvent.write.rawValue), queue: defaultQueue)
        source.setEventHandler {
            let type = source.data
            print(type)
            self.changed?(type)
        }
        source.setCancelHandler {
            close(fileDescriptor)
            fileDescriptor = 0
        }
        source.resume()
    }
}


class XYFileBrowser: NSObject {
    static let shared = XYFileBrowser()
    private override init() {
      super.init()
    }
    
    private var stack = Stack<String>()
    private let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    private lazy var pwd = documentPath
    private lazy var monitors = Dictionary<String, XYFileMonitor>()
    
    enum FileBrowserViewMode {
        case list
        case collection
    }
    
    var viewMode = FileBrowserViewMode.list
    
    var isInRootDirectory: Bool {
        return stack.isEmpty
    }
    
    var workingDirectory: String {
        return stack.top ?? "/"
    }
    
    var backDirectory: String {
        let leftTitle = stack.secondTop ?? "/"
        if leftTitle.count > 10 {
            return (leftTitle as NSString).substring(to: 10)
        }
        return leftTitle
    }
    
    func contentsInCurrentDirectory(isVideo: Bool = false, searchFinished: @escaping ([XYFile])->Void) {
        DispatchQueue.global().async {
            let models = self.contentsInPath(self.pwd, isVideo: isVideo)
            DispatchQueue.main.async {
                searchFinished(models)
            }
        }
    }
    
    func moveIntoSubDirectory(_ dir: String) {
        assert(!dir.isEmpty, "parameter error!")
        stack.push(dir)
        pwd = documentPath.appending(stack.filePath)
        print(pwd)
    }
    
    func backToParentDirectory() {
        if !stack.isEmpty {
            let _ = stack.pop()
            pwd = documentPath.appending(stack.filePath)
        }
        
        print(pwd)
    }
    
    private func contentsInPath(_ path: String, isVideo: Bool = false) -> [XYFile] {
        let mgr = FileManager.default
        var fileModels = [XYFile]()
        do {
            let contents = try mgr.contentsOfDirectory(atPath: path)
//            print(contents)
            
            fileModels = contents.map { (file) -> XYFile in
                return XYFile(filePath: path.appendingFormat("/%@", file))
            }
        } catch {
            print(error)
        }
        if isVideo {
            fileModels = fileModels.filter { (file) -> Bool in
                return file.type.isVideo
            }
        }
        return fileModels
    }

}
