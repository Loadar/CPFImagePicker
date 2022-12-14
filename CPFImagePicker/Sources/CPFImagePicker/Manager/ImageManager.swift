//
//  ImageManager.swift
//  
//
//  Created by Aaron on 2022/12/9.
//

import UIKit
import Photos

/// 图片管理器
public final class ImageManager {
    public static let shared = ImageManager()
    private init() {}
    
    /// 缩略图缓存
    private let thumbnailCache = NSCache<NSString, UIImage>().then {
        $0.countLimit = 10000
    }
    /// 图像请求信息
    private var imageRequestInfo: [String: PHImageRequestID] = [:]
    /// 图像请求回调
    private var imageRequestCompletionInfo: [String: [(UIImage, PHAsset) -> Void]] = [:]
}

extension ImageManager {
    /// 获取指定照片缩略图
    /// - Parameters:
    ///   - asset: 照片对应asset
    ///   - width: 图像宽度，单位为pt
    ///   - keepImageSizeRatio: 是否保持图像宽高比
    ///   - responseOnceForSameRequest: 同样的图像请求，是否仅响应最后一次的回调，默认true
    ///   - completion: 完成回调
    public func fetchThumbnail(
        of asset: PHAsset,
        width: CGFloat,
        keepImageSizeRatio: Bool,
        responseOnceForSameRequest: Bool = true,
        completion: @escaping (UIImage, PHAsset) -> Void
    ) {
        let key = "\(asset.localIdentifier)-\(width)-\(keepImageSizeRatio)"
        let keyObject = key as NSString
        
        // 检查缓存
        if let image = thumbnailCache.object(forKey: keyObject) {
            completion(image, asset)
            return
        }
        
        if let list = imageRequestCompletionInfo[key] {
            var newList = list
            // 思考：闭包是否需要去重
            newList.append(completion)
            imageRequestCompletionInfo[key] = list
        } else {
            imageRequestCompletionInfo[key] = [completion]
        }
        
        // 从相册获取
        if let _ = imageRequestInfo[key] {
            // 已经在请求中
            // 思考：是否需要添加闭包回调处理以及是否取消和重试
            return
        }
        
        let id = Util.image(of: asset, width: width, keepImageSizeRatio: keepImageSizeRatio, completion: { [weak self] image, isDegraded, _ in
            guard let self = self else { return }
            self.thumbnailCache.setObject(image, forKey: keyObject)
            self.imageRequestCompletionInfo[key]?.forEach {
                $0(image, asset)
            }
            if !isDegraded {
                self.imageRequestCompletionInfo[key] = nil
                self.imageRequestInfo[key] = nil
            }
        })
        self.imageRequestInfo[key] = id
    }
}
