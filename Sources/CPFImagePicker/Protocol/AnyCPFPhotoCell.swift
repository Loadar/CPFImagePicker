//
//  AnyCPFPhotoCell.swift
//  
//
//  Created by Aaron on 2022/12/8.
//

import UIKit

/// 任意照片Cell
public protocol AnyCPFPhotoCell {
    /// 更新数据
    /// - Parameters:
    ///   - photo: 照片数据
    ///   - isSelected: 是否被选中
    ///   - selectedIndex: 当前照片在全部选中照片中的索引
    ///   - selectable: 是否可以选择
    func updateData(_ photo: Photo, isSelected: Bool, selectedIndex: Int, selectable: Bool)
    
    /// 仅更新选中状态
    /// - Parameters:
    ///   - selectedState: 是否选中
    ///   - selectedIndex: 当前照片在全部选中照片中的索引
    func update(selectedState: Bool, selectedIndex: Int)
    
    /// 更新配置
    func update(config: Config.Photo.Cell)
}
