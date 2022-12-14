//
//  AlbumListConfig.swift
//  
//
//  Created by Aaron on 2022/12/12.
//

import UIKit

public struct AlbumListConfig {
    /// 背景颜色，默认black，50%alpha
    public var backgroundColor: UIColor = .black.withAlphaComponent(0.5)
    
    /// 内容边距，默认top: 10
    public var contentInset: UIEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
    /// 内容最大高度
    public var maxContentHeight: CGFloat = UIScreen.main.bounds.height * 2.0 / 3.0
    
    /// Cell高度
    public var cellHeight: CGFloat = 74
    
    /// 动画时长，默认0.3秒
    public var animationTimeInterval: TimeInterval = 0.3
}
