//
//  AddAttachmentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

private class AttachmentGradientLayer: CAGradientLayer {
    
    override init() {
        
        let cgColors = [ThemeColor.B3.color.cgColor, ThemeColor.gray.color.cgColor]
        
        super.init()
        self.startPoint = CAGradientLayer.Point.topLeft.point
        self.endPoint = CAGradientLayer.Point.bottomRight.point
        self.colors = cgColors
        self.type = .axial
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(layer: Any) {
        super.init()
    }
}

class AddMediaView: ThemeButton {
    
    let plusImageView = UIImageView()
    let displayableImageView = DisplayableImageView()
    
    var didSelectRemove: CompletionOptional = nil
    var didSelectExpand: CompletionOptional = nil
    
    private let gradientLayer = AttachmentGradientLayer()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.plusImageView)
        self.plusImageView.image = UIImage(systemName: "plus")
        self.plusImageView.tintColor = UIColor.white.withAlphaComponent(0.8)
        
        self.layer.borderColor = ThemeColor.gray.color.cgColor
        self.layer.borderWidth = 2
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Theme.innerCornerRadius
        
        self.layer.insertSublayer(self.gradientLayer, at: 0)
        
        self.addSubview(self.displayableImageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.displayableImageView.expandToSuperviewSize()
        
        self.plusImageView.squaredSize = self.height * 0.5
        self.plusImageView.centerOnXAndY()
        
        CATransaction.begin()
        self.gradientLayer.frame = self.bounds
        CATransaction.commit()
    }
    
    func configure(with item: MediaItem?) {
        self.displayableImageView.isHidden = item.isNil
        self.displayableImageView.displayable = item
        self.updateMenu(for: item)
    }
    
    private func updateMenu(for item: MediaItem?) {
        if let item = item {
            self.menu = self.createMenu(for: item)
        } else {
            self.menu = nil
        }
    }
    
    private func createMenu(for item: MediaItem) -> UIMenu {
        
        let expand = UIAction(title: "Expand", image: UIImage(systemName: "arrow.up.left.and.arrow.down.right")) { action in
            self.didSelectExpand?()
        }
        
        let remove = UIAction(title: "Remove",
                              image: UIImage(systemName: "trash"),
                              attributes: .destructive) { action in
            self.didSelectRemove?()
        }

        return UIMenu.init(title: "",
                           image: nil,
                           identifier: nil,
                           options: [],
                           children: [expand, remove])
    }
}
