//
//  AnyCPFImagePickerObserver.swift
//  
//
//  Created by Aaron on 2022/12/14.
//

import Foundation

/// 任意观察者
protocol AnyCPFImagePickerObserver: AnyObject {
    /// 相册列表改变
    func albumListDidChanged()
    /// 指定相册的照片列表改变
    func photoListDidChanged(of album: Album)
}

extension AnyCPFImagePickerObserver {
    func albumListDidChanged() {}
    func photoListDidChanged(of album: Album) {}
}
