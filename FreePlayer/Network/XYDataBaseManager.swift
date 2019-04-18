//
//  XYDataBaseManager.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/22.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit
import CoreData

class XYDataBaseManager: NSObject {
    
    static let `default` = XYDataBaseManager()
    override init() {
        super.init()
    }
    
    // 私有队列的MOC和主队列的MOC，在执行save操作时，都应该调用performBlock:方法，在自己的队列中执行save操作。
    // 私有队列的MOC执行完自己的save操作后，还调用了主队列MOC的save方法，来完成真正的持久化操作，否则不能持久化到本地
    // MARK:保存数据
    private func saveContext(_ finished: @escaping (Error?)->Void) {
            bgContext.perform {
                do {
                    try self.bgContext.save()
                    self.mainContext.perform({
                        do {
                            try self.mainContext.save()
                            finished(nil)
                        } catch {
                            print(error)
                            finished(error)
                        }
                    })
                } catch {
                    print(error)
                    DispatchQueue.main.async {
                        finished(error)
                    }
                }
            }
    }
    
    // MARK:增加数据
    func savePlayUrl(link: String, finished: ((Error?)->Void)? = nil) {
        bgContext.perform {
            let playUrl = NSEntityDescription.insertNewObject(forEntityName: XYConst.coreDataEntityName, into: self.bgContext) as! XYPlayUrl
            playUrl.link = link
            self.saveContext({ (error) in
                finished?(error)
            })
        }
    }
    
    // MARK:获取所有数据
    func getAllRecords(_ finished: @escaping (([XYPlayUrl]?)->Void))  {
        bgContext.perform {
            let fetchRequest: NSFetchRequest = XYPlayUrl.fetchRequest()
            do {
                let result = try self.bgContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    finished(result)
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    finished(nil)
                }
            }
        }
        
    }
    
    // MARK:条件查询数据
    func getPlayURL(link: String, finished: @escaping ([XYPlayUrl]?)->Void) {
        bgContext.perform {
            let fetchRequest: NSFetchRequest = XYPlayUrl.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "link == %@", link)
            do {
                let result: [XYPlayUrl] = try self.bgContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    finished(result)
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    finished(nil)
                }
            }
        }
    }
    
    func isPlayURLExist(_ link: String, finished: @escaping (Bool)->Void) {
        getPlayURL(link: link) { (ret) in
            if let urls = ret, !urls.isEmpty {
                finished(true)
            } else {
                finished(false)
            }
        }
    }
    
    // MARK:修改指定数据
    func changePlayURLWith(link: String, newLink: String, finished: @escaping (Error?)->Void) {
        
        bgContext.perform {
            let fetchRequest: NSFetchRequest = XYPlayUrl.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "link == %@", link)
            do {
                // 拿到符合条件的所有数据
                let result = try self.bgContext.fetch(fetchRequest)
                for item in result {
                    // 循环修改
                    item.link = newLink
                }
            } catch {
                DispatchQueue.main.async {
                    finished(error)
                }
                return
            }
            self.saveContext({ (err) in
                finished(err)
            })
        }
    }
    
    
    // MARK: 删除指定数据
    func delete(link: String, finished: @escaping (Error?)->Void) {
        bgContext.perform {
            let fetchRequest: NSFetchRequest = XYPlayUrl.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "link == %@", link)
            do {
                let result = try self.bgContext.fetch(fetchRequest)
                for item in result {
                    self.bgContext.delete(item)
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    finished(error)
                }
                return
            }
            self.saveContext({ (error) in
                finished(error)
            })
        }
        
    }
    
    //MARK: 删除所有数据
    func deleteAllRecords(_ finished: @escaping (Error?)->Void) {
        // 这里直接调用上面获取所有数据的方法
        getAllRecords { (ret) in
            if let result = ret {
                // 循环删除所有数据
                for item in result {
                    self.bgContext.delete(item)
                }
                self.saveContext({ (error) in
                    finished(error)
                })
            }
        }
    }
    
    
    // MARK:Lazy load
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: XYConst.coreDataMomdName, withExtension: nil)!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        return managedObjectModel
    }()
    
    // 持久化存储协调器
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let fileManager = FileManager.default
        var url = XYConst.dbCacheURL.appendingPathComponent(XYConst.dataBaseDirectoryName)
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("persistentStoreCoordinator error!")
            }
        }
        let sqliteURL = url.appendingPathComponent(XYConst.dbFileName)
        
        let options = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
        
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: sqliteURL, options: options)
            
        } catch {
            var dict = [String: Any]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as Any?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as Any?
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 6666, userInfo: dict)
            print("Unresolved error (wrappedError), (wrappedError.userInfo)")
            abort()
        }
        return persistentStoreCoordinator
    }()
    
    // 私有队列MOC，用于执行其他耗时操作
    lazy var bgContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = mainContext
        return context
    }()
    
    // 主队列MOC，用于执行UI操作
    lazy var mainContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        return context
    }()

}
