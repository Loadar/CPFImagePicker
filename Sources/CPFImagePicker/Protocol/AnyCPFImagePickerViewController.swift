//
//  AnyCPFImagePickerViewController.swift
//  
//
//  Created by Aaron on 2023/6/7.
//

import UIKit

public protocol AnyCPFImagePickerViewController: AnyObject {
    /// 指定初始化方法
    init(data: AlbumData)
    
    /// 完成回调
    var completion: ((AlbumData?, Bool) -> Void)? { get set }
}
