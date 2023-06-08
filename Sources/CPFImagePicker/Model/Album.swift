//
//  Album.swift
//  
//
//  Created by Aaron on 2022/12/8.
//

import Foundation
import Photos

/// 相册
public struct Album {
    /// 底层数据
    public let collection: PHAssetCollection
    /// 照片列表底层数据
    let assetResult: PHFetchResult<PHAsset>
    
    /// 名称
    public let name: String
    /// 是否是相机胶卷(拍照默认保存的相册)
    public let isCameraRoll: Bool
    /// 照片数目
    public let photoCount: Int
    /// 封面照片
    public let coverPhoto: Photo?
    
    init(
        collection: PHAssetCollection,
        assetResult: PHFetchResult<PHAsset>,
        name: String,
        isCameraRoll: Bool,
        photoCount: Int,
        coverPhoto: Photo?
    ) {
        self.collection = collection
        self.assetResult = assetResult
        self.name = name
        self.isCameraRoll = isCameraRoll
        self.photoCount = photoCount
        self.coverPhoto = coverPhoto
    }
    
    /// 是否包含指定照片
    func contains(_ photo: Photo) -> Bool {
        assetResult.contains(photo.asset)
    }
}

extension Album: Equatable, Hashable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.collection.localIdentifier == rhs.collection.localIdentifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(collection.localIdentifier)
    }
}
