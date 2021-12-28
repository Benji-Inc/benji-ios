//
//  InitialMessageCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class InitialMessageCell: UICollectionViewCell {

    var handleTopicTapped: CompletionOptional = nil

    private(set) var label = ThemeLabel(font: FontType.mediumBold, textColor: .textColor)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.contentView.addSubview(self.label)

        self.label.alpha = 0
        self.label.textAlignment = .center

        self.contentView.didSelect { [unowned self] in
            self.handleTopicTapped?()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }
    
    func configure(with conversation: Conversation) {
        if conversation.title.isEmpty {
            self.label.setText("Add a topic")
        } else {
            self.label.setText("Topic: \(conversation.title)")
        }
        self.layoutNow()
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        guard let messageLayoutAttributes
                = layoutAttributes as? ConversationMessageCellLayoutAttributes else {
            return
        }
        
        self.label.alpha = messageLayoutAttributes.detailAlpha
    }
}
