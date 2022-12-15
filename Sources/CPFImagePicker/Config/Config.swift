//
//  Config.swift
//  
//
//  Created by Aaron on 2022/12/8.
//

import UIKit
import Then

/// 全局配置
public struct Config: Then {
    /// 全局样式
    public var appearance = Appearance()
    /// 相册列表
    public var album = Album()
    /// 照片
    public var photo = Photo()
}

