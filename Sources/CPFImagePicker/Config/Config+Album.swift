//
//  Config+Album.swift
//  
//
//  Created by Aaron on 2022/12/15.
//

import UIKit
import Then

extension Config {
    /// 相册配置
    public struct Album: Then {
        /// 动画时长，默认0.3秒
        public var animationTimeInterval: TimeInterval = 0.3

        /// 列表
        public var list = List()
        /// cell
        public var cell = Cell()
    }
}

extension Config.Album {
    /// 相册列表
    public struct List: Then {
        /// 背景颜色，默认black，50%alpha
        public var backgroundColor: UIColor = .black.withAlphaComponent(0.5)
        /// 内容边距，默认top: 10
        public var contentInset: UIEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        /// 内容最大高度，默认为屏幕高度的2/3
        public var maxContentHeight: CGFloat = UIScreen.main.bounds.height * 2.0 / 3.0
    }
}

extension Config.Album {
    /// 相册Cell配置
    public struct Cell: Then {
        /// 行高，默认74
        public var rowHeight: CGFloat = 74
    }
}
