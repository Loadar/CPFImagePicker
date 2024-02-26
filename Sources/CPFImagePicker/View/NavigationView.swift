//
//  NavigationView.swift
//  
//
//  Created by Aaron on 2022/12/12.
//

import UIKit
import CPFUIKit

/// 自定义导航栏
open class NavigationView: UIView {
    private enum CPF {
        /// 返回按钮尺寸
        static var backButtonSize: CGSize { CGSize(width: 44, height: 44) }
        
        /// 下一步按钮高度
        static var nextButtonHeight: CGFloat { 30 }
    }
    
    /// 返回按钮
    public let backButton: Button
    /// 标题
    public let titleButton: Button
    /// 下一步
    public let nextButton = Button {
        $0.contentInsets = UIEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
    }
    
    /// 配置
    private let config: Config
    
    // MARK: - Lifecycle
    public init(config: Config) {
        self.config = config
        backButton = Button {
            let iconSize = config.appearance.backIconSize
            if iconSize.width <= CPF.backButtonSize.width, iconSize.height <= CPF.backButtonSize.height {
                $0.imageSize = iconSize
                let xInset = CPF.backButtonSize.width - iconSize.width
                let yInset = (CPF.backButtonSize.height - iconSize.height) / 2
                $0.contentInsets = UIEdgeInsets(top: yInset, left: 0, bottom: yInset, right: xInset)
            } else {
                $0.imageSize = CPF.backButtonSize
            }
        }
        titleButton = Button {
            $0.priority = .text
            $0.interSpace = 0
            $0.imageSize = config.appearance.popUpIconSize
            // 234 = 约为 16*2(两边按钮边距)+91*2(下一步按钮，2位数字时)+10*2(内容间距)
            $0.maxTextWidth = UIScreen.main.bounds.width - 234 - $0.imageSize.width - $0.interSpace
            $0.size = CGSize(width: 0, height: 44)
            $0.minSize = CGSize(width: 44, height: 0)
        }
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: 44)))
        configureView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
    public func configureView() {
        // views
        self.do {
            $0.addSubview(backButton)
            $0.addSubview(titleButton)
            $0.addSubview(nextButton)
        }
        
        // layouts
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        backButton.do {
            $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
                $0.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ]
            self.addConstraints(constraints)
        }
        titleButton.do {
            $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            let constraints: [NSLayoutConstraint] = [
                $0.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                $0.centerXAnchor.constraint(equalTo: self.centerXAnchor)
            ]
            self.addConstraints(constraints)
        }
        nextButton.do {
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            let constraints: [NSLayoutConstraint] = [
                $0.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16),
                $0.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                $0.heightAnchor.constraint(equalToConstant: CPF.nextButtonHeight),
            ]
            self.addConstraints(constraints)
        }
        
        // attributes
        backButton.do {
            $0.imageView?.contentMode = .scaleAspectFit
            $0.setImage(config.appearance.backIcon, for: .normal)
        }
        titleButton.do {
            $0.titleLabel?.font = .systemFont(ofSize: 18)
            $0.setTitleColor(.black, for: .normal)
            
            $0.imageView?.contentMode = .scaleAspectFit
            $0.setImage(config.appearance.popUpIcon, for: .normal)
        }
        nextButton.do {
            $0.isEnabled = false
            $0.titleLabel?.font = .systemFont(ofSize: 12)

            $0.layer.do {
                $0.cornerRadius = CPF.nextButtonHeight / 2
                $0.masksToBounds = true
                
                $0.borderWidth = 1
            }
        }
        
        // others
        updateNextButton(with: 0)
    }
    
    open override var intrinsicContentSize: CGSize {
        CGSize(width: -1, height: 44)
    }
    
    func updateNextButton(with selectedPhotoCount: Int, enabled: Bool = true) {
        nextButton.isEnabled = selectedPhotoCount > 0 && enabled

        if selectedPhotoCount > 0 {
            nextButton.setTitle("下一步(\(selectedPhotoCount))", for: .normal)
        } else {
            nextButton.setTitle("下一步", for: .normal)
        }
        
        if nextButton.isEnabled {
            nextButton.setTitleColor(Util.color(with: 0x2f54eb), for: .normal)
        } else {
            nextButton.setTitleColor(Util.color(with: 0xcccccc), for: .normal)
        }

        nextButton.layer.borderColor = nextButton.currentTitleColor.cgColor
    }
}
