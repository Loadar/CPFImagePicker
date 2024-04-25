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
        $0.countLimit = 20000
    }
    /// 图像请求回调
    private var thumbnailTasks: [ThumbnailTask] = []
}

extension ImageManager {
    /// 获取指定照片缩略图
    /// - Parameters:
    ///   - asset: 照片对应asset
    ///   - width: 图像宽度，单位为pt
    ///   - keepImageSizeRatio: 是否保持图像宽高比
    ///   - completion: 完成回调
    func fetchThumbnail(
        of asset: PHAsset,
        width: CGFloat,
        keepImageSizeRatio: Bool,
        completion: @escaping (UIImage, Bool, PHAsset) -> Void
    ) {
        var task = ThumbnailTask(asset: asset, width: width, keepImageSizeRatio: keepImageSizeRatio, completion: completion)
        
        // 检查缓存
        if let image = thumbnailCache.object(forKey: task.id as NSString) {
            completion(image, false, asset)
            return
        }
        if let image = thumbnailCache.object(forKey: "\(task.id)-degraded" as NSString) {
            completion(image, true, asset)
        }
        
        if let index = thumbnailTasks.firstIndex(where: { $0.id == task.id }) {
            // 已经在请求中, 忽略新请求，返回旧请求id
            thumbnailTasks[index].addCompletion(completion)
            return
        }
        
        let id = Util.image(of: asset, width: width, keepImageSizeRatio: keepImageSizeRatio, completion: { [weak self] image, isDegraded, _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if !isDegraded {
                    self.thumbnailCache.setObject(image, forKey: task.id as NSString)
                } else {
                    self.thumbnailCache.setObject(image, forKey: "\(task.id)-degraded" as NSString)
                }
                if let theTask = self.thumbnailTasks.first(where: { $0.id == task.id }) {
                    theTask.completions.forEach {
                        $0(image, isDegraded, theTask.asset)
                    }
                }
                
                if !isDegraded {
                    self.thumbnailTasks.removeAll(where: { $0.id == task.id })
                }
            }
        })
        task.requestId = id
        thumbnailTasks.append(task)
    }
}

extension ImageManager {
    /// 指定照片的缩略图，仅从缓存中获取
    public func thumbnail(of photo: Photo, width: CGFloat) -> UIImage? {
        let key = "\(photo.asset.localIdentifier)-\(width)-\(false)"
        if let image = thumbnailCache.object(forKey: key as NSString) {
            return image
        } else {
            let gradedKey = "\(key)-degraded"
            return thumbnailCache.object(forKey: gradedKey as NSString)
        }
    }
}

extension ImageManager {
    func cancelTask(with id: String) {
        guard let index = thumbnailTasks.firstIndex(where: { $0.id == id }) else { return }
        var task = thumbnailTasks[index]
        task.referenceCount -= 1
        guard task.referenceCount <= 0 else {
            thumbnailTasks[index] = task
            return
        }
        
        if let requestId = task.requestId {
            PHImageManager.default().cancelImageRequest(requestId)
        }
        thumbnailTasks.removeAll(where: { $0.id == id })
    }
}

extension ImageManager {
    /// 缩略图任务
    struct ThumbnailTask {
        /// id
        let id: String
        /// asset
        let asset: PHAsset
        /// 缩略图宽度
        let width: CGFloat
        /// 是否保存图像宽高比
        let keepImageSizeRatio: Bool
        /// 完成回调
        private(set) var completions: [(UIImage, Bool, PHAsset) -> Void]
        /// 创建时间
        let createDate: Date
        /// 请求id
        var requestId: PHImageRequestID?
        
        /// 引用计数
        var referenceCount = 0
        
        init(asset: PHAsset, width: CGFloat, keepImageSizeRatio: Bool, completion: @escaping (UIImage, Bool, PHAsset) -> Void) {
            self.id = Self.id(of: asset, width: width, keepImageSizeRatio: keepImageSizeRatio)
            self.asset = asset
            self.width = width
            self.keepImageSizeRatio = keepImageSizeRatio
            self.completions = [completion]
            self.createDate = Date()
            self.referenceCount = 1
        }
        
        static func id(of asset: PHAsset, width: CGFloat, keepImageSizeRatio: Bool) -> String {
            "\(asset.localIdentifier)-\(width)-\(keepImageSizeRatio)"
        }
        
        mutating func addCompletion(_ completion: @escaping (UIImage, Bool, PHAsset) -> Void) {
            completions.append(completion)
            referenceCount += 1
        }
    }
}
