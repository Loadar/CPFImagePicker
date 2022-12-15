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
    /// 请求相册权限
    /// - Parameters:
    ///   - completion: 权限请求结果
    public static func requestAlbumAuthorization(completion: @escaping (PHAuthorizationStatus) -> Void) {
        // 检查目前权限
        let status = currentAlbumAuthorizationStatus()
        switch status {
        case .authorized, .limited:
            // 已授权 & 允许了部分图片权限(iOS 14及以上)
            completion(status)
            return
        default:
            break
        }
        
        // 尝试向系统申请权限
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    completion(status)
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    completion(status)
                }
            }
        }
    }
    
    /// 当前相册权限
    public static func currentAlbumAuthorizationStatus() -> PHAuthorizationStatus {
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            // iOS 14以上需要使用新的api获取权限
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }
        return status
    }
}

extension Util {
    internal static func color(with hexValue: Int, containsAlpha: Bool = false) -> UIColor {
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
    static func fetchAlbums(completion: @escaping ([Album]) -> Void) {
        
        func albums(of result: PHFetchResult<PHAssetCollection>) -> [Album] {
            func isCameraRoll(of collection: PHAssetCollection) -> Bool {
                switch collection.assetCollectionSubtype {
                case .smartAlbumUserLibrary: return true
                default: return false
                }
            }

            var albums = [Album]()
            result.enumerateObjects { collection, index, _ in
                
                let isCameraRoll = isCameraRoll(of: collection)
                
                // 过滤空相册(相机胶卷不过滤，总是显示)
                guard collection.estimatedAssetCount > 0 || isCameraRoll else { return }
                // 过滤隐藏相册
                guard collection.assetCollectionSubtype != .smartAlbumAllHidden else { return }
                // 过滤最近删除相册
                guard collection.assetCollectionSubtype.rawValue != 1000000201 else { return }
                
                let option = PHFetchOptions().then {
                    $0.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
                    $0.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                }

                let assetResult = PHAsset.fetchAssets(in: collection, options: option)
                // 无图片(除了相机胶卷)
                guard assetResult.countOfAssets(with: .image) > 0 || isCameraRoll else { return }
                
                let coverPhoto = assetResult.firstObject.flatMap {
                    Photo(asset: $0)
                }
                let album = Album(
                    collection: collection,
                    assetResult: assetResult,
                    name: collection.localizedTitle ?? "",
                    isCameraRoll: isCameraRoll,
                    photoCount: assetResult.countOfAssets(with: .image),
                    coverPhoto: coverPhoto
                )
                albums.append(album)
            }
            return albums
        }
        
        var albumCollections: [PHFetchResult<PHAssetCollection>] = []
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        albumCollections.append(smartAlbums)
        if let topLevelUserCollections = PHAssetCollection.fetchTopLevelUserCollections(with: nil) as? PHFetchResult<PHAssetCollection> {
            albumCollections.append(topLevelUserCollections)
        }
        let syncedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedAlbum, options: nil)
        albumCollections.append(syncedAlbums)

        var finalAlbums = [Album]()
        for result in albumCollections {
            let albums = albums(of: result)
            albums.forEach { item in
                if !finalAlbums.contains(where: { $0.collection == item.collection }) {
                    finalAlbums.append(item)
                }
            }
        }
        
        if let index = finalAlbums.firstIndex(where: { $0.isCameraRoll }) {
            let cameraRollAlbum = finalAlbums.remove(at: index)
            finalAlbums.insert(cameraRollAlbum, at: 0)
        }

        completion(finalAlbums)
    }
    /*
    //获取所有Album列表
    - (void)getAllAlbums:(BOOL)allowPickingVideo
       allowPickingImage:(BOOL)allowPickingImage
         needFetchAssets:(BOOL)needFetchAssets
              completion:(void (^)(NSArray<YZGAlbumModel *> *albumList))completion{
        NSMutableArray *albumArr = [NSMutableArray array];
//        PHFetchOptions *option = [[PHFetchOptions alloc] init];
//        if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
//        if (!allowPickingImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
//                                                    PHAssetMediaTypeVideo];
//        // option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:self.sortAscendingByModificationDate]];
//        if (!self.sortAscendingByModificationDate) {
//            option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.sortAscendingByModificationDate]];
//        }
                  
        // 我的照片流 1.6.10重新加入..
        //PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];先不加入cloud照片
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
        //PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil]; 先不加入cloud照片
        NSArray *allAlbums = @[smartAlbums,topLevelUserCollections,syncedAlbums];
        for (PHFetchResult *fetchResult in allAlbums) {
            for (PHAssetCollection *collection in fetchResult) {
                // 有可能是PHCollectionList类的的对象，过滤掉
                if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
                // 过滤空相册
                if (collection.estimatedAssetCount <= 0 && ![self isCameraRollAlbum:collection]) continue;
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
                if (fetchResult.count < 1 && ![self isCameraRollAlbum:collection]) continue;
    //            [self getAssetType:asset]
    //            [fetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
    //                [self getAssetType:asset];
    //                YZGAssetModelMediaType type = [self getAssetType:asset];
    //                //NSLog(@"YZGAssetModelMediaType : %d",type);
    //                if ( type == YZGAssetModelMediaTypeVideo) ;//!allowPickingVideo &&
    //                if (!allowPickingImage && type == YZGAssetModelMediaTypePhoto) continue;
    //                if (type == YZGAssetModelMediaTypePhotoGif) continue;//!allowPickingImage &&
    //            }];
                
                if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) continue;
                if (collection.assetCollectionSubtype == 1000000201) continue; //『最近删除』相册
                if ([self isCameraRollAlbum:collection]) {
                    [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle isCameraRoll:YES needFetchAssets:needFetchAssets] atIndex:0];
                } else {
                    [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle isCameraRoll:NO needFetchAssets:needFetchAssets]];
                }
            }
        }
        if (completion) {
            completion(albumArr);
        }
    }

    
    [[YZGImageVideoPickerHelper helper] getAllAlbums:[YZGPickerConfig sharedInstance].pickerType == YZGImageVideoPickerTypeVideo allowPickingImage:[YZGPickerConfig sharedInstance].pickerType == YZGImageVideoPickerTypeImage needFetchAssets:YES completion:^(NSArray<YZGAlbumModel *> *albumList) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSMutableArray *array = [NSMutableArray array];
        for (YZGAlbumModel *album in albumList) {
            if (album.count == 0) {
                [array addObject:album];
            }
        }
        
        NSMutableArray * albumArray = [NSMutableArray arrayWithArray:albumList];
        [albumArray removeObjectsInArray:array];
    
        
        if(strongSelf.firstAlbum){
            [albumArray replaceObjectAtIndex:0 withObject:strongSelf.firstAlbum];
        }
        strongSelf.albumList = albumArray.copy;
        [strongSelf.tableView reloadData];
        CGFloat tableHeight = ROW_HEIGHT*[albumList count];
        tableHeight = tableHeight>YZG_ALBUM_LIST_MAX_HEIGHT?YZG_ALBUM_LIST_MAX_HEIGHT:tableHeight;
        strongSelf.tableView.frame = CGRectMake(0, -tableHeight, strongSelf.view.frame.size.width, tableHeight);
    }];
    */
    
    /// 获取指定相册的照片assert
    /// - Parameters:
    ///   - collection: 相册对应的collection
    ///   - onlyImages: 是否仅保留图片类型的数据
    public static func assets(of collection: PHAssetCollection, onlyImages: Bool) -> [PHAsset] {
        let option = PHFetchOptions().then {
            if onlyImages {
                $0.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
            }
            $0.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        }
        let assetResult = PHAsset.fetchAssets(in: collection, options: option)
        
        // 无图片
        if onlyImages, assetResult.countOfAssets(with: .image) <= 0 {
            return []
        }
        
        var assets = [PHAsset]()
        assetResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
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
            if pixelWidth > 300 {
                $0.isNetworkAccessAllowed = true
            }
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
