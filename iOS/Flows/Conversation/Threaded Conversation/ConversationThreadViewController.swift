//
//  ConversationViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine
import StreamChat

class ConversationThreadViewController: DiffableCollectionViewController<ConversationCollectionViewDataSource.SectionType, ConversationCollectionViewDataSource.ItemType, ConversationCollectionViewDataSource>, CollectionViewInputHandler {

    let messageController: ChatMessageController
    var message: Message! {
        return self.messageController.message
    }

    var collectionViewBottomInset: CGFloat = 0 {
        didSet {
            self.collectionView.contentInset.bottom = self.collectionViewBottomInset
            self.collectionView.verticalScrollIndicatorInsets.bottom = self.collectionViewBottomInset
        }
    }

    var indexPathForEditing: IndexPath?

    var inputTextView: InputTextView {
        return self.messageInputAccessoryView.textView
    }

    // Custom Input Accessory View
    lazy var messageInputAccessoryView = ConversationInputAccessoryView(with: self)

    override var inputAccessoryView: UIView? {
        return self.messageInputAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true 
    }

    init(channelID: ChannelId, messageID: MessageId) {
        self.messageController = ChatClient.shared.messageController(cid: channelID, messageId: messageID)

        super.init(with: ConversationThreadCollectionView())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        Task {
            self.setupHandlers()
            await self.loadReplies(for: self.message)
            self.subscribeToUpdates()
        }
    }

    private func setupHandlers() {
        self.addKeyboardObservers()

        self.collectionView.onDoubleTap { [unowned self] (doubleTap) in
            if self.messageInputAccessoryView.textView.isFirstResponder {
                self.messageInputAccessoryView.textView.resignFirstResponder()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.resignFirstResponder()
    }

    // MARK: Data Loading

    override func getAllSections() -> [ConversationCollectionViewDataSource.SectionType] {
        return []
    }

//    override func retrieveDataForSnapshot() async -> [ArchiveCollectionViewDataSource.SectionType : [ArchiveCollectionViewDataSource.ItemType]] {
//
//        guard let channels = self.channelListController?.channels else { return [:] }
//
//        var data: [ArchiveCollectionViewDataSource.SectionType : [ArchiveCollectionViewDataSource.ItemType]] = [:]
//
//        data[.conversations] = channels.map { conversation in
//            return .conversation(conversation.cid)
//        }
//
//        await NoticeSupplier.shared.loadNotices()
//
//        data[.notices] = NoticeSupplier.shared.notices.map { notice in
//            return .notice(notice)
//        }
//
//        return data
//    }
}
