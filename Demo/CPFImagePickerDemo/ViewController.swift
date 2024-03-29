//
//  ViewController.swift
//  CPFImagePickerDemo
//
//  Created by Aaron on 2022/12/7.
//

import UIKit
import CPFImagePicker
import Then
import CPFUIKit

class ViewController: UIViewController {
    
    private let pushButton = Button(type: .custom)
    private let pushButtonWithCustomNavigationBar = Button(type: .custom)
    private let presentButton = Button(type: .custom)
    private let presentButtonWithCustomNavigationBar = Button(type: .custom)
    private let takePhotoButton = Button(type: .custom)

    
    private var data: CPFImagePicker.AlbumData?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let stackView = UIStackView(arrangedSubviews: [pushButton, pushButtonWithCustomNavigationBar, presentButton, presentButtonWithCustomNavigationBar, takePhotoButton]).then {
            $0.axis = .vertical
            $0.alignment = .fill
            $0.distribution = .fillEqually
            $0.spacing = 20
        }
        view.addSubview(stackView)
        
        stackView.do {
            let constraints: [NSLayoutConstraint] = [
                $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
                $0.heightAnchor.constraint(equalToConstant: 300),
                $0.widthAnchor.constraint(equalToConstant: 180),
                $0.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ]
            view.addConstraints(constraints)
        }
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.arrangedSubviews
            .compactMap({ $0 as? UIButton})
            .forEach {
                $0.backgroundColor = .lightGray.withAlphaComponent(0.2)
                $0.layer.cornerRadius = 8
                $0.layer.masksToBounds = true
                
                $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
                $0.setTitleColor(.purple, for: .normal)
                
                $0.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            }
        
        pushButton.setTitle("Push", for: .normal)
        pushButtonWithCustomNavigationBar.setTitle("Push(自定义导航栏)", for: .normal)
        presentButton.setTitle("Present", for: .normal)
        presentButtonWithCustomNavigationBar.setTitle("Present(自定义导航栏)", for: .normal)
        takePhotoButton.setTitle("拍照", for: .normal)
    }
    
    @objc private func buttonTapped(_ button: UIButton) {
        func showAuthAlert() {
            let albumAuthorizationTitle: String = {
                if #available(iOS 14, *) {
                    return "所有照片"
                } else {
                    return "照片"
                }
            }()
            
            let controller = UIAlertController(
                title: "无相册访问权限",
                message: "请在\"设置-xxx-照片\"中，允许xxx访问【\(albumAuthorizationTitle)】",
                preferredStyle: .alert
            ).then {
                $0.addAction(UIAlertAction(title: "取消", style: .cancel))
                $0.addAction(UIAlertAction(title: "去设置", style: .default, handler: { _ in
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    guard UIApplication.shared.canOpenURL(url) else { return }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }))
            }
            Util.topController?.present(controller, animated: true)
        }
        
        if button === pushButton {
            navigationController?.isNavigationBarHidden = false
            
            if let data = self.data {
                CPFImagePicker.Router.showImagePicker(
                    with: data,
                    controller: CustomImagePickerViewController.self,
                    authorizing: { status in
                        switch status {
                        case .authorized, .limited:
                            break
                        default:
                            showAuthAlert()
                        }
                    },
                    configure: {
                        $0.appearance.displaySystemNavigationBar = true
                        $0.appearance.animatedWhenCompleted = false
                        $0.dismissWhenCompleted = true
                        $0.photo.maxSelectableCount = 5
                        $0.photo.photoShouldSelect = {
                            if $0.fileSize > 1000 * 1024 {
                                let controller = UIAlertController(title: "所选照片超过限制大小", message: nil, preferredStyle: .alert).then {
                                    $0.addAction(UIAlertAction(title: "知道了", style: .cancel))
                                }
                                Util.topController?.present(controller, animated: true)
                                return false
                            } else {
                                return true
                            }
                        }
                        $0.photo.tryToSelectPhotoBeyondMaxCount = { _ in
                            let controller = UIAlertController(title: "已达到最大可选择图片数目", message: nil, preferredStyle: .alert).then {
                                $0.addAction(UIAlertAction(title: "知道了", style: .cancel))
                            }
                            Util.topController?.present(controller, animated: true)
                        }
                        $0.photo.cell.displaySelectedIconIndex = Int.random(in: 0..<10) % 2 == 0
                    },
                    completion: { _, _ in
                        
                    }
                )
            } else {
                CPFImagePicker.Router.showImagePicker(
                    controller: CustomImagePickerViewController.self,
                    authorizing: { status in
                        switch status {
                        case .authorized, .limited:
                            break
                        default:
                            showAuthAlert()
                        }
                    },
                    configure: { config in
                        config.dismissWhenCompleted = false
                        config.preferNavigateMode = .modal
                        
                        //config.displaySystemNavigationBar = true
                        
                        config.photo.maxSelectableCount = 20
                        config.photo.cell.displaySelectedIconIndex = true
                    },
                    completion: { [weak self] data, picker in
                        guard let self = self else { return }
                        guard let data = data else { return }
                        if self.data !== data {
                            self.data = data
                        }
                        
                        func showDetail() {
                            let testController = UIViewController().then {
                                $0.view.backgroundColor = .green
                            }
                            if let navigationController = picker?.navigationController, case .push = data.config.displayNavigateMode {
                                var controllers = navigationController.viewControllers
                                controllers.removeLast()
                                controllers.append(testController)
                                navigationController.setViewControllers(controllers, animated: true)
                            } else {
                                Util.topController?.present(testController, animated: true)
                            }
                        }
                        
                        if !data.config.dismissWhenCompleted {
                            picker?.dismissPicker(animated: true, completion: {
                                showDetail()
                            })
                        } else {
                            showDetail()
                        }
                        
                    }
                )
            }
        } else if button === pushButtonWithCustomNavigationBar {
            navigationController?.isNavigationBarHidden = true
            if let data = self.data {
                CPFImagePicker.Router.showImagePicker(
                    with: data,
                    controller: ImagePickerViewController.self,
                    authorizing: { status in
                        switch status {
                        case .authorized, .limited:
                            break
                        default:
                            showAuthAlert()
                        }
                    },
                    configure: {
                        $0.appearance.displaySystemNavigationBar = false
                        $0.photo.maxSelectableCount = 3
                        //$0.photo.takePhotoEnabled = false
                    },
                    completion: { _, _ in
                        
                    }
                )
            } else {
                CPFImagePicker.Router.showImagePicker(
                    controller: ImagePickerViewController.self,
                    authorizing: { status in
                        switch status {
                        case .authorized, .limited:
                            break
                        default:
                            showAuthAlert()
                        }
                    },
                    configure: {
                        //config.displaySystemNavigationBar = false
                        $0.photo.takePhotoEnabled = false
                    },
                    completion: { [weak self] data, _ in
                        guard let data = data else { return }
                        self?.data = data
                    }
                )
            }
        } else if button === presentButton {
            let _ = CPFImagePicker.Router.showImagePicker(
                controller: ImagePickerViewController.self,
                authorizing: { status in
                    switch status {
                    case .authorized, .limited:
                        break
                    default:
                        showAuthAlert()
                    }
                },
                configure: { config in
                    config.appearance.displaySystemNavigationBar = true
                    config.preferNavigateMode = .modal
                },
                completion: { _, _ in
                    
                }
            )
        } else if button === presentButtonWithCustomNavigationBar {
            let _ = CPFImagePicker.Router.showImagePicker(
                controller: ImagePickerViewController.self,
                authorizing: { status in
                    switch status {
                    case .authorized, .limited:
                        break
                    default:
                        showAuthAlert()
                    }
                },
                configure: { config in
                    config.appearance.displaySystemNavigationBar = false
                    config.preferNavigateMode = .modal
                },
                completion: { _, _ in
                    
                }
            )
        } else if button === takePhotoButton {
            Util.requestCameraAuthorization { status in
                guard status else { return }
                
                let controller = UIImagePickerController()
                controller.allowsEditing = false
                controller.sourceType = .camera
                controller.delegate = self
                Util.topController?.present(controller, animated: true, completion: nil)
            }
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            let alertController = UIAlertController(title: "拍照失败", message: nil, preferredStyle: .alert).then {
                $0.addAction(UIAlertAction(title: "知道了", style: .cancel))
            }
            Util.topController?.present(alertController, animated: true)
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        picker.dismiss(animated: true, completion: { [weak self] in
            guard let self = self else { return }
            
            CPFImagePicker.Router.showImagePicker(
                controller: CustomImagePickerViewController.self,
                photoTaken: image,
                authorizing: { status in
                    switch status {
                    case .authorized, .limited:
                        break
                    default:
                        //showAuthAlert()
                        break
                    }
                },
                configure: { config in
                    config.dismissWhenCompleted = false
                    config.preferNavigateMode = .modal
                    
                    //config.displaySystemNavigationBar = true
                    
                    config.photo.maxSelectableCount = 20
                    config.photo.cell.displaySelectedIconIndex = true
                },
                completion: { [weak self] data, picker in
                    guard let self = self else { return }
                    guard let data = data else { return }
                    if self.data !== data {
                        self.data = data
                    }
                    
                    func showDetail() {
                        let testController = UIViewController().then {
                            $0.view.backgroundColor = .green
                        }
                        if let navigationController = picker?.navigationController, case .push = data.config.displayNavigateMode {
                            var controllers = navigationController.viewControllers
                            controllers.removeLast()
                            controllers.append(testController)
                            navigationController.setViewControllers(controllers, animated: true)
                        } else {
                            Util.topController?.present(testController, animated: true)
                        }
                    }
                    
                    if !data.config.dismissWhenCompleted {
                        picker?.dismissPicker(animated: true, completion: {
                            showDetail()
                        })
                    } else {
                        showDetail()
                    }
                }
            )
        })
    }
}
