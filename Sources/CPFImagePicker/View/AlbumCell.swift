//
//  AlbumCell.swift
//  
//
//  Created by Aaron on 2022/12/8.
//

import UIKit

/// 相册Cell
open class AlbumCell: UITableViewCell, AnyCPFAlbumCell {
    /// 缩略图
    public let thumbnailView = UIImageView()
    /// 名称
    public let nameLabel = UILabel()
    /// 照片数目
    public let photoCountLabel = UILabel()
    /// 包含已选图片的标志
    public let photoSelectionMarkView = UIView()
    
    /// 展示的封面照片
    private var displayCoverPhoto: Photo?
    
    // MARK: - Lifecycle
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
    public func configureCell() {
        // views
        contentView.do {
            $0.addSubview(thumbnailView)
            $0.addSubview(nameLabel)
            $0.addSubview(photoCountLabel)
            $0.addSubview(photoSelectionMarkView)
        }
        
        // layouts
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        photoCountLabel.translatesAutoresizingMaskIntoConstraints = false
        photoSelectionMarkView.translatesAutoresizingMaskIntoConstraints = false

        thumbnailView.do {
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 14),
                $0.widthAnchor.constraint(equalToConstant: 54),
                $0.heightAnchor.constraint(equalToConstant: 54),
                $0.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ]
            contentView.addConstraints(constraints)
        }
        nameLabel.do {
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: thumbnailView.rightAnchor, constant: 10),
                $0.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),
                $0.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
                $0.heightAnchor.constraint(equalToConstant: 22)
            ]
            contentView.addConstraints(constraints)
        }
        photoCountLabel.do {
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
                $0.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),
                $0.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
                $0.heightAnchor.constraint(equalToConstant: 20)
            ]
            contentView.addConstraints(constraints)
        }
        photoSelectionMarkView.do {
            let constraints: [NSLayoutConstraint] = [
                $0.topAnchor.constraint(equalTo: thumbnailView.topAnchor, constant: 4),
                $0.rightAnchor.constraint(equalTo: thumbnailView.rightAnchor, constant: -4),
                $0.widthAnchor.constraint(equalToConstant: 16),
                $0.heightAnchor.constraint(equalToConstant: 16)
            ]
            contentView.addConstraints(constraints)
        }
        
        // attributes
        thumbnailView.do {
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
        }
        nameLabel.do {
            $0.font = UIFont.systemFont(ofSize: 16)
            $0.textColor = .black
            $0.lineBreakMode = .byTruncatingTail
        }
        photoCountLabel.do {
            $0.font = UIFont.systemFont(ofSize: 14)
            $0.textColor = Util.color(with: 0x858585)
            $0.lineBreakMode = .byTruncatingTail
        }
        photoSelectionMarkView.do {
            $0.isUserInteractionEnabled = false
            $0.backgroundColor = Util.color(with: 0x2f54eb)
            $0.layer.cornerRadius = 8
            $0.isHidden = true
        }
    }
    
    public func updateData(_ album: Album, hasSelectedPhoto: Bool) {
        displayCoverPhoto = album.coverPhoto
        if let photo = album.coverPhoto {
            ImageManager.shared.fetchThumbnail(of: photo.asset, width: 54, keepImageSizeRatio: false) { [weak self] image, isDegraded, assert in
                guard let self = self else { return }
                guard assert.localIdentifier == self.displayCoverPhoto?.asset.localIdentifier else { return }
                self.thumbnailView.image = image
            }
        } else {
            self.thumbnailView.image = nil
        }
        
        nameLabel.text = album.name
        photoCountLabel.text = "\(album.photoCount)"
        photoSelectionMarkView.isHidden = !hasSelectedPhoto
    }
}
