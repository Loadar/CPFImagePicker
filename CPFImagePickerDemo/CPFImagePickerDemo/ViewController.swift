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
    
    private let pushButton = CPFButton(type: .custom)
    private let pushButtonWithCustomNavigationBar = CPFButton(type: .custom)
    private let presentButton = CPFButton(type: .custom)
    private let presentButtonWithCustomNavigationBar = CPFButton(type: .custom)
    
    private var data: CPFImagePicker.Data?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let stackView = UIStackView(arrangedSubviews: [pushButton, pushButtonWithCustomNavigationBar, presentButton, presentButtonWithCustomNavigationBar]).then {
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
            self.present(controller, animated: true)
        }
        
        if button === pushButton {
            navigationController?.isNavigationBarHidden = false
            
            if let data = self.data {
                CPFImagePicker.Router.showImagePicker(
                    to: self.navigationController,
                    with: data,
                    authorizing: { status in
                        switch status {
                        case .authorized, .limited:
                            break
                        default:
                            showAuthAlert()
                        }
                    },
                    configure: { [weak self] in
                        $0.displaySystemNavigationBar = true
                        $0.photo.maxSelectableCount = 5
                        $0.photo.photoShouldSelect = { [weak self] in
                            guard let self = self else { return false }
                            
                            if $0.fileSize > 1000 * 1024 {
                                let controller = UIAlertController(title: "所选照片超过限制大小", message: nil, preferredStyle: .alert).then {
                                    $0.addAction(UIAlertAction(title: "知道了", style: .cancel))
                                }
                                self.present(controller, animated: true)
                                return false
                            } else {
                                return true
                            }
                        }
                        $0.photo.tryToSelectPhotoBeyondMaxCount = { [weak self] in
                            let controller = UIAlertController(title: "已达到最大可选择图片数目", message: nil, preferredStyle: .alert).then {
                                $0.addAction(UIAlertAction(title: "知道了", style: .cancel))
                            }
                            self?.present(controller, animated: true)
                        }
                    },
                    completion: { _ in
                        
                    }
                )
            } else {
                self.data = CPFImagePicker.Router.showImagePicker(
                    to: self.navigationController,
                    authorizing: { status in
                        switch status {
                        case .authorized, .limited:
                            break
                        default:
                            showAuthAlert()
                        }
                    },
                    configure: { _ in
                        //config.displaySystemNavigationBar = true
                    },
                    completion: { _ in
                        
                    }
                )
            }
        } else if button === pushButtonWithCustomNavigationBar {
            navigationController?.isNavigationBarHidden = true
            if let data = self.data {
                CPFImagePicker.Router.showImagePicker(
                    to: self.navigationController,
                    with: data,
                    authorizing: { status in
                        switch status {
                        case .authorized, .limited:
                            break
                        default:
                            showAuthAlert()
                        }
                    },
                    configure: {
                        $0.displaySystemNavigationBar = false
                        $0.photo.maxSelectableCount = 3
                    },
                    completion: { _ in
                        
                    }
                )
            } else {
                self.data = CPFImagePicker.Router.showImagePicker(
                    to: self.navigationController,
                    authorizing: { status in
                        switch status {
                        case .authorized, .limited:
                            break
                        default:
                            showAuthAlert()
                        }
                    },
                    configure: { _ in
                        //config.displaySystemNavigationBar = false
                    },
                    completion: { _ in
                        
                    }
                )
            }
        } else if button === presentButton {
            let _ = CPFImagePicker.Router.showImagePicker(
                to: nil,
                authorizing: { status in
                    switch status {
                    case .authorized, .limited:
                        break
                    default:
                        showAuthAlert()
                    }
                },
                configure: { config in
                    config.displaySystemNavigationBar = true
                },
                completion: { _ in
                    
                }
            )
        } else if button === presentButtonWithCustomNavigationBar {
            let _ = CPFImagePicker.Router.showImagePicker(
                to: nil,
                authorizing: { status in
                    switch status {
                    case .authorized, .limited:
                        break
                    default:
                        showAuthAlert()
                    }
                },
                configure: { config in
                    config.displaySystemNavigationBar = false
                },
                completion: { _ in
                    
                }
            )
        }
    }
}

