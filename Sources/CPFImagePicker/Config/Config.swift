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
    
    /// 偏好的导航模式，默认push
    public var preferNavigateMode: NavigateMode = .push
    /// 实际使用的导航模式
    public internal(set) var displayNavigateMode: NavigateMode = .push
    
    /// 是否在完成时收起界面，默认true
    public var dismissWhenCompleted = true
}

extension Config {
    /// 导航模式
    public enum NavigateMode {
        /// 使用可查找到的最上层的导航控制器来展示
        /// 注意：若找不到可用的导航控制器，将使用modal的方式来展示
        case push
        /// 使用模态的方式来展示
        case modal
    }
}
