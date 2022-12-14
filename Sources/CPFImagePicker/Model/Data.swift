//
//  Data.swift
//  
//
//  Created by Aaron on 2022/12/12.
//

import Foundation

/// 通用数据
public class Data {
    /// 配置
    public internal(set) var config: Config
    /// 选中的照片
    public private(set) var photos = [Photo]()
    
    /// 选中的照片(包含操作中的)
    private(set) var selectedPhotos: [Photo] {
        didSet {
            if selectedPhotos != oldValue {
                observers
                    .compactMap { $0.weakObject as? AnyCPFDataObserver }
                    .forEach { $0.selectedPhotosDidChanged() }
            }
        }
    }
    /// 展示的相册
    var album: Album? {
        didSet {
            observers
                .compactMap { $0.weakObject as? AnyCPFDataObserver }
                .forEach { $0.selectedAlbumDidChanged() }
        }
    }
    
    /// 观察者
    private var observers: [WeakBox<AnyObject>] = []
    
    public init(config: Config) {
        self.config = config
        self.selectedPhotos = []
        self.album = nil
    }
}

extension Data {
    /// 指定相册是否包含任意选中照片
    /// - Parameter album: 待检查的相册
    func anySelectedPhoto(in album: Album) -> Bool {
        selectedPhotos.contains(where: { album.contains($0) })
    }
    
    /// 指定照片是否已选中
    func isSelected(of photo: Photo) -> Bool {
        selectedPhotos.contains(photo)
    }
    
    /// 是否还可以选择更多照片
    var morePhotosCanBeSelected: Bool {
        selectedPhotos.count < config.photo.maxSelectableCount
    }
    
    /// 添加选择的照片
    func add(photo: Photo) {
        guard !isSelected(of: photo) else {
            debugPrint("***** 照片已添加了 *****")
            return
        }
        guard morePhotosCanBeSelected else {
            debugPrint("***** 无法再添加照片了 *****")
            return
        }
        selectedPhotos.append(photo)
    }
    
    /// 移除选择的照片
    func remove(photo: Photo) {
        guard isSelected(of: photo) else {
            debugPrint("***** 照片未添加 *****")
            return
        }
        selectedPhotos.removeAll(where: { $0 == photo })
    }
}

extension Data {
    /// 添加观察者
    func add<T: AnyCPFDataObserver>(_ observer: T) {
        compactObservers()
        if !observers.contains(where: { $0.weakObject === observer }) {
            observers.append(WeakBox(observer))
        }
    }
    
    /// 移除观察者
    func remove<T: AnyCPFDataObserver>(_ observer: T) {
        observers.removeAll(where: { $0.weakObject === observer || $0.weakObject == nil })
    }
    
    /// 重整观察者列表，移除无效的
    private func compactObservers() {
        observers.removeAll(where: { $0.weakObject == nil })
    }
}

extension Data {
    func saveStatus() {
        if selectedPhotos != photos {
            selectedPhotos = photos
        }
    }
    
    func restoreStatus() {
        if selectedPhotos != photos {
            selectedPhotos = photos
        }
    }
    
    func saveChanges() {
        if photos != selectedPhotos {
            photos = selectedPhotos
        }
    }
}
