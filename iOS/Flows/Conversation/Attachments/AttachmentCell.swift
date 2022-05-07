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
    
    private let imageView = DisplayableImageView()
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.imageView)
        self.imageView.roundCorners()
    }
    
    func configure(with item: Attachment) {
        
        Task {
            guard let result = try? await AttachmentsManager.shared.getImage(for: item, size: self.size) else { return }
            self.imageView.displayable = result.0
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.expandToSuperviewSize()
    }
}
