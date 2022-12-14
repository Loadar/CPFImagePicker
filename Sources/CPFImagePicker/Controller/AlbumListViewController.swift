//
//  AlbumListViewController.swift
//  
//
//  Created by Aaron on 2022/12/9.
//

import UIKit

/// 相册列表
open class AlbumListViewController<Cell: UITableViewCell & AnyCPFAlbumCell>: UIViewController, UITableViewDataSource, UITableViewDelegate, AnyCPFDataObserver, AnyCPFImagePickerObserver {
    /// 背景
    public let backgroundView = UIControl()
    /// 列表
    public let tableView = UITableView(frame: .zero, style: .plain)
    
    /// 数据
    private let data: Data
    /// 配置
    private var config: Config { data.config }
    /// 完成回调
    private let completion: (Album?) -> Void
    
    /// 内容高度
    private var contentHeight: CGFloat {
        let config = self.config.albumList
        let count = DataManager.shared.albums.count
        var height = config.cellHeight * CGFloat(count)
        height += config.contentInset.top
        height += config.contentInset.bottom
        
        if height > config.maxContentHeight {
            height = config.maxContentHeight
        }
        return height
    }
    
    // MARK: - Lifecycle
    public init(data: Data, completion: @escaping (Album?) -> Void) {
        self.data = data
        self.completion = completion
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
        
        // 加载数据
        let _ = DataManager.shared.refreshAlbumDataIfNeeded()
        
        configureView()
    }
    
    // MARK: - UI
    open func configureView() {
        // views
        view.do {
            $0.addSubview(backgroundView)
            $0.addSubview(tableView)
        }
        
        // layouts
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        backgroundView.do {
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: view.leftAnchor),
                $0.rightAnchor.constraint(equalTo: view.rightAnchor),
                $0.topAnchor.constraint(equalTo: view.topAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
            view.addConstraints(constraints)
        }
        tableView.do {
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: view.leftAnchor),
                $0.rightAnchor.constraint(equalTo: view.rightAnchor),
                $0.topAnchor.constraint(equalTo: view.topAnchor),
                $0.heightAnchor.constraint(equalToConstant: contentHeight)
            ]
            view.addConstraints(constraints)
        }

        // attributes
        backgroundView.do {
            $0.backgroundColor = config.albumList.backgroundColor
            $0.addTarget(self, action: #selector(backgroundTapped), for: .touchUpInside)
        }
        tableView.do {
            $0.contentInsetAdjustmentBehavior = .never
            $0.backgroundColor = .white
            $0.tableFooterView = UIView()
            $0.separatorStyle = .none
            $0.contentInset = config.albumList.contentInset
            $0.contentOffset.y = config.albumList.contentInset.top * -1
            
            $0.register(Cell.self, forCellReuseIdentifier: String(describing: Cell.self))
            $0.dataSource = self
            $0.delegate = self
        }
     
        // line
        UIView().do {
            view.addSubview($0)
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: view.leftAnchor),
                $0.rightAnchor.constraint(equalTo: view.rightAnchor),
                $0.topAnchor.constraint(equalTo: view.topAnchor),
                $0.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale)
            ]
            view.addConstraints(constraints)
            
            $0.isUserInteractionEnabled = false
            $0.backgroundColor = Util.color(with: 0x979797)
        }
    }
    
    // MARK: - Actions
    @objc private func backgroundTapped() {
        backgroundView.cpfThrottler().run { [weak self] in
            guard let self = self else { return }
            self.dismiss(with: nil)
        }
    }
    
    // MARK: - UITableViewDataSource & UITableViewDelegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        DataManager.shared.albums.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        config.albumList.cellHeight
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: Cell.self), for: indexPath)
        if let albumCell = cell as? Cell {
            if let album = DataManager.shared.album(at: indexPath.item) {
                albumCell.updateData(album, hasSelectedPhoto: data.anySelectedPhoto(in: album))
            } else {
                assert(false, "异常的索引或数据")
            }
        } else {
            assert(false, "异常的Cell")
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let album = DataManager.shared.album(at: indexPath.item) else {
            assert(false, "数据异常")
            return
        }

        dismiss(with: album)
    }
    
    // MARK: - AnyCPFDataObserver
    public func selectedAlbumDidChanged() {
        tableView.reloadData()
    }
    
    public func selectedPhotosDidChanged() {
        tableView.reloadData()
    }
    
    // MARK: - AnyCPFImagePickerObserver
    func albumListDidChanged() {
        tableView.reloadData()
    }
    
    // MARK: - Animation
    public static func show(to controller: UIViewController, destination view: UIView, data: Data, completion: @escaping (Album?) -> Void) -> AlbumListViewController<Cell> {
        let listController = AlbumListViewController(data: data, completion: completion)
        controller.addChild(listController)
        view.addSubview(listController.view)
        listController.view.frame = view.bounds
        
        listController.showing()
        
        return listController
    }
    
    func showing() {
        self.view.isHidden = false
        backgroundView.alpha = 0
        tableView.transform = CGAffineTransform(translationX: 0, y: contentHeight * -1)
        UIView.animate(
            withDuration: config.albumList.animationTimeInterval,
            delay: 0,
            options: .curveEaseOut,
            animations: { [weak self] in
                guard let self = self else { return }
                self.tableView.transform = .identity
                self.backgroundView.alpha = 1
            },
            completion: { _ in
                
            }
        )
    }
    
    public func dismiss(with album: Album?) {
        completion(album)
        UIView.animate(
            withDuration: config.albumList.animationTimeInterval,
            delay: 0,
            options: .curveEaseOut,
            animations: { [weak self] in
                guard let self = self else { return }
                self.tableView.transform = CGAffineTransform(translationX: 0, y: self.contentHeight * -1)
                self.backgroundView.alpha = 0
            },
            completion: { [weak self] _ in
                self?.view.isHidden = true
            }
        )
    }

}