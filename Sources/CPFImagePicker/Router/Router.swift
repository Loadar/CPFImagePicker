
import UIKit
import CPFUIKit
import Photos

public struct Router {
    /// 展示照片选择器
    /// - Parameters:
    ///   - data: 状态数据，默认为nil
    ///   - authorizing: 相册授权回调，由调用者根据情况处理
    ///   - configure: 配置，若不指定，则使用状态数据内的配置
    ///   - completion: 完成回调
    public static func showImagePicker(
        with data: Data? = nil,
        authorizing: @escaping (PHAuthorizationStatus) -> Void,
        configure: ((inout Config) -> Void)? = nil,
        completion: @escaping (Data?, ImagePickerViewController?) -> Void
    ) {
        Util.requestAlbumAuthorization { status in
            switch status {
            case .authorized, .limited:
                
                let finalData: Data
                if let data = data {
                    finalData = data
                } else {
                    finalData = DataManager.shared.newData(of: Config())
                }
                configure?(&finalData.config)
                
                let navigationController = CPFUIKit.Util.topController(findChild: true)?.navigationController
                switch finalData.config.preferNavigateMode {
                case .push:
                    if let theNavigationController = navigationController {
                        finalData.config.appearance.displaySystemNavigationBar = !theNavigationController.isNavigationBarHidden
                        finalData.config.displayNavigateMode = .push
                    } else {
                        finalData.config.displayNavigateMode = .modal
                    }
                case .modal:
                    finalData.config.displayNavigateMode = .modal
                }

                finalData.saveStatus()
                
                displayPicker(with: finalData, navigationController: navigationController, completion: completion)
            default:
                authorizing(status)
                break
            }
        }
    }
    
    private static func displayPicker(with data: Data, navigationController: UINavigationController?, completion: @escaping (Data?, ImagePickerViewController?) -> Void) {
        let controller = ImagePickerViewController(data: data, completion: completion)
        switch data.config.displayNavigateMode {
        case .push:
            navigationController?.pushViewController(controller, animated: true)
        case .modal:
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
         
            CPFUIKit.Util.topController()?.present(navigationController, animated: true)
        }
    }
}
