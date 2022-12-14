//
//  AddPhotoCell.swift
//  
//
//  Created by Aaron on 2022/12/14.
//

import UIKit

/// 添加照片
open class AddPhotoCell: UICollectionViewCell {
    /// 图标
    public let iconView = UIImageView()
    /// 提示文字
    public let infoLabel = UILabel()
    
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
        
        // layouts
        iconView.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let layoutGuide = UILayoutGuide().then {
            contentView.addLayoutGuide($0)
            let constraints: [NSLayoutConstraint] = [
                $0.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                $0.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ]
            contentView.addConstraints(constraints)
        }
        iconView.do {
            let constraints: [NSLayoutConstraint] = [
                $0.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
                $0.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
                $0.widthAnchor.constraint(equalToConstant: 30),
                $0.heightAnchor.constraint(equalToConstant: 30)
            ]
            contentView.addConstraints(constraints)
        }
        infoLabel.do {
            let constraints: [NSLayoutConstraint] = [
                $0.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
                $0.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
                $0.widthAnchor.constraint(equalTo: layoutGuide.widthAnchor),
                $0.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
            ]
            contentView.addConstraints(constraints)
        }

        // attributes
        contentView.do {
            $0.backgroundColor = Util.color(with: 0xebebeb)
        }
        iconView.do {
            $0.contentMode = .scaleAspectFit
            $0.image = Bundle.module.url(forResource: "add", withExtension: "png").flatMap {
                UIImage(contentsOfFile: $0.path)
            }
        }
        infoLabel.do {
            $0.font = .systemFont(ofSize: 16)
            $0.textColor = Util.color(with: 0x212121)
            $0.textAlignment = .center
            $0.numberOfLines = 2
            $0.text = "添加更多\n可访问照片"
        }
    }
}
