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

    private(set) var label = ThemeLabel(font: .regular)
    private let borderView = BaseView()
    
    private var controller: MessageSequenceController?
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
        self.borderView.layer.cornerRadius = Theme.cornerRadius
        self.borderView.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.borderView.layer.borderWidth = 1

        self.label.alpha = 0
        self.label.textAlignment = .center
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.borderView.expandToSuperviewWidth()
        self.borderView.height = MessageContentView.bubbleHeight
        self.borderView.pin(.top)

        self.label.setSize(withWidth: self.borderView.width - Theme.ContentOffset.standard.value.doubled)
        self.label.centerOnXAndY()
    }
    
    func configure(with messageSequenceController: MessageSequenceController) {
        self.controller = messageSequenceController
        if let messageSequence = messageSequenceController.messageSequence {
            self.update(with: messageSequence)
        }

        self.subscribeToUpdates()
    }
    
    private func update(with messageSequence: MessageSequence) {
        let dateString = Date.monthDayYear.string(from: messageSequence.createdAt)
        if let title = messageSequence.title {
            self.label.setText("\(title.capitalized) was created on:\n\(dateString)")
        } else {
            self.label.setText("This conversation was created on:\n\(dateString)")
        }
        
        self.layoutNow()
    }
    
    private func subscribeToUpdates() {
        self.controller?
            .messageSequenceChangePublisher
            .mainSink { [unowned self] event in
                switch event {
                case .update(let conversation):
                    self.update(with: conversation)
                case .create, .remove:
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
        
        self.label.alpha = clamp(messageLayoutAttributes.detailAlpha, 0.0, 0.35)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }
}
