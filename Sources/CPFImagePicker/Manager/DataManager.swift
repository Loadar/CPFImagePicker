//
//  DataManager.swift
//  
//
//  Created by Aaron on 2022/12/9.
//

import Foundation
import Photos

/// 数据管理
final class DataManager: NSObject {
    static let shared = DataManager()
    private override init() {
        super.init()
        
        PHPhotoLibrary.shared().register(self)
    }
    
    /// 相册列表
    private(set) var albums = [Album]() {
        didSet {
            self.photoInfo.removeAll()
            
            observers
                .compactMap { $0.weakObject as? AnyCPFImagePickerObserver }
                .forEach { $0.albumListDidChanged() }
        }
    }
    /// 相册待刷新
    private var albumRequiredRefresh = true
    
    /// 照片信息
    private var photoInfo: [Album: [Photo]] = [:]
    
    /// 展示的数据
    private var displayDatas = [WeakBox<Data>]()
    
    /// 观察者
    private var observers: [WeakBox<AnyObject>] = []
}

extension DataManager {
    /// 指定索引相册
    func album(at index: Int) -> Album? {
        guard (0..<albums.count).contains(index) else { return nil }
        return albums[index]
    }
    
    /// 刷新相册数据
    @discardableResult
    func refreshAlbumDataIfNeeded() -> Bool {
        guard albumRequiredRefresh else { return false }
        albumRequiredRefresh = false
        
        Util.requestAlbumAuthorization { status in
            switch status {
            case .authorized, .limited:
                Util.fetchAlbums { [weak self] list in
                    guard let self = self else { return }
                    self.albums = list
                }
            default:
                break
            }
        }
        
        return true
    }
}

extension DataManager {
    func photos(of album: Album, fetchIfNeeded: Bool) -> [Photo] {
        if let photos = photoInfo[album] {
            return photos
        }
        
        guard fetchIfNeeded else { return [] }
        
        let assets = Util.assets(of: album.collection, onlyImages: true)
        let photos = assets.compactMap {
            Photo(asset: $0)
        }
        photoInfo[album] = photos
        observers
            .compactMap { $0.weakObject as? AnyCPFImagePickerObserver }
            .forEach { $0.photoListDidChanged(of: album) }

        return photos
    }
}

extension DataManager {
    /// 生成新数据
    func newData(of config: Config) -> Data {
        let data = Data(config: config)
        self.displayDatas.append(WeakBox(data))
        return data
    }
    
    /// 移除指定数据
    func removeData(_ data: Data) {
        compactData()
        displayDatas.removeAll(where: { $0.weakObject === data })
    }
    
    /// 移除不存在的数据
    func compactData() {
        displayDatas.removeAll(where: { $0.weakObject == nil })
    }
}

extension DataManager {
    /// 添加观察者
    func addObserver<T: AnyCPFImagePickerObserver>(_ observer: T) {
        compactObservers()
        if !observers.contains(where: { $0.weakObject === observer }) {
            observers.append(WeakBox(observer))
        }
    }
    
    /// 移除观察者
    func removeObserver<T: AnyCPFImagePickerObserver>(_ observer: T) {
        observers.removeAll(where: { $0.weakObject === observer || $0.weakObject == nil })
    }
    
    /// 重整观察者列表，移除无效的
    private func compactObservers() {
        observers.removeAll(where: { $0.weakObject == nil })
    }
}

extension DataManager: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.albumRequiredRefresh = true
            self.photoInfo.removeAll()
            self.compactData()
            
            if !self.displayDatas.isEmpty {
                self.refreshAlbumDataIfNeeded()
            }
        }
    }
}
