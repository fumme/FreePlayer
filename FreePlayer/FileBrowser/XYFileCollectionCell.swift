//
//  XYFileCollectionCell.swift
//  FreePlayer
//
//  Created by CXY on 2019/3/1.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit

class XYFileCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var despLabel: UILabel!
    
    static let cellSpacing: CGFloat = 8
    static let cellWidth: CGFloat = (UIScreen.main.bounds.size.width-4*cellSpacing)/3 - 0.001
    static let cellHeight: CGFloat = 130
    static let cellReuseID = "XYFileCollectionCell"
    static let thumbnailHeight: CGFloat = 89
    static let thumbnailWidth: CGFloat = cellWidth
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
