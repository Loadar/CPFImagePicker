//
//  AnyCPFAlbumCell.swift
//  
//
//  Created by Aaron on 2022/12/8.
//

import UIKit

/// 任意相册Cell
public protocol AnyCPFAlbumCell {
    /// 更新数据
    func updateData(_ album: Album, hasSelectedPhoto: Bool)
}
