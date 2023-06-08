//
//  TakePhotoCell.swift
//  
//
//  Created by Aaron on 2023/6/7.
//

import UIKit

/// 拍照
open class TakePhotoCell: UICollectionViewCell {
    /// 图标
    public let iconView = UIImageView()
    /// 提示文字
    public let infoLabel = UILabel()
    
    /// 渐变背景
    private let gradientLayer = CAGradientLayer()
    
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
            $0.addSubview(iconView)
            $0.addSubview(infoLabel)
        }
        contentView.layer.insertSublayer(gradientLayer, at: 0)
        
        // layouts
        iconView.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        iconView.do {
            let constraints: [NSLayoutConstraint] = [
                $0.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
                $0.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                $0.widthAnchor.constraint(equalToConstant: 32),
                $0.heightAnchor.constraint(equalToConstant: 32)
            ]
            contentView.addConstraints(constraints)
        }
        infoLabel.do {
            let constraints: [NSLayoutConstraint] = [
                $0.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
                $0.centerXAnchor.constraint(equalTo: iconView.centerXAnchor)
            ]
            contentView.addConstraints(constraints)
        }

        // attributes
        contentView.do {
            $0.backgroundColor = .clear
        }
        gradientLayer.do {
            $0.type = .axial
            $0.colors = [0x4d4d4d, 0x212121].map {
                Util.color(with: $0).cgColor
            }
            $0.locations = [0, 1]
            $0.startPoint = .zero
            $0.endPoint = CGPoint(x: 1, y: 1)
            
            $0.frame = contentView.bounds
        }
        
        iconView.do {
            $0.contentMode = .scaleAspectFit
            $0.image = Bundle.module.url(forResource: "camera", withExtension: "png").flatMap {
                UIImage(contentsOfFile: $0.path)
            }
        }
            
        infoLabel.do {
            $0.font = .systemFont(ofSize: 12, weight: .medium)
            $0.textColor = Util.color(with: 0x858585)
            $0.textAlignment = .center
            $0.text = "拍摄照片"
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = contentView.bounds
    }
}
