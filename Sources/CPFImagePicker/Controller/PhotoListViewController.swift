//
//  PhotoListViewController.swift
//  
//
//  Created by Aaron on 2022/12/13.
//

import UIKit
import PhotosUI

/// 照片列表
open class PhotoListViewController<Cell>: UIViewController,
                                          UICollectionViewDataSource,
                                          UICollectionViewDelegate,
                                          UIImagePickerControllerDelegate,
                                          UINavigationControllerDelegate,
                                          AnyCPFDataObserver
                                          where Cell: UICollectionViewCell & AnyCPFPhotoCell {
    private enum Item {
        /// 照片
        case photo(Photo)
        /// 添加照片
        case add
        /// 拍照
        case takePhoto
    }
    
    /// 列表
    public let collectionView: UICollectionView
    
    /// 数据
    let data: AlbumData
    /// 展示的照片列表
    private var displayItems: [Item] = []
    
    /// 新添加得照片Id
    private var newAddedPhotoId: String?
    
    // MARK: - Lifecylce
    public init(data: AlbumData) {
        self.data = data
        collectionView = .init(frame: .zero, collectionViewLayout: data.config.photo.list.layoutProvider())
        super.init(nibName: nil, bundle: nil)
        configureView()
        
        data.add(self)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Appearance
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadPhotos()
    }
    
    // MARK: - UI
    public func configureView() {
        // views
        view.do {
            $0.addSubview(collectionView)
        }
        
        // layouts
        view.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView.do {
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: view.leftAnchor),
                $0.rightAnchor.constraint(equalTo: view.rightAnchor),
                $0.topAnchor.constraint(equalTo: view.topAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
            view.addConstraints(constraints)
        }
        
        // attributes
        collectionView.do {
            $0.contentInsetAdjustmentBehavior = .never
            $0.backgroundColor = Util.color(with: 0xf5f5f5)
            
            $0.register(Cell.self, forCellWithReuseIdentifier: String(describing: Cell.self))
            $0.register(AddPhotoCell.self, forCellWithReuseIdentifier: String(describing: AddPhotoCell.self))
            $0.register(TakePhotoCell.self, forCellWithReuseIdentifier: String(describing: TakePhotoCell.self))

            $0.dataSource = self
            $0.delegate = self
        }
    }
    
    // MARK: - UICollectionViewDataSource & UICollectionViewDelegate
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayItems.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier: String
        switch item(at: indexPath) {
        case .add:
            identifier = String(describing: AddPhotoCell.self)
        case .takePhoto:
            identifier = String(describing: TakePhotoCell.self)
        case .photo, nil:
            identifier = String(describing: Cell.self)
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        if let photoCell = cell as? Cell, let photo = self.photo(at: indexPath) {
            photoCell.update(config: data.config.photo.cell)
            
            var selectedIndex = -1
            if let index = data.selectedIndex(of: photo) {
                selectedIndex = index
            }
            photoCell.updateData(photo, isSelected: selectedIndex >= 0, selectedIndex: selectedIndex, selectable: data.morePhotosCanBeSelected)
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = self.item(at: indexPath) else { return }
        
        switch item {
        case .photo(let photo):
            if data.isSelected(of: photo) {
                data.remove(photo: photo)
            } else {
                if let photoShouldSelect = data.config.photo.photoShouldSelect, !photoShouldSelect(photo) {
                    return
                }
                if data.selectedPhotos.count >= data.config.photo.maxSelectableCount {
                    data.config.photo.tryToSelectPhotoBeyondMaxCount?(data.config)
                } else {
                    data.add(photo: photo)
                }
            }
        case .add:
            if #available(iOS 14, *) {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
            } else {
                // do nothing
            }
        case .takePhoto:
            Util.requestCameraAuthorization { authorized in
                guard authorized else { return }
                
                let controller = UIImagePickerController()
                controller.allowsEditing = false
                controller.sourceType = .camera
                controller.delegate = self
                Util.topController?.present(controller, animated: true, completion: nil)
            }
            break
        }
    }
    
    private func photo(at indexPath: IndexPath) -> Photo? {
        item(at: indexPath).flatMap {
            switch $0 {
            case .photo(let photo): return photo
            case .add, .takePhoto: return nil
            }
        }
    }
    private func item(at indexPath: IndexPath) -> Item? {
        guard (0..<displayItems.endIndex).contains(indexPath.item) else { return nil }
        return displayItems[indexPath.item]
    }
    
    private func reloadPhotos() {
        guard let album = data.album else { return }
        
        let photos = DataManager.shared.photos(of: album, fetchIfNeeded: true)
        var displayItems = photos.map { Item.photo($0) }
        if case .limited = Util.currentAlbumAuthorizationStatus() {
            // 仅允许选择的照片展示时，允许重新添加照片
            displayItems.append(.add)
        }
        
        if data.config.photo.takePhotoEnabled {
            // 允许拍照时，展示拍照选项，这里不校验权限，点击的时候才校验
            // 非智能相册才支持拍照添加照片
            if let album = data.album, album.isCameraRoll || (album.collection.assetCollectionType == .album) {
                displayItems.insert(.takePhoto, at: 0)
            }
        }
        
        self.displayItems = displayItems
        
        if let newAddedPhotoId = newAddedPhotoId {
            self.newAddedPhotoId = nil
            if let photo = photos.first(where: { $0.asset.localIdentifier == newAddedPhotoId }), !data.isSelected(of: photo) {
                if data.selectedPhotos.count >= data.config.photo.maxSelectableCount {
                    data.config.photo.tryToSelectPhotoBeyondMaxCount?(data.config)
                } else {
                    data.add(photo: photo)
                }
            }
        }
        
        self.collectionView.reloadData()
    }
    
    // MARK: - UIImagePickerControllerDelegate
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
            
            let album: Album?
            if let item = self.data.album, !item.isCameraRoll {
                album = item
            } else {
                album = nil
            }
            Util.save(image: image, to: album) { [weak self] id in
                guard let id = id, !id.isEmpty else { return }
                self?.newAddedPhotoId = id
            }
        })
    }
    
    // MARK: - AnyCPFDataObserver
    public func selectedAlbumDidChanged() {
        reloadPhotos()
    }
    
    public func selectedPhotosDidChanged() {
        collectionView.reloadData()
    }
}
