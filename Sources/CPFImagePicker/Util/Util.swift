//
//  Util.swift
//  
//
//  Created by Aaron on 2022/12/8.
//

import UIKit
import Photos

public struct Util {
    /// 获取指定照片的类型，非照片类型返回nil
    internal static func photoType(of asset: PHAsset) -> PhotoType? {
        switch asset.mediaType {
        case .image:
            if asset.mediaSubtypes.contains(.photoLive) {
                return .live
            } else if let name = asset.value(forKey: "filename") as? String, name.lowercased().hasSuffix("gif") {
                return .gif
            } else {
                return .common
            }
        case .video, .audio:
            // 暂不支持的类型
            return nil
        case .unknown:
            return nil
        @unknown default:
            return nil
        }
    }
}

extension Util {
    public static func color(with hexValue: Int, containsAlpha: Bool = false) -> UIColor {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat
        
        if containsAlpha {
            red = CGFloat((hexValue & 0xff000000) >> 24) / 255.0
            green = CGFloat((hexValue & 0xff0000) >> 16) / 255.0
            blue = CGFloat((hexValue & 0xff00) >> 8) / 255.0
            alpha = CGFloat(hexValue & 0xff) / 255.0
        } else {
            red = CGFloat((hexValue & 0xff0000) >> 16) / 255.0
            green = CGFloat((hexValue & 0xff00) >> 8) / 255.0
            blue = CGFloat(hexValue & 0xff) / 255.0
            alpha = 1
        }
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension Util {
    static func fetchAlbums(completion: @escaping ((albums: [Album], isAll: Bool)) -> Void) {
        DispatchQueue.global().async {
            var finalAlbums = [Album]()
            
            func checkCameraRoll() {
                if let index = finalAlbums.firstIndex(where: { $0.isCameraRoll }), index > 0 {
                    let cameraRollAlbum = finalAlbums.remove(at: index)
                    finalAlbums.insert(cameraRollAlbum, at: 0)
                }
            }
            
            let smartAlbumResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
            for album in self.albums(of: smartAlbumResult) {
                if !finalAlbums.contains(where: { $0.collection == album.collection }) {
                    finalAlbums.append(album)
                    
                    if !DataManager.shared.albumFetched, finalAlbums.contains(where: { $0.isCameraRoll }) {
                        checkCameraRoll()
                        DispatchQueue.main.async {
                            completion((finalAlbums, false))
                        }
                    }
                }
            }
            
            let syncedAlbumResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            for album in self.albums(of: syncedAlbumResult) {
                if !finalAlbums.contains(where: { $0.collection == album.collection }) {
                    finalAlbums.append(album)
                    if !DataManager.shared.albumFetched, finalAlbums.contains(where: { $0.isCameraRoll }) {
                        checkCameraRoll()
                        DispatchQueue.main.async {
                            completion((finalAlbums, false))
                        }
                    }
                }
            }
            
            checkCameraRoll()
            
            DispatchQueue.main.async {
                completion((finalAlbums,true))
            }
        }
    }
    
    private static func albums(of result: PHFetchResult<PHAssetCollection>) -> [Album] {
        var albums = [Album]()
        result.enumerateObjects { collection, index, _ in
            if let album = self.album(of: collection) {
                albums.append(album)
            }
        }
        return albums
    }
    
    private static func albums(of result: PHFetchResult<PHCollection>) -> [Album] {
        var finalAlbums = [Album]()
        result.enumerateObjects { collection, index, _ in
            if let list = collection as? PHCollectionList {
                // 取文件夹中的相册
                let result = PHAssetCollection.fetchCollections(in: list, options: nil)
                finalAlbums.append(contentsOf: self.albums(of: result))
            } else if let collection = collection as? PHAssetCollection {
                if let album = self.album(of: collection) {
                    finalAlbums.append(album)
                }
            } else {
                // do nothing
            }
        }
        return finalAlbums
    }
        
    private static func album(of collection: PHAssetCollection) -> Album? {
        func isCameraRoll(of collection: PHAssetCollection) -> Bool {
            switch collection.assetCollectionSubtype {
            case .smartAlbumUserLibrary: return true
            default: return false
            }
        }

        let isCameraRoll = isCameraRoll(of: collection)
        
        // 过滤空相册(相机胶卷不过滤，总是显示)
        guard collection.estimatedAssetCount > 0 || isCameraRoll else { return nil }
        // 过滤隐藏相册
        guard collection.assetCollectionSubtype != .smartAlbumAllHidden else { return nil }
        // 过滤最近删除相册
        guard collection.assetCollectionSubtype.rawValue != 1000000201 else { return nil }
            
        let option = PHFetchOptions().then {
            $0.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
            $0.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        }
        
        let assetResult = PHAsset.fetchAssets(in: collection, options: option)
        // 无照片(除了相机胶卷)
        guard assetResult.countOfAssets(with: .image) > 0 || isCameraRoll else { return nil }
        
        let coverPhoto = assetResult.firstObject.flatMap {
            Photo(asset: $0)
        }

        return Album(
            collection: collection,
            assetResult: assetResult,
            name: collection.localizedTitle ?? "",
            isCameraRoll: isCameraRoll,
            photoCount: assetResult.countOfAssets(with: .image),
            coverPhoto: coverPhoto
        )
    }
        
    /// 获取指定相册的照片assert列表
    /// - Parameters:
    ///   - album: 相册
    ///   - page: 分页， 从0开始
    ///   - pageSize: 分页大小
    ///   - completion: 完成回调
    public static func assets(of album: Album, page: Int, pageSize: Int, completion: @escaping ([PHAsset]) -> Void) {
        let assetResult = album.assetResult
        
        // 无图片
        if assetResult.countOfAssets(with: .image) <= 0 {
            completion([])
            return
        }
        
        var assets = [PHAsset]()
        let from = page * pageSize
        var to = (page + 1) * pageSize
        let count = assetResult.count
        if from > count - 1 {
            completion([])
            return
        }
        if to > count {
            to = count
        }
        let indexSet = IndexSet(integersIn: from..<to)
        assets = assetResult.objects(at: indexSet)
        completion(assets)
    }
}

extension Util {
    /// 获取照片原始数据
    /// - Parameters:
    ///   - photo: 当前照片
    ///   - synchronous: 是否是同步获取
    ///   - completion: 完成回调
    /// - Returns: 获取Id，用于取消请求
    public static func originalPhotoData(
        of photo: Photo,
        synchronous: Bool,
        completion: @escaping ((data: Foundation.Data, info: [AnyHashable: Any], orientation: UIImage.Orientation)?) -> Void
    ) -> PHImageRequestID {
        let asset = photo.asset
        let option = PHImageRequestOptions().then {
            $0.resizeMode = .none
            $0.isSynchronous = synchronous
            // 原始数据可能存放在iCloud，需要支持网络请求
            $0.isNetworkAccessAllowed = true
        }
        if #available(iOS 13, *) {
            return PHImageManager.default().requestImageDataAndOrientation(for: asset, options: option, resultHandler: { data, _, orientation, info in
                guard let info = info else {
                    completion(nil)
                    return
                }
                if let status = info[PHImageCancelledKey] as? Bool, status {
                    // 取消了
                    // ?? 取消了还会有回调？
                    completion(nil)
                    return
                }
                if let status = info[PHImageErrorKey] as? Bool, status {
                    // 出错了
                    completion(nil)
                    return
                }
                guard let data = data else {
                    completion(nil)
                    return
                }
                let finalOrientation: UIImage.Orientation = {
                    switch orientation {
                    case .up: return .up
                    case .down: return .down
                    case .left: return .left
                    case .right: return .right
                    case .upMirrored: return .upMirrored
                    case .downMirrored: return .downMirrored
                    case .leftMirrored: return .leftMirrored
                    case .rightMirrored: return .rightMirrored
                    }
                }()
                completion((data, info, finalOrientation))
            })
        } else {
            return PHImageManager.default().requestImageData(for: asset, options: option, resultHandler: { data, _, orientation, info in
                guard let info = info else {
                    completion(nil)
                    return
                }
                if let status = info[PHImageCancelledKey] as? Bool, status {
                    // 取消了
                    // ?? 取消了还会有回调？
                    completion(nil)
                    return
                }
                if let status = info[PHImageErrorKey] as? Bool, status {
                    // 出错了
                    completion(nil)
                    return
                }
                guard let data = data else {
                    completion(nil)
                    return
                }
                completion((data, info, orientation))
            })
        }
    }
    
    /// 获取照片指定尺寸的图像
    /// - Parameters:
    ///   - asset: 照片对应的asset
    ///   - width: 图像宽度，单位为pt
    ///   - keepImageSizeRatio: 是否保持图像宽高比
    ///   - completion: 完成回调
    /// - Returns: 获取Id，用于取消请求
    public static func image(
        of asset: PHAsset,
        width: CGFloat,
        keepImageSizeRatio: Bool,
        completion: @escaping (_ image: UIImage, _ isDegraded: Bool, _ info: [AnyHashable: Any]?) -> Void
    ) -> PHImageRequestID {
        let pixelWidth = width * UIScreen.main.scale
        let imageSize: CGSize
        if keepImageSizeRatio {
            if asset.pixelWidth > 0, asset.pixelHeight > 0 {
                let ratio = CGFloat(asset.pixelHeight) / CGFloat(asset.pixelWidth)
                let pixelHeight = pixelWidth * ratio
                imageSize = CGSize(width: pixelWidth, height: pixelHeight)
            } else {
                imageSize = CGSize(width: pixelWidth, height: pixelWidth)
            }
        } else {
            imageSize = CGSize(width: pixelWidth, height: pixelWidth)
        }
        
        let options = PHImageRequestOptions().then {
            $0.resizeMode = .fast
            $0.isNetworkAccessAllowed = true
        }
        return PHImageManager.default().requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options) { image, info in
            guard let image = image else { return }
            let isDegraded: Bool
            if let value = info?[PHImageResultIsDegradedKey] as? Bool {
                isDegraded = value
            } else {
                isDegraded = false
            }
            completion(image, isDegraded, info)
        }
    }
    
    /// 取消指定id的图片获取请求
    /// - Parameter id: 请求id
    public static func cancelPhotoImageRequest(of id: PHImageRequestID) {
        PHImageManager.default().cancelImageRequest(id)
    }
}

extension Util {
    public static var topController: UIViewController? {
        var controller = UIApplication.shared.keyWindow?.rootViewController
        while let aController = controller?.presentedViewController {
            controller = aController
        }
        return controller
    }
}
