//
//  Config.swift
//  
//
//  Created by Aaron on 2022/12/8.
//

import UIKit

/// 全局配置
public struct Config {
    
    /// 照片
    public var photo = Photo()
    
    /// 是否使用系统导航栏，指定为false时导航栏部分将使用自定view来实现，默认false(使用modal方式展示时才生效)
    public var displaySystemNavigationBar = false
    
    /// 返回图标
    public var backIcon: UIImage? = {
        if let url = Bundle.module.url(forResource: "back", withExtension: "png") {
            return UIImage(contentsOfFile: url.path)
        } else {
            return nil
        }
    }()
    /// 返回图标尺寸
    public var backIconSize: CGSize = CGSize(width: 24, height: 24)
    
    /// 下拉图标
    public var popUpIcon: UIImage? = {
        if let url = Bundle.module.url(forResource: "popUp", withExtension: "png") {
            return UIImage(contentsOfFile: url.path)
        } else {
            return nil
        }
    }()
    /// 下拉图标尺寸
    public var popUpIconSize: CGSize = CGSize(width: 16, height: 16)

    
    /// 相册列表
    public var albumList = AlbumListConfig()
    
//    /// 照片Cell配置
//    public var photoCell = PhotoCellConfig()
}

