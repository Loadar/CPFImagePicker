//
//  Util+Camera.swift
//  
//
//  Created by Aaron on 2023/6/7.
//

import UIKit
import AVFoundation

public extension Util {
    /// 请求相机权限
    static func requestCameraAuthorization(completion: @escaping (Bool) -> Void) {
        @discardableResult
        func check(status: AVAuthorizationStatus) -> Bool {
            switch status {
            case .authorized:
                // 已授权
                completion(true)
                return true
            case .denied, .restricted:
                let alertController = UIAlertController(title: "无法打开相机", message: "请在设置中，允许App访问【相机】", preferredStyle: .alert).then {
                    $0.addAction(UIAlertAction(title: "取消", style: .cancel))
                    $0.addAction(UIAlertAction(title: "去设置", style: .default, handler: { _ in
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        guard UIApplication.shared.canOpenURL(url) else { return }
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }))
                }
                Util.topController?.present(alertController, animated: true)

                completion(false)
                return true
            case .notDetermined:
                break
            @unknown default:
                break
            }
            
            return false
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard !check(status: status) else { return }
        
        // 请求权限
        AVCaptureDevice.requestAccess(for: .video) { (status) in
            DispatchQueue.main.async {
                if status {
                    check(status: .authorized)
                } else {
                    check(status: .denied)
                }
            }
        }
    }
}
