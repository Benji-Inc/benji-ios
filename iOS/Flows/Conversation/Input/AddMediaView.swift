//
//  AddAttachmentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleCountView: BaseView {
    
    let blurredEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    let vibrancyEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .regular))
    lazy var vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
    
    let countLabel = ThemeLabel(font: .smallBold, textColor: .B0)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.blurredEffectView)
        
        self.vibrancyView.contentView.addSubview(self.countLabel)
        self.countLabel.textAlignment = .center
        
        self.blurredEffectView.contentView.addSubview(self.vibrancyView)
    }
    
    func set(count: Int) {
        self.countLabel.setText("\(count)")
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.squaredSize = 18
        self.makeRound()
        
        self.blurredEffectView.expandToSuperviewSize()
        self.blurredEffectView.makeRound()
        
        self.vibrancyView.expandToSuperviewSize()
        
        self.countLabel.expandToSuperviewSize()
    }
}

class AddMediaView: ThemeButton {
    
    static let expandedHeight: CGFloat = 100
    static let collapsedHeight: CGFloat = 40 
    
    let plusImageView = UIImageView()
    let displayableImageView = DisplayableImageView()
    
    let countCircle = CircleCountView()
    
    var didSelectRemove: CompletionOptional = nil
    
    var hasMedia: Bool {
        return self.displayableImageView.displayable.exists 
    }
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .clear)
        
        self.addSubview(self.plusImageView)
        self.plusImageView.image = UIImage(systemName: "plus")
        self.plusImageView.contentMode = .scaleAspectFit
        self.plusImageView.tintColor = ThemeColor.whiteWithAlpha.color
        self.displayableImageView.isVisible = false
        self.layer.borderColor = ThemeColor.whiteWithAlpha.color.cgColor
        self.layer.borderWidth = 2
        self.layer.cornerRadius = Theme.innerCornerRadius
                
        self.addSubview(self.displayableImageView)
        // Don't allow user interaction on the image so it doesn't interfere with the UIMenu interaction.
        self.displayableImageView.isUserInteractionEnabled = false

        self.showsMenuAsPrimaryAction = true
        
        self.addSubview(self.countCircle)
        self.countCircle.isVisible = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.displayableImageView.expandToSuperviewSize()
        
        self.plusImageView.squaredSize = self.width * 0.7
        self.plusImageView.centerOnXAndY()
        
        self.countCircle.pin(.bottom, offset: .short)
        self.countCircle.pin(.right, offset: .short)        
    }
    
    func configure(with items: [MediaItem]) {
        self.layer.borderColor = items.isEmpty ? ThemeColor.clear.color.cgColor : ThemeColor.whiteWithAlpha.color.cgColor
        self.displayableImageView.isHidden = items.isEmpty
        self.displayableImageView.displayable = items.first
        self.countCircle.isVisible = items.count > 1
        self.countCircle.set(count: items.count)
        self.setNeedsLayout()
        self.updateMenu(for: items)
    }

    private func updateMenu(for items: [MediaItem]) {
        if items.isEmpty {
            self.menu = nil
        } else {
            self.menu = self.createMenu(for: items)
        }
    }
    
    private func createMenu(for items: [MediaItem]) -> UIMenu {
        let title = items.count > 1 ? "Remove \(items.count) items" : "Remove item"
        let remove = UIAction(title: title,
                              image: UIImage(systemName: "trash"),
                              attributes: .destructive) { [unowned self] action in
            self.didSelectRemove?()
        }

        return UIMenu.init(title: "",
                           image: nil,
                           identifier: nil,
                           options: [],
                           children: [remove])
    }
}
