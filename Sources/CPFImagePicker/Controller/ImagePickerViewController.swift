//
//  ImagePickerViewController.swift
//  
//
//  Created by Aaron on 2022/12/12.
//

import UIKit

/// 图片选择器
open class ImagePickerViewController: UIViewController, AnyCPFDataObserver, AnyCPFImagePickerObserver, AnyCPFImagePickerViewController {
    /// 导航栏
    public let navigationView: NavigationView
    /// 内容
    public let contentView = UIView()
    
    public let data: AlbumData
    
    /// 相册
    public private(set) var albumController: AlbumListViewController<AlbumCell>?
    /// 照片
    public let photoController: PhotoListViewController<PhotoCell>
    
    /// 完成回调
    public var completion: ((AlbumData?, Bool) -> Void)?
    
    // MARK: - Lifecycle
    public required init(data: AlbumData) {
        self.data = data
        navigationView = .init(config: data.config)
        photoController = .init(data: data)
        super.init(nibName: nil, bundle: nil)
        data.add(self)
        DataManager.shared.addObserver(self)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Appearance
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        
        
        if !DataManager.shared.refreshAlbumDataIfNeeded() {
            albumListDidChanged()
        }
    }
    
    // MARK: - UI
    open func configureView() {
        // views
        addChild(photoController)
        view.do {
            $0.addSubview(contentView)
            
            if data.config.appearance.displaySystemNavigationBar {
                navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationView.backButton)
                navigationItem.titleView = navigationView.titleButton
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationView.nextButton)
            }
            $0.addSubview(navigationView)
        }
        contentView.do {
            $0.addSubview(photoController.view)
        }
        
        // layouts
        navigationView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        navigationView.do {
            var constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: view.leftAnchor),
                $0.rightAnchor.constraint(equalTo: view.rightAnchor)
            ]
            if data.config.appearance.displaySystemNavigationBar {
                constraints.append($0.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
            } else {
                constraints.append($0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
            }
            view.addConstraints(constraints)
        }
        contentView.do {
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: view.leftAnchor),
                $0.rightAnchor.constraint(equalTo: view.rightAnchor),
                $0.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
            view.addConstraints(constraints)
        }
        photoController.view.do {
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                $0.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                $0.topAnchor.constraint(equalTo: contentView.topAnchor),
                $0.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ]
            contentView.addConstraints(constraints)
        }
        
        // attributes
        navigationView.do {
            $0.backgroundColor = .white
            $0.isHidden = data.config.appearance.displaySystemNavigationBar
        }
        if !data.config.appearance.displaySystemNavigationBar {
            let backgroundView = UIView()
            view.insertSubview(backgroundView, belowSubview: navigationView)
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.do {
                let constraints: [NSLayoutConstraint] = [
                    $0.leftAnchor.constraint(equalTo: view.leftAnchor),
                    $0.rightAnchor.constraint(equalTo: view.rightAnchor),
                    $0.topAnchor.constraint(equalTo: view.topAnchor),
                    $0.bottomAnchor.constraint(equalTo: navigationView.bottomAnchor)
                ]
                view.addConstraints(constraints)
            }
            backgroundView.backgroundColor = .white
        }
        contentView.do {
            $0.backgroundColor = .white
            $0.clipsToBounds = true
        }
        
        // others
        configureActions()
        updateTitle()
        navigationView.updateNextButton(with: data.selectedPhotos.count)
    }
    
    /// 配置事件
    open func configureActions() {
        // 返回
        navigationView.backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        // 标题点击
        navigationView.titleButton.addTarget(self, action: #selector(titleTapped), for: .touchUpInside)
        // 下一步
        navigationView.nextButton.addTarget(self, action: #selector(nextAction), for: .touchUpInside)
    }
    
    @objc private func back() {
        navigationView.backButton.cpfThrottler().run { [weak self] in
            guard let self = self else { return }
            self.dismiss(with: false)
        }
    }
    
    public func dismiss(with status: Bool) {
        if status {
            data.saveChanges()
        } else {
            data.restoreStatus()
        }
        
        let completion = self.completion
        let config = self.data.config
        let data: AlbumData? = status ? self.data : nil
        if status, !config.dismissWhenCompleted {
            completion?(data, true)
            return
        }
        
        let animated = status ? config.appearance.animatedWhenCompleted : true
        if let navigationController = self.navigationController, navigationController.viewControllers.first !== self {
            self.navigationController?.popViewController(animated: animated)
            // 注意：导航栏的动画结束时机需要用delegate来处理，太过于麻烦，这里直接做个延时，如果涉及到自定义转场动画等，需要调整
            let delayDuration = animated ? 0.35 : 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delayDuration) {
                completion?(data, false)
            }
        } else {
            self.presentingViewController?.dismiss(animated: animated, completion: {
                completion?(data, false)
            })
        }
    }
    
    /// 收起界面，不触发完成回调
    public func dismissPicker(animated: Bool = true, completion: (() -> Void)?) {
        guard !data.config.dismissWhenCompleted else {
            assert(false, "自动收起界面开启时不支持手动调用")
            return
        }
        
        if let navigationController = self.navigationController, navigationController.viewControllers.first !== self {
            self.navigationController?.popViewController(animated: animated)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                completion?()
            }
        } else {
            self.presentingViewController?.dismiss(animated: animated, completion: completion)
        }
    }
    
    @objc private func titleTapped() {
        navigationView.titleButton.cpfThrottler().run { [weak self] in
            guard let self = self else { return }
            if !self.navigationView.titleButton.isSelected {
                self.navigationView.titleButton.isSelected.toggle()
                self.navigationView.updateNextButton(with: self.data.selectedPhotos.count, enabled: false)
                UIView.animate(withDuration: self.data.config.album.animationTimeInterval, delay: 0, options: .curveEaseOut, animations: {
                    if self.navigationView.titleButton.isSelected {
                        self.navigationView.titleButton.imageView?.transform = CGAffineTransform(rotationAngle: .pi)
                    } else {
                        self.navigationView.titleButton.imageView?.transform = .identity
                    }
                })

                if let controller = self.albumController {
                    controller.showing()
                } else {
                    self.albumController = AlbumListViewController<AlbumCell>.show(to: self, destination: self.contentView, data: self.data) { [weak self] newAlbum in
                        guard let self = self else { return }
                        self.navigationView.titleButton.isSelected.toggle()
                        self.navigationView.updateNextButton(with: self.data.selectedPhotos.count, enabled: true)
                        UIView.animate(withDuration: self.data.config.album.animationTimeInterval, delay: 0, options: .curveEaseOut, animations: {
                            if self.navigationView.titleButton.isSelected {
                                self.navigationView.titleButton.imageView?.transform = CGAffineTransform(rotationAngle: .pi)
                            } else {
                                self.navigationView.titleButton.imageView?.transform = .identity
                            }
                        })
                        
                        guard let newAlbum = newAlbum, newAlbum != self.data.album else { return }
                        self.data.album = newAlbum
                    }
                }
                
            } else {
                self.albumController?.dismiss(with: nil)
            }
        }
    }
    
    @objc private func nextAction() {
        navigationView.nextButton.cpfThrottler().run { [weak self] in
            guard let self = self else { return }
            self.dismiss(with: true)
        }
    }
    
    // MARK: - Update
    private func updateTitle() {
        if let theAlbum = data.album {
            navigationView.titleButton.setTitle(theAlbum.name, for: .normal)
            navigationView.titleButton.isHidden = false
        } else {
            navigationView.titleButton.isHidden = true
        }
    }
    
    // MARK: - AnyCPFDataObserver
    open func selectedAlbumDidChanged() {
        updateTitle()
    }
    
    open func selectedPhotosDidChanged() {
        navigationView.updateNextButton(with: data.selectedPhotos.count)
    }
    
    // MARK: - AnyCPFImagePickerObserver
    func albumListDidChanged() {
        let albums = DataManager.shared.albums
        
        // 当前未选中相册或已选中相册不存在时，默认选中第一个相册
        if let album = data.album, let theAlbum = albums.first(where: { $0 == album }) {
            // 注意：需要赋新的值来刷新照片列表
            data.album = theAlbum
            return
        }
        
        if let firstAlbum = DataManager.shared.albums.first {
            data.album = firstAlbum
        } else {
            debugPrint("**** 无可用相册 ****")
        }
    }
}

