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
    private(set) var albums = [Album]()
    /// 相册数据已获取
    private(set) var albumFetched = false
    /// 相册数据是否已全部获取
    private(set) var allAlbumFetched = false
    /// 相册待刷新
    private var albumRequiredRefresh = true
    
    /// 照片分页大小
    static var photoListPageSize: Int { 100 }
    /// 照片信息
    private var photoInfo: [Album: (page: Int, fetchCompleted: Bool, photos: [Photo])] = [:]
    /// 获取中的照片列表分页信息
    private var photoFetchingPageInfo = [Album: Int]()
    
    /// 展示的数据
    private var displayDatas = [WeakBox<AlbumData>]()
    
    /// 观察者
    private var observers: [WeakBox<AnyObject>] = []
    
    private func updateAlbums(_ albums: [Album], isAll: Bool) {
        self.albums = albums
        photoInfo.removeAll()
        albumFetched = true
        allAlbumFetched = isAll
        
        observers
            .compactMap { $0.weakObject as? AnyCPFImagePickerObserver }
            .forEach { $0.albumListDidChanged() }
    }
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
                Util.fetchAlbums { [weak self] result in
                    guard let self = self else { return }
                    self.updateAlbums(result.albums, isAll: result.isAll)
                }
            default:
                break
            }
        }
        
        return true
    }
}

extension DataManager {
    /// 获取指定相册下的照片列表
    /// - Parameters:
    ///   - album: 相册
    ///   - page: 分页，用于确定是否获取更多数据， 从0开始
    ///   - fetchIfNeeded: 当缓存中无数据时，是否从图片库中获取
    /// - Returns: 返回此相册下已获取的所有照片
    func photos(of album: Album, page: Int, fetchIfNeeded: Bool) -> [Photo]? {
        if fetchIfNeeded {
            let fetchedPage = photoInfo[album]?.page ?? -1
            if fetchedPage + 1 == page, photoFetchingPageInfo[album] == nil {
                photoFetchingPageInfo[album] = page
                Util.assets(of: album, page: page, pageSize: Self.photoListPageSize) { assets in
                    let photos = assets.compactMap {
                        Photo(asset: $0)
                    }
                    
                    var allPhotos = self.photoInfo[album]?.photos ?? []
                    allPhotos.append(contentsOf: photos)
                    self.photoInfo[album] = (page, photos.isEmpty, allPhotos)
                    self.photoFetchingPageInfo[album] = nil
                    self.observers
                        .compactMap { $0.weakObject as? AnyCPFImagePickerObserver }
                        .forEach { $0.photoListDidChanged(of: album) }
                }
            }
        }

        return photoInfo[album]?.photos
    }
    
    func isPhotosFetchedCompleted(of album: Album) -> Bool {
        guard let info = photoInfo[album] else { return false }
        return info.fetchCompleted
    }
    func isPhotosFetched(of album: Album, page: Int) -> Bool {
        guard let info = photoInfo[album] else { return false }
        return info.page >= page
    }
}

extension DataManager {
    /// 生成新数据
    func newData(of config: Config) -> AlbumData {
        let data = AlbumData(config: config)
        self.displayDatas.append(WeakBox(data))
        return data
    }
    
    /// 移除指定数据
    func removeData(_ data: AlbumData) {
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
            self.compactData()
            
            if !self.displayDatas.isEmpty {
                self.refreshAlbumDataIfNeeded()
            }
        }
    }
}
