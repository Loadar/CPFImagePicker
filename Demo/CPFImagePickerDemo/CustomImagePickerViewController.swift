//
//  CustomImagePickerViewController.swift
//  CPFImagePickerDemo
//
//  Created by Aaron on 2023/6/8.
//

import UIKit
import CPFImagePicker

final class CustomImagePickerViewController: ImagePickerViewController {
    /// 工具栏
    private let toolView = UIView()
    /// 提示
    private let changeButton = UIButton(type: .custom)
    /// 确认按钮
    private let confirmButton = UIButton(type: .custom)
    
    
    override func configureView() {
        super.configureView()
        
        // views
        view.do {
            $0.addSubview(toolView)
        }
        toolView.do {
            $0.addSubview(changeButton)
            $0.addSubview(confirmButton)
        }

        // layouts
        toolView.translatesAutoresizingMaskIntoConstraints = false
        changeButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        
        let toolViewLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(toolViewLayoutGuide)
        
        toolViewLayoutGuide.do {
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: view.leftAnchor),
                $0.rightAnchor.constraint(equalTo: view.rightAnchor),
                $0.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                $0.heightAnchor.constraint(equalToConstant: 64)
            ]
            view.addConstraints(constraints)
        }
        
        toolView.do {
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: toolViewLayoutGuide.leftAnchor),
                $0.rightAnchor.constraint(equalTo: toolViewLayoutGuide.rightAnchor),
                $0.topAnchor.constraint(equalTo: toolViewLayoutGuide.topAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
            view.addConstraints(constraints)
        }
        changeButton.do {
            let constraints: [NSLayoutConstraint] = [
                $0.leftAnchor.constraint(equalTo: toolView.leftAnchor, constant: 24),
                $0.centerYAnchor.constraint(equalTo: toolView.centerYAnchor),
                $0.heightAnchor.constraint(equalToConstant: 44)
            ]
            toolView.addConstraints(constraints)
        }
        confirmButton.do {
            let constraints: [NSLayoutConstraint] = [
                $0.rightAnchor.constraint(equalTo: toolView.rightAnchor, constant: -20),
                $0.widthAnchor.constraint(equalToConstant: 137),
                $0.centerYAnchor.constraint(equalTo: toolView.centerYAnchor),
                $0.heightAnchor.constraint(equalToConstant: 40)
            ]
            toolView.addConstraints(constraints)
        }
        
        // 不展示顶部的下一步按钮
        navigationView.nextButton.isHidden = true
        toolView.do {
            $0.backgroundColor = .white
        }
        changeButton.do {
            $0.titleLabel?.font = .systemFont(ofSize: 16)
            $0.setTitleColor(Util.color(with: 0x4d4d4d), for: .normal)
            $0.setTitle("切换选中索引展示", for: .normal)
        }
        confirmButton.do {
            $0.layer.cornerRadius = 20
            $0.clipsToBounds = true
            $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            $0.titleLabel?.textColor = .white
            $0.titleLabel?.textAlignment = .center
            $0.setTitleColor(.white, for: .normal)
            $0.setTitle("完成", for: .normal)
        }
        
        photoController.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 64, right: 0)
        
        selectedPhotosDidChanged()
    }
    
    override func configureActions() {
        super.configureActions()
        
        // 切换显示状态
        changeButton.addTarget(self, action: #selector(changeDisplayState), for: .touchUpInside)
        // 完成
        confirmButton.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
    }
    
    @objc private func changeDisplayState() {
        changeButton.cpfThrottler().run { [weak self] in
            guard let self = self else { return }
            self.data.updateConfig {
                $0.photo.cell.displaySelectedIconIndex = !$0.photo.cell.displaySelectedIconIndex
            }
        }
    }
    
    @objc private func confirmAction() {
        confirmButton.cpfThrottler().run { [weak self] in
            guard let self = self else { return }
            self.dismiss(with: true)
        }
    }
    
    override func selectedAlbumDidChanged() {
        super.selectedAlbumDidChanged()
        toolView.isHidden = data.album == nil
    }
    
    override func selectedPhotosDidChanged() {
        let countText: String
        if data.config.photo.cell.displaySelectedIconIndex {
            countText = "(\(data.selectedPhotos.count)/\(data.config.photo.maxSelectableCount))"
        } else {
            if data.selectedPhotos.count > 0 {
                countText = "(\(data.selectedPhotos.count))"
            } else {
                countText = ""
            }
        }
        confirmButton.isEnabled = data.selectedPhotos.count > 0
        if confirmButton.isEnabled {
            confirmButton.backgroundColor = Util.color(with: 0x2f54eb)
        } else {
            confirmButton.backgroundColor = Util.color(with: 0xcccccc)
        }
        
        confirmButton.setTitle("完成\(countText)", for: .normal)
    }
}
