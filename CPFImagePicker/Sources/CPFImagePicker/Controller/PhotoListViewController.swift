//
//  PhotoListViewController.swift
//  
//
//  Created by Aaron on 2022/12/13.
//

import UIKit
import PhotosUI

/// 照片列表
open class PhotoListViewController<Cell: UICollectionViewCell & AnyCPFPhotoCell>: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, AnyCPFDataObserver {
    private enum Item {
        /// 照片
        case photo(Photo)
        /// 添加照片
        case add
    }
    
    /// 列表
    public let collectionView: UICollectionView
    
    /// 数据
    let data: Data
    /// 展示的照片列表
    private var displayItems: [Item] = []
    
    // MARK: - Lifecylce
    public init(data: Data) {
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
        case .photo, nil:
            identifier = String(describing: Cell.self)
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        if let photoCell = cell as? Cell, let photo = self.photo(at: indexPath) {
            photoCell.update(config: data.config.photo.cell)
            photoCell.updateData(photo, isSelected: data.isSelected(of: photo), selectable: data.morePhotosCanBeSelected)
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
                    data.config.photo.tryToSelectPhotoBeyondMaxCount?()
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
        }
    }
    
    private func photo(at indexPath: IndexPath) -> Photo? {
        item(at: indexPath).flatMap {
            switch $0 {
            case .photo(let photo): return photo
            case .add: return nil
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
            displayItems.append(.add)
        }
        
        self.displayItems = displayItems
        
        self.collectionView.reloadData()
    }
    
    // MARK: - AnyCPFDataObserver
    public func selectedAlbumDidChanged() {
        reloadPhotos()
    }
    
    public func selectedPhotosDidChanged() {
        collectionView.reloadData()
    }
}
