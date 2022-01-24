//
//  InitialMessageCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine

class InitialMessageCell: UICollectionViewCell {

    var handleTopicTapped: CompletionOptional = nil

    private(set) var label = ThemeLabel(font: .regular)
    private let borderView = BaseView()
    
    private var controller: ConversationController?
    private var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeViews()
    }

    private func initializeViews() {
        
        self.contentView.addSubview(self.borderView)
        self.borderView.addSubview(self.label)
        
        self.borderView.layer.borderColor = ThemeColor.D6withAlpha.color.cgColor
        self.borderView.layer.borderWidth = 1
        self.borderView.layer.cornerRadius = Theme.cornerRadius

        self.label.alpha = 0
        self.label.textAlignment = .center

        self.contentView.didSelect { [unowned self] in
            self.handleTopicTapped?()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.borderView.expandToSuperviewWidth()
        self.borderView.height = MessageContentView.bubbleHeight - Theme.ContentOffset.short.value
        self.borderView.pin(.bottom)

        self.label.setSize(withWidth: self.borderView.width - Theme.ContentOffset.standard.value.doubled)
        self.label.centerOnXAndY()
    }
    
    func configure(with conversation: Conversation) {
        self.controller = ChatClient.shared.channelController(for: conversation.cid)
        self.update(with: conversation)
        self.subscribeToUpdates()
    }
    
    private func update(with conversation: Conversation) {
        if conversation.isOwnedByMe {
            if let title = conversation.title {
                self.label.setText("Tap to edit: \(title)")
            } else {
                self.label.setText("Tap to add a topic")
            }
        } else {
            let dateString = Date.monthDayYear.string(from: conversation.createdAt)
            if let title = conversation.title {
                self.label.setText("\(title.capitalized) was created on:\n\(dateString)")
            } else {
                self.label.setText("This conversation was created on:\n\(dateString)")
            }
        }
        
        self.layoutNow()
    }
    
    private func subscribeToUpdates() {
        self.controller?
            .channelChangePublisher
            .mainSink { [unowned self] event in
                switch event {
                case .create(_):
                    break
                case .update(let conversation):
                    self.update(with: conversation)
                case .remove(_):
                    break
                }
            }.store(in: &self.cancellables)
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        guard let messageLayoutAttributes
                = layoutAttributes as? ConversationMessageCellLayoutAttributes else {
            return
        }
        
        self.label.alpha = messageLayoutAttributes.detailAlpha
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }
}
