//
//  Util+Album.swift
//  
//
//  Created by Aaron on 2023/6/7.
//

import UIKit
import Photos

public extension Util {
    /// 请求相册权限
    /// - Parameters:
    ///   - completion: 权限请求结果
    static func requestAlbumAuthorization(completion: @escaping (PHAuthorizationStatus) -> Void) {
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
    static func currentAlbumAuthorizationStatus() -> PHAuthorizationStatus {
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

public extension Util {
    /// 保存图片
    static func save(image: UIImage, to album: Album? = nil, displayFailureAlert: Bool = true, completion: @escaping (String?) -> Void) {
        func savingImage() {
            var id: String?
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                id = request.placeholderForCreatedAsset?.localIdentifier
                
                if let album = album, let newAssert = request.placeholderForCreatedAsset {
                    let albumRequest = PHAssetCollectionChangeRequest(for: album.collection, assets: album.assetResult)
                    albumRequest?.addAssets([newAssert] as NSFastEnumeration)
                }
            } completionHandler: { (status, error) in
                DispatchQueue.main.async {
                    if !status, displayFailureAlert {
                        let alertController = UIAlertController(title: "无法保存照片", message: error?.localizedDescription, preferredStyle: .alert).then {
                            $0.addAction(UIAlertAction(title: "知道了", style: .cancel))
                        }
                        Util.topController?.present(alertController, animated: true)
                    }
                    completion(id)
                }
            }
        }
        
        requestAlbumAuthorization { status in
            guard case .authorized = status else {
                let alertController = UIAlertController(title: "无法保存", message: "请在设置中，允许App访问【所有照片】", preferredStyle: .alert).then {
                    $0.addAction(UIAlertAction(title: "取消", style: .cancel))
                    $0.addAction(UIAlertAction(title: "去设置", style: .default, handler: { _ in
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        guard UIApplication.shared.canOpenURL(url) else { return }
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }))
                }
                Util.topController?.present(alertController, animated: true)
                return
            }
            
            // 保存图片
            savingImage()
        }
    }
}
