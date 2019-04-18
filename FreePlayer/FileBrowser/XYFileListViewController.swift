//
//  ViewController.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/19.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit
import AVKit
import MobilePlayer
import Kingfisher
import MJRefresh

class XYFileListViewController: BaseViewController {
    
    @IBOutlet weak var listView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.addTarget(self, action: #selector(back), for: .touchUpInside)
        btn.setImage(UIImage(named: ""), for: .normal)
        return btn
    }()
    
    private lazy var viewStyleButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(changeViewStyle(_:)), for: .touchUpInside)
        btn.setImage(UIImage(named: "view_as_list"), for: .normal)
        btn.setImage(UIImage(named: "view_as_collection"), for: .selected)
        return btn
    }()
    
    private lazy var segmentController: UISegmentedControl = {
        let filterSegmentedControl = UISegmentedControl(items: ["名称", "种类"])
        filterSegmentedControl.apportionsSegmentWidthsByContent = false
        filterSegmentedControl.frame = CGRect(x: 0, y: 0, width: 80, height: 20)
        filterSegmentedControl.selectedSegmentIndex = 0
        filterSegmentedControl.addTarget(self, action: #selector(filterChanged(_:)), for: .valueChanged)
        return filterSegmentedControl
    }()
    
    private lazy var listRefreshHeader: MJRefreshNormalHeader? = {
        let header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadContent()
        })
        return header
    }()
    
    private lazy var collectionRefreshHeader: MJRefreshNormalHeader? = {
        let header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadContent()
        })
        return header
    }()
    
    private lazy var tipView: UIView = {
        let view = UIView()
        let tipLb = UILabel()
        tipLb.text = "暂无文件哟！\n 请使用iTunes或WiFi添加文件！"
        tipLb.font = UIFont.systemFont(ofSize: 18)
        tipLb.numberOfLines = 0
        tipLb.textAlignment = .center
        tipLb.frame = CGRect(x: 0, y: 150, width: UIScreen.main.bounds.size.width, height: 100)
        view.frame = CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        view.addSubview(tipLb)
        return view
    }()
    
    private lazy var fileModels = [XYFile]()
    
    private var currentFile: XYFile?
    
    private lazy var previewManager = XYPreviewManager()

    
    private let cellSpacing: CGFloat = 8
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewStyleButton.isSelected = XYFileBrowser.shared.viewMode == .collection
        listView.isHidden = viewStyleButton.isSelected
        collectionView.isHidden = !viewStyleButton.isSelected
        loadContent()
    }
    
    private func setupSubViews() {
        listView.register(UINib(nibName: XYFileListCell.cellID, bundle: nil), forCellReuseIdentifier: XYFileListCell.cellID)
        listView.tableFooterView = UIView()
        listView.backgroundColor = XYConst.commonLightWhiteColor
        listView.rowHeight = XYFileListCell.cellHeight
        listView.mj_header = listRefreshHeader
        
        collectionView.register(UINib(nibName: XYFileCollectionCell.cellReuseID, bundle: nil), forCellWithReuseIdentifier: XYFileCollectionCell.cellReuseID)
        collectionView.backgroundColor = XYConst.commonLightWhiteColor
        collectionView.mj_header = collectionRefreshHeader
        
        if !XYFileBrowser.shared.isInRootDirectory {
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: viewStyleButton)
        navigationItem.titleView = segmentController
        backButton.setTitle("< "+XYFileBrowser.shared.backDirectory, for: .normal)
    }
    
    private func loadContent() {
        XYFileBrowser.shared.contentsInCurrentDirectory { [weak self](files) in
            guard let strongSelf = self else {
                self?.listRefreshHeader?.endRefreshing()
                self?.collectionRefreshHeader?.endRefreshing()
                return
            }
            strongSelf.fileModels = files
            if XYFileBrowser.shared.viewMode == .list {
                strongSelf.listView.reloadData()
                strongSelf.listView.tableFooterView = files.isEmpty ? strongSelf.tipView : UIView()
            } else {
                strongSelf.collectionView.reloadData()
            }
            strongSelf.listRefreshHeader?.endRefreshing()
            strongSelf.collectionRefreshHeader?.endRefreshing()
        }
    }
    
    @objc private func filterChanged(_ segment: UISegmentedControl) {
        sortFile()
    }
    
    @objc private func back() {
        XYFileBrowser.shared.backToParentDirectory()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func changeViewStyle(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        listView.isHidden = btn.isSelected
        collectionView.isHidden = !btn.isSelected
        XYFileBrowser.shared.viewMode = btn.isSelected ? .collection : .list
        loadContent()
    }
    
//    -(void)sortFiles
//    {
//    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.highcaffeinecontent.Files"];
//    NSInteger sortingFilter = [defaults integerForKey:@"FBSortingFilter"];
//
//    self.files = [self.files sortedArrayWithOptions:0 usingComparator:^NSComparisonResult(NSString* file1, NSString* file2) {
//    NSString *newPath1 = [self.path stringByAppendingPathComponent:file1];
//    NSString *newPath2 = [self.path stringByAppendingPathComponent:file2];
//
//    BOOL isDirectory1, isDirectory2;
//    [[NSFileManager defaultManager] fileExistsAtPath:newPath1 isDirectory:&isDirectory1];
//    [[NSFileManager defaultManager] fileExistsAtPath:newPath2 isDirectory:&isDirectory2];
//
//    if (sortingFilter == 0)
//    {
//    if (isDirectory1 && !isDirectory2)
//    return NSOrderedDescending;
//
//    return  NSOrderedAscending;
//    }
//    else
//    {
//    if ([[file1 pathExtension] isEqualToString:[file2 pathExtension]])
//    return [file1 localizedCaseInsensitiveCompare:file2];
//
//    return [[file1 pathExtension] localizedCaseInsensitiveCompare:[file2 pathExtension]];
//    }
//    }];
//
//    [self.tableView reloadData];
//    }
    private func sortFile() {
        
    }
    
    private func previewFile(_ file: XYFile) {
        let filePreview = previewManager.previewViewControllerForFile(file, fromNavigation: true)
        filePreview.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(filePreview, animated: true)
    }


    private func playVideoWithMobilePlayer(file: XYFile) {
        let playerVC = MobilePlayerViewController(contentURL: file.fileURL)
        playerVC.title = "QVPlayer - \(file.fileURL.lastPathComponent)"
        playerVC.activityItems = [file.fileURL] // Check the documentation for more information.
        navigationController?.present(playerVC, animated: true, completion: {
            playerVC.play()
        })
    }
    
    private func playVideoWithVLCPlayer(file: XYFile) {
        let player = CustomVLCPlayerController(url: file.fileURL)
        navigationController?.present(player, animated: true, completion: {
            player.play()
            print(file.filePath)
        })
    }
    
    private func viewFileAttributes(file: XYFile) {
        let vc = XYFileAttributesViewController(file: file)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func fileSelected(_ file: XYFile) {
        if file.isDirectory {
            XYFileBrowser.shared.moveIntoSubDirectory(file.displayName)
            let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
            let fileVC = storyBoard.instantiateViewController(withIdentifier: "XYFileListViewController")
            navigationController?.pushViewController(fileVC, animated: true)
        } else if file.isVideo {
            playVideoWithVLCPlayer(file: file)
        } else {
            previewFile(file)
        }
    }
}

extension XYFileListViewController: UITableViewDataSource, UITableViewDelegate, UINavigationBarDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: XYFileListCell.cellID, for: indexPath) as! XYFileListCell
        let file = fileModels[indexPath.row]
        cell.nameLabel?.text = file.displayName
        cell.thumbnailImage?.image = file.type.image()
        if file.isDirectory {
            cell.sizeLabel?.text = "\(file.directoryContentsCount) 项"
            cell.accessoryType = .detailButton
        } else {
            cell.sizeLabel?.text = file.fileSize
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        fileSelected(fileModels[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let file = fileModels[indexPath.row]
            file.delete { [weak self] (ret) in
                if ret {
                    self?.loadContent()
                } else {
                    ToastView.showToast("删除文件失败")
                }
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let file = fileModels[indexPath.row]
        viewFileAttributes(file: file)
    }
}


extension XYFileListViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fileModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: XYFileCollectionCell.cellReuseID, for: indexPath) as! XYFileCollectionCell
        let file = fileModels[indexPath.row]
        cell.nameLabel.text = file.displayName
        let size = CGSize(width: XYFileCollectionCell.thumbnailWidth, height: XYFileCollectionCell.thumbnailHeight)
        
        if file.hasThumbnail {
            XYThumbnailService.startService(file: file, size: size) { (img) in
                if let image = img {
                    cell.thumbnailImage?.image = image
                }
            }
        } else {
            cell.thumbnailImage?.image = file.type.image()
        }
        
        if file.isDirectory {
            cell.despLabel.text = "\(file.directoryContentsCount) 项"
        } else {
            cell.despLabel.text = file.fileSize
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        fileSelected(fileModels[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.row < fileModels.count else { return }
        let file = fileModels[indexPath.row]
        if file.hasThumbnail {
            XYThumbnailService.stopService(file: file)
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: XYFileCollectionCell.cellWidth, height: XYFileCollectionCell.cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: cellSpacing, left: cellSpacing, bottom: cellSpacing, right: cellSpacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
    
}

