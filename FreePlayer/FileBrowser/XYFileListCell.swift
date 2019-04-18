//
//  XYFileListCell.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/28.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class XYFileListCell: UITableViewCell {

    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    
    static let thumbnailHeight: CGFloat = 72.5
    static let thumbnailWidth: CGFloat = 100
    static let cellHeight: CGFloat = 85
    static let cellID = "XYFileListCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = XYConst.commonLightWhiteColor
        backgroundColor = XYConst.commonLightWhiteColor
        
    }
    
}
