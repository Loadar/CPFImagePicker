//
//  PhotoListViewController.swift
//  
//
//  Created by Aaron on 2022/12/13.
//

import UIKit
import PhotosUI
import DeepDiff

/// 照片列表
open class PhotoListViewController<Cell>: UIViewController,
                                          UICollectionViewDataSource,
                                          UICollectionViewDelegate,
                                          UIImagePickerControllerDelegate,
                                          UINavigationControllerDelegate,
                                          AnyCPFDataObserver
                                          where Cell: UICollectionViewCell & AnyCPFPhotoCell {
    private enum Item: Equatable, DiffAware {
        /// 照片
        case photo(Photo)
        /// 添加照片
        case add
        /// 拍照
        case takePhoto
        
        static func ==(lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.add, .add),
                (.takePhoto, .takePhoto):
                return true
            case let (.photo(first), .photo(second)):
                return first == second
            default:
                return false
            }
        }
        
        var diffId: String {
            switch self {
            case .photo(let photo): photo.asset.localIdentifier
            case .add: "add"
            case .takePhoto: "takePhoto"
            }
        }
        
        static func compareContent(_ a: PhotoListViewController<Cell>.Item, _ b: PhotoListViewController<Cell>.Item) -> Bool {
            a == b
        }

    }
    
    /// 列表
    public let collectionView: UICollectionView
    
    /// 数据
    let data: AlbumData
    /// 展示的照片列表
    private var displayItems: [Item] = []
    
    /// 新添加得照片Id
    private var newAddedPhotoId: String?
    /// 照片是否在加载中
    private var reloading = false
    /// 照片是否需要刷新
    private var listRequiredRefresh = false
    
    /// 界面尺寸
    private var viewSize: CGSize = .zero
    
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
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let image = data.photoTaken {
            data.photoTaken = nil
            
            Util.save(image: image, to: nil) { [weak self] id in
                guard let id = id, !id.isEmpty else { return }
                self?.newAddedPhotoId = id
            }
        }
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
            $0.contentInsetAdjustmentBehavior = .automatic
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
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let album = data.album else { return }
        
        let indexPathes = collectionView.indexPathsForVisibleItems.sorted(by: { $0.item < $1.item })
        guard var maxIndex = indexPathes.last?.item else { return }
        
        if displayItems.contains(.add) {
            maxIndex -= 1
        }
        if displayItems.contains(.takePhoto) {
            maxIndex -= 1
        }
        
        let pageSize = DataManager.photoListPageSize
        let page = maxIndex / pageSize
        if maxIndex % pageSize > pageSize / 2,
           !DataManager.shared.isPhotosFetchedCompleted(of: album),
           !DataManager.shared.isPhotosFetched(of: album, page: page + 1) {
            // 超过当前页一半时，获取下一页的数据
            let _ = DataManager.shared.photos(of: album, page: page + 1, fetchIfNeeded: true)
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
    
    func reloadPhotos() {
        guard !reloading else {
            listRequiredRefresh = true
            return
        }
        guard let album = data.album else {
            return
        }
        
        reloading = true
        let oldDisplayItems = displayItems
        
        let photos = DataManager.shared.photos(of: album, page: 0, fetchIfNeeded: true) ?? []
        var displayItems = photos.map { Item.photo($0) }
        
        if self.data.config.photo.takePhotoEnabled {
            // 允许拍照时，展示拍照选项，这里不校验权限，点击的时候才校验
            // 非智能相册才支持拍照添加照片
            if let album = self.data.album, album.isCameraRoll || (album.collection.assetCollectionType == .album) {
                displayItems.insert(.takePhoto, at: 0)
            }
        }
        if case .limited = Util.currentAlbumAuthorizationStatus() {
            // 仅允许选择的照片展示时，允许重新添加照片
            if let index = displayItems.firstIndex(of: .takePhoto) {
                displayItems.insert(.add, at: index + 1)
            } else {
                displayItems.insert(.add, at: 0)
            }
        }
        
        if let newAddedPhotoId = self.newAddedPhotoId {
            if let photo = photos.first(where: { $0.asset.localIdentifier == newAddedPhotoId }), !self.data.isSelected(of: photo) {
                if self.data.selectedPhotos.count >= self.data.config.photo.maxSelectableCount {
                    self.data.config.photo.tryToSelectPhotoBeyondMaxCount?(self.data.config)
                } else {
                    self.data.add(photo: photo)
                }
            }
            
            self.newAddedPhotoId = nil
        }
        
        // 新、旧数据任意为空时，直接reload
        if oldDisplayItems.isEmpty || displayItems.isEmpty {
            self.displayItems = displayItems
            collectionView.reloadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.reloading = false
                if self.listRequiredRefresh {
                    self.listRequiredRefresh = false
                    self.reloadPhotos()
                }
            }
            return
        }
        
        
        // 差异化更新
        let changes = diff(old: oldDisplayItems, new: displayItems)
        collectionView.reload(changes: changes) {
            self.displayItems = displayItems
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.reloading = false

            if self.listRequiredRefresh {
                self.listRequiredRefresh = false
                self.reloadPhotos()
            }
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard viewSize != view.bounds.size else { return }
        viewSize = view.bounds.size
        
        switch UIApplication.shared.applicationState {
        case .active, .inactive:
            break
        case .background:
            return
        @unknown default:
            return
        }
        
        collectionView.collectionViewLayout = data.config.photo.list.layoutProvider()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
        CATransaction.commit()
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
        collectionView.indexPathsForVisibleItems.forEach {
            guard let cell = collectionView.cellForItem(at: $0) as? Cell else { return }
            guard (0..<displayItems.count).contains($0.item) else { return }
            guard case .photo(let photo) = displayItems[$0.item] else { return }
            var selectedIndex = -1
            if let index = data.selectedIndex(of: photo) {
                selectedIndex = index
            }
            cell.update(selectedState: selectedIndex >= 0, selectedIndex: selectedIndex)
        }
    }
}
