//
//  AnyCPFDataObserver.swift
//  
//
//  Created by Aaron on 2022/12/14.
//

import Foundation

/// 任意数据观察者
protocol AnyCPFDataObserver: AnyObject {
    /// 选中相册改变
    func selectedAlbumDidChanged()
    /// 选中的照片改变
    func selectedPhotosDidChanged()
}

extension AnyCPFDataObserver {
    func selectedAlbumDidChanged() {}
    func selectedPhotosDidChanged() {}
}
