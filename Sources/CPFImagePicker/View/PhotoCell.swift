//
//  PhotoCell.swift
//  
//
//  Created by Aaron on 2022/12/8.
//

import UIKit
import Photos
import Then

open class PhotoCell: UICollectionViewCell, AnyCPFPhotoCell {
    /// 缩略图
    public let thumbnailView = UIImageView()
    /// 选中状态
    public let selectStatusView = UIButton(type: .custom)
    /// 选中序号
    public let selectedIndexLabel = UILabel()
    /// 无法选中蒙层
    public let imselectableMaskView = UIView()
    
    /// 选中状态控件宽度
    private var selectStatusViewWidthConstraint: NSLayoutConstraint?
    /// 选中状态控件高度
    private var selectStatusViewHeightConstraint: NSLayoutConstraint?

    /// 展示的照片
    private var displayPhoto: Photo?
    /// 缩略图任务Id
    private var thumbnailTaskId: String?
    
    // MARK: - Lifecycle
    public override init(frame: CGRect) {
        super.init(frame: .zero)
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
            $0.addSubview(selectStatusView)
            $0.addSubview(selectedIndexLabel)
            $0.addSubview(imselectableMaskView)
        }
        
        // layouts
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        selectStatusView.translatesAutoresizingMaskIntoConstraints = false
        selectedIndexLabel.translatesAutoresizingMaskIntoConstraints = false
        imselectableMaskView.translatesAutoresizingMaskIntoConstraints = false
        
        thumbnailView.do {
            let constraints: [NSLayoutConstraint] = [
                $0.topAnchor.constraint(equalTo: contentView.topAnchor),
                $0.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                $0.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                $0.rightAnchor.constraint(equalTo: contentView.rightAnchor)
            ]
            contentView.addConstraints(constraints)
        }
        selectStatusView.do {
            let widthConstraint = $0.widthAnchor.constraint(equalToConstant: 24)
            self.selectStatusViewWidthConstraint = widthConstraint
            let heightConstraint = $0.heightAnchor.constraint(equalToConstant: 24)
            self.selectStatusViewHeightConstraint = heightConstraint
            let constraints: [NSLayoutConstraint] = [
                $0.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
                $0.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -5),
                widthConstraint,
                heightConstraint
            ]
            contentView.addConstraints(constraints)
        }
        selectedIndexLabel.do {
            let constraints: [NSLayoutConstraint] = [
                $0.centerXAnchor.constraint(equalTo: selectStatusView.centerXAnchor),
                $0.centerYAnchor.constraint(equalTo: selectStatusView.centerYAnchor)
            ]
            contentView.addConstraints(constraints)
        }
        imselectableMaskView.do {
            let constraints: [NSLayoutConstraint] = [
                $0.topAnchor.constraint(equalTo: contentView.topAnchor),
                $0.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                $0.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                $0.rightAnchor.constraint(equalTo: contentView.rightAnchor)
            ]
            contentView.addConstraints(constraints)
        }
        
        // attributes
        thumbnailView.do {
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
        }
        selectStatusView.do {
            $0.isUserInteractionEnabled = false
            $0.imageView?.contentMode = .scaleAspectFit
        }
        selectedIndexLabel.do {
            $0.font = .systemFont(ofSize: 12, weight: .medium)
            $0.textColor = .white
            $0.isHidden = true
        }
        imselectableMaskView.do {
            $0.isUserInteractionEnabled = false
            $0.backgroundColor = .white.withAlphaComponent(0.4)
            $0.isHidden = true
        }
    }
    
    // MARK: - AnyCPFPhotoCell
    public func updateData(_ photo: Photo, isSelected: Bool, selectedIndex: Int, selectable: Bool) {
        self.displayPhoto = photo

        update(selectedState: isSelected, selectedIndex: selectedIndex)
        imselectableMaskView.isHidden = isSelected || selectable
        
        self.layoutIfNeeded()
        self.thumbnailView.image = ImageManager.shared.thumbnail(of: photo, width: thumbnailView.bounds.width)
        
        let width = thumbnailView.bounds.width
        let newId = ImageManager.ThumbnailTask.id(of: photo.asset, width: width, keepImageSizeRatio: false)
        if let oldId = thumbnailTaskId, oldId != newId {
            ImageManager.shared.cancelTask(with: oldId)
        }
        thumbnailTaskId = newId
        ImageManager.shared.fetchThumbnail(of: photo.asset, width: width, keepImageSizeRatio: false) { [weak self] image, assert in
            guard let self = self else { return }
            guard assert.localIdentifier == self.displayPhoto?.asset.localIdentifier else { return }
            self.thumbnailView.image = image
        }
    }
    
    public func update(selectedState: Bool, selectedIndex: Int) {
        selectStatusView.isSelected = selectedState
        if !selectedIndexLabel.isHidden {
            if selectedState {
                selectedIndexLabel.alpha = 1
                selectedIndexLabel.text = "\(selectedIndex + 1)"
            } else {
                selectedIndexLabel.alpha = 0
            }
        }
    }
    
    public func update(config: Config.Photo.Cell) {
        if let radius = config.thumbnailCornerRadius, radius > 0 {
            thumbnailView.layer.cornerRadius = radius
        } else {
            thumbnailView.layer.cornerRadius = 0
        }
        if let (lineWidth, color) = config.thumbnailBorder, lineWidth > 0 {
            thumbnailView.layer.borderWidth = lineWidth
            thumbnailView.layer.borderColor = color.cgColor
        } else {
            thumbnailView.layer.borderWidth = 0
        }
        
        if let constraint = selectStatusViewWidthConstraint, constraint.constant != config.selectStateIconSize.width {
            constraint.constant = config.selectStateIconSize.width
        }
        if let constraint = selectStatusViewHeightConstraint, constraint.constant != config.selectStateIconSize.height {
            constraint.constant = config.selectStateIconSize.height
        }

        if let icon = config.unSelectedIcon, icon !== selectStatusView.image(for: .normal) {
            selectStatusView.setImage(icon, for: .normal)
        }
        if let icon = config.displaySelectedIcon, icon !== selectStatusView.image(for: .selected) {
            selectStatusView.setImage(icon, for: .selected)
        }
        selectedIndexLabel.isHidden = !config.displaySelectedIconIndex

        imselectableMaskView.backgroundColor = config.maskColor
    }
}
