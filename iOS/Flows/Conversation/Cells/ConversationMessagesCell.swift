//
//  MessageCell.swift
//  MessageCell
//
//  Created by Martin Young on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// A cell to display the messages of a conversation.
/// The user's messages and other messages are put in two stacks (along the z-axis),
/// with the most recent messages at the front.
class ConversationMessagesCell: UICollectionViewCell {

    // Interaction handling
    var handleTappedMessage: ((MessageSequenceItem, MessageContentView) -> Void)?
    var handleEditMessage: ((MessageSequenceItem) -> Void)?

    var handleTappedConversation: ((MessageSequence) -> Void)?
    var handleDeleteConversation: ((MessageSequence) -> Void)?

    private lazy var collectionLayout = MessagesTimeMachineCollectionViewLayout()
    lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: self.collectionLayout)
        cv.keyboardDismissMode = .interactive
        cv.showsVerticalScrollIndicator = false 
        return cv
    }()
    private lazy var dataSource = MessageSequenceCollectionViewDataSource(collectionView: self.collectionView)

    private var state: ConversationUIState = .read

    /// The conversation containing all the messages.
    var conversation: MessageSequence?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.collectionLayout.dataSource = self.dataSource

        self.collectionView.decelerationRate = .fast
        self.collectionView.delegate = self
        self.collectionView.set(backgroundColor: .clear)

        // Allow message subcells to scale in size without getting clipped.
        self.collectionView.clipsToBounds = false
        self.contentView.addSubview(self.collectionView)

        self.dataSource.handleTappedMessage = { [unowned self] item, content in
            self.handleTappedMessage?(item, content)
        }

        self.dataSource.handleEditMessage = { [unowned self] item in
            self.handleEditMessage?(item)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.collectionView.expandToSuperviewSize()
    }

    /// Configures the cell to display the given messages. The message sequence should be ordered newest to oldest.
    func set(sequence: MessageSequence) {
        self.conversation = sequence

        self.dataSource.update(messageSequence: sequence)
    }

    func updateMessages(with event: Event) {
        var snapshot = self.dataSource.snapshot()
        switch event {
        case let event as ReactionNewEvent:
            let item = MessageSequenceItem(channelID: event.cid, messageID: event.message.id)
            if snapshot.itemIdentifiers.contains(item) {
                snapshot.reconfigureItems([item])
            }
        case let event as ReactionDeletedEvent:
            let item = MessageSequenceItem(channelID: event.cid, messageID: event.message.id)
            if snapshot.itemIdentifiers.contains(item) {
                snapshot.deleteItems([item])
            }
        case let event as ReactionUpdatedEvent:
            let item = MessageSequenceItem(channelID: event.cid, messageID: event.message.id)
            if snapshot.itemIdentifiers.contains(item) {
                snapshot.reconfigureItems([item])
            }
        default:
            logDebug("event not handled")
        }

        self.dataSource.apply(snapshot, animatingDifferences: false)
    }
  
    override func prepareForReuse() {
        super.prepareForReuse()

        self.dataSource.prepareForSend = false

        // Remove all the items so the next message has a blank slate to work with.
        var snapshot = self.dataSource.snapshot()
        snapshot.deleteAllItems()
        self.dataSource.apply(snapshot, animatingDifferences: false)
    }

    /// Returns the frame that a message drop zone should have, based on this cell's contents.
    /// The frame is in the coordinate space of the passed in view.
    func getMessageDropZoneFrame(convertedTo targetView: UIView) -> CGRect {
        let dropZoneFrame = self.collectionLayout.getDropZoneFrame()

        return self.collectionView.convert(dropZoneFrame, to: targetView)
    }

    func setDropZone(isShowing: Bool) {
        self.collectionLayout.isShowingDropZone = isShowing
    }

    func getDropZoneColor() -> Color? {
        return self.collectionLayout.getDropZoneColor()
    }

    func getBottomFrontMostCell() -> MessageSubcell? {
        return self.collectionLayout.getBottomFrontMostCell()
    }

    func prepareForNewMessage() {
        self.dataSource.prepareForSend = true

        guard let conversation = self.conversation else { return }
        self.set(sequence: conversation)
    }

    func unprepareForNewMessage(reloadMessages: Bool) {
        self.dataSource.prepareForSend = false

        guard reloadMessages, let conversation = self.conversation else { return }
        self.set(sequence: conversation)
    }
}

extension ConversationMessagesCell: UICollectionViewDelegate {

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = self.dataSource.itemIdentifier(for: indexPath),
                let cell = collectionView.cellForItem(at: indexPath) as? MessageSubcell else { return }
        
        self.handleTappedMessage?(item, cell.content)
    }
}
