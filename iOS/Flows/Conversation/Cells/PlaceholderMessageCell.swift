//
//  NewConversationCell.swift
//  Jibber
//
//  Created by Martin Young on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PlaceholderMessageCell: UICollectionViewCell {

    let dropZoneView = MessageDropZoneView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.initializeViews()
    }

    private func initializeViews() {
        self.contentView.addSubview(self.dropZoneView)
        self.dropZoneView.setState(.newMessage, messageColor: .white)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.dropZoneView.expandToSuperviewWidth()
        self.dropZoneView.height = MessageContentView.bubbleHeight
        self.dropZoneView.top = 180
    }
}
