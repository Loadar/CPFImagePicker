//
//  Config.swift
//  
//
//  Created by Aaron on 2022/12/13.
//

import UIKit

extension Config {
    /// 照片配置
    public struct Photo {
        /// 最多可选择的数目，默认1
        public var maxSelectableCount = 1
        /// 指定照片是否可选择，未指定时仅受到最大选择数目限制，默认为nil
        public var photoShouldSelect: ((CPFImagePicker.Photo) -> Bool)?
        /// 尝试选取超出限制数目的照片
        public var tryToSelectPhotoBeyondMaxCount: ((Config) -> Void)?
        
        /// 是否支持拍照，默认true
        public var takePhotoEnabled = true
        
        /// 列表
        public var list = List()
        /// Cell
        public var cell = Cell()
    }
}

extension Config.Photo {
    /// 列表配置
    public struct List {
        
        /// 布局
        /// 注意：提供的是一个闭包而不是对象，以防止多个列表复用同一个布局对象导致异常
        public var layoutProvider: () -> UICollectionViewFlowLayout = {
            UICollectionViewFlowLayout().then {
                // 每行展示3项，间距2，边距0
                let interSpace: CGFloat = 2
                var width = UIScreen.main.bounds.width - 4
                width /= 3
                width = floor(width)
                
                $0.itemSize = CGSize(width: width, height: width)
                $0.minimumInteritemSpacing = interSpace
                $0.minimumLineSpacing = 2
                $0.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
                $0.scrollDirection = .vertical
            }
        }
        
    }
}

extension Config.Photo {
    /// Cell配置
    public struct Cell {
        /// 缩略图圆角，默认无
        public var thumbnailCornerRadius: CGFloat?
        /// 缩略图边框(线宽、颜色)，默认无
        public var thumbnailBorder: (CGFloat, UIColor)?
        
        /// 选择状态图标尺寸，默认(24, 24)
        public var selectStateIconSize = CGSize(width: 24, height: 24)
        /// 未选中图标
        public var unSelectedIcon: UIImage? = {
            if let url = Bundle.module.url(forResource: "unselected", withExtension: "png") {
                return UIImage(contentsOfFile: url.path)
            } else {
                return nil
            }
        }()
        /// 选中图标
        public var selectedIcon: UIImage? = {
            if let url = Bundle.module.url(forResource: "selected", withExtension: "png") {
                return UIImage(contentsOfFile: url.path)
            } else {
                return nil
            }
        }()
        /// 指定序号的选中图标背景，序号需要额外添加
        public var selectedBackgroundIcon: UIImage? = {
            if let url = Bundle.module.url(forResource: "selectedBackground", withExtension: "png") {
                return UIImage(contentsOfFile: url.path)
            } else {
                return nil
            }
        }()
        /// 展示的选中图标
        public var displaySelectedIcon: UIImage? {
            displaySelectedIconIndex ? selectedBackgroundIcon : selectedIcon
        }
        /// 选中图片是否展示序号
        public var displaySelectedIconIndex = false
        
        
        /// 无法选中蒙层颜色，默认.white, 40%alpha
        public var maskColor: UIColor = .white.withAlphaComponent(0.4)
    }
}
