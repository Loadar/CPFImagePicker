//
//  Photo.swift
//  
//
//  Created by Aaron on 2022/12/8.
//

import UIKit
import Photos

/// 照片
public struct Photo {
    /// 底层数据
    public let asset: PHAsset
    /// 类型
    public let type: PhotoType
    
    /// 缩略图
    public var thumbanil: UIImage? {
        let defaultConfig = Config()
        let width = defaultConfig.photo.list.layoutProvider().itemSize.width
        return ImageManager.shared.thumbnail(of: self, width: width)
    }
    
    /// 通过asset及照片类型初始化
    public init(asset: PHAsset, type: PhotoType) {
        self.asset = asset
        self.type = type
    }
    
    /// 通过asset初始化，当其类型非照片时，返回nil
    public init?(asset: PHAsset) {
        guard let type = Util.photoType(of: asset) else { return nil }
        self.init(asset: asset, type: type)
    }
    
    /// 通过asset id初始化，当其对应的asset不存在或其类型非照片时，返回nil
    public init?(assetId: String) {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: options)
        guard let asset = result.firstObject else { return nil }
        
        self.init(asset: asset)
    }
}

public extension Photo {
    /// 像素尺寸
    var pixelSize: CGSize {
        CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
    }
    
    /// 原文件名
    var fileName: String {
        guard let resource = PHAssetResource.assetResources(for: asset).first else {
            assert(false, "无可用资源")
            return ""
        }
        return resource.originalFilename
    }
    
    /// 原文件大小
    var fileSize: Int64 {
        guard let resource = PHAssetResource.assetResources(for: asset).first else {
            assert(false, "无可用资源")
            return 0
        }
        if let size = resource.value(forKey: "fileSize") as? Int64 {
            return size
        }
        
        assert(false, "无法获取文件大小")
        return 0
    }
}

extension Photo: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.asset.localIdentifier == rhs.asset.localIdentifier
    }
}
