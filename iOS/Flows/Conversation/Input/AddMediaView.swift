//
//  AddAttachmentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AddMediaView: ThemeButton {
    
    static let expandedHeight: CGFloat = 100
    static let collapsedHeight: CGFloat = 40 
    
    let plusImageView = UIImageView()
    let displayableImageView = DisplayableImageView()
    
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
    
        
        self.layer.cornerRadius = Theme.innerCornerRadius
                
        self.addSubview(self.displayableImageView)
        // Don't allow user interaction on the image so it doesn't interfere with the UIMenu interaction.
        self.displayableImageView.isUserInteractionEnabled = false

        self.showsMenuAsPrimaryAction = true 
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.displayableImageView.expandToSuperviewSize()
        
        self.plusImageView.squaredSize = self.width * 0.7
        self.plusImageView.centerOnXAndY()
    }
    
    func configure(with items: [MediaItem]) {
        self.displayableImageView.isHidden = items.isEmpty
        self.displayableImageView.displayable = items.first
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
        let remove = UIAction(title: "Remove",
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
