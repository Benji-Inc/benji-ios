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
    
    private let videoImageView = UIImageView(image: UIImage(systemName: "video.fill"))
    private let imageView = DisplayableImageView()
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.videoImageView)
        self.videoImageView.tintColor = ThemeColor.white.color
        self.videoImageView.contentMode = .scaleAspectFit
        self.videoImageView.showShadow(withOffset: 2)
        self.imageView.roundCorners()
    }
    
    func configure(with item: Attachment) {
        
        Task {
            guard let result = try? await AttachmentsManager.shared.getImage(for: item, size: self.size) else { return }
            
            self.videoImageView.isVisible = item.isVideo
            self.imageView.displayable = result.0
        }
    }
    
    override func update(isSelected: Bool) {
        self.imageView.alpha = isSelected ? 0.5 : 1.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.expandToSuperviewSize()
        
        self.videoImageView.squaredSize = 16
        self.videoImageView.pin(.bottom, offset: .short)
        self.videoImageView.pin(.right, offset: .short)
    }
}
