//
//  AttachmentCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttachmentCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Attachment
    
    var currentItem: Attachment?
    
    private let videoImageView = SymbolImageView(symbol: .videoFill)
    private let imageView = DisplayableImageView()
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.imageView)
        self.imageView.layer.borderWidth = 2
        self.imageView.roundCorners()

        self.contentView.addSubview(self.videoImageView)
        self.videoImageView.tintColor = ThemeColor.white.color
        self.videoImageView.contentMode = .scaleAspectFit
        self.videoImageView.showShadow(withOffset: 2)
    }
    
    func configure(with item: Attachment) {
        
        Task {
            guard let result = try? await AttachmentsManager.shared.getImage(for: item, size: self.size) else { return }
            
            self.videoImageView.isVisible = item.isVideo
            self.imageView.displayable = result.0
        }
    }
    
    override func update(isSelected: Bool) {
        self.imageView.layer.borderColor = isSelected ? ThemeColor.D6.color.cgColor : ThemeColor.clear.color.cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.expandToSuperviewSize()
        
        self.videoImageView.squaredSize = 16
        self.videoImageView.pin(.bottom, offset: .short)
        self.videoImageView.pin(.right, offset: .short)
    }
}
