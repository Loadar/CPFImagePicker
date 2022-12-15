
import UIKit
import CPFUIKit
import Photos

public struct Router {
    /// 展示照片选择器
    /// - Parameters:
    ///   - navigationController: 目标导航栏控制器，若指定，则使用push方式展示，否则使用modal方式展示
    ///   - authorizing: 相册授权回调，由调用者根据情况处理
    ///   - configure: 配置
    ///   - completion: 完成回调
    public static func showImagePicker(
        to navigationController: UINavigationController?,
        authorizing: @escaping (PHAuthorizationStatus) -> Void,
        configure: (inout Config) -> Void,
        completion: @escaping (Data) -> Void
    ) {
        var config = Config()
        configure(&config)
        if let navigationController = navigationController {
            config.appearance.displaySystemNavigationBar = !navigationController.isNavigationBarHidden
        }
        
        let data = DataManager.shared.newData(of: config)
        showImagePicker(to: navigationController, with: data, authorizing: authorizing, completion: completion)
    }

    /// 展示照片选择器
    /// - Parameters:
    ///   - navigationController: 目标导航栏控制器，若指定，则使用push方式展示，否则使用modal方式展示
    ///   - data: 状态数据
    ///   - authorizing: 相册授权回调，由调用者根据情况处理
    ///   - configure: 配置，若不指定，则使用状态数据内的配置
    ///   - completion: 完成回调
    public static func showImagePicker(
        to navigationController: UINavigationController?,
        with data: Data,
        authorizing: @escaping (PHAuthorizationStatus) -> Void,
        configure: ((inout Config) -> Void)? = nil,
        completion: @escaping (Data) -> Void
    ) {
        
        Util.requestAlbumAuthorization { status in
            switch status {
            case .authorized, .limited:
                configure?(&data.config)
                data.saveStatus()
                
                let controller = ImagePickerViewController(data: data, completion: completion)
                if let navigationController = navigationController {
                    // 指定了导航控制器, 使用push方式展示
                    navigationController.pushViewController(controller, animated: true)
                } else {
                    // 未指定导航控制器，使用modal方式展示，且根视图为导航控制器
                    
                    let navigationController = UINavigationController(rootViewController: controller)
                    navigationController.navigationBar.do {
                        $0.barTintColor = .white
                        $0.tintColor = .white
                        $0.barStyle = .default
                        $0.isTranslucent = false
                        $0.setBackgroundImage(UIImage(), for: .default)
                        $0.shadowImage = UIImage()
                        $0.titleTextAttributes = [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.black]
                    }
                    navigationController.modalPresentationStyle = .fullScreen
                    navigationController.isNavigationBarHidden = !data.config.appearance.displaySystemNavigationBar
                 
                    CPFUIKit.Util.topController?.present(navigationController, animated: true)
                }
            default:
                authorizing(status)
                break
            }
        }
        
    }
}
