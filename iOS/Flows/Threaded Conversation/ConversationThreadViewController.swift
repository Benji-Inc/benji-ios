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

class ConversationThreadViewController: BlurredViewController, CollectionViewInputHandler {

    lazy var conversationCollectionView = ConversationCollectionView()
    lazy var collectionViewManager = ConversationCollectionViewManager(with: self.conversationCollectionView)

    let messageController: ChatMessageController
    var message: Message! {
        return self.messageController.message
    }
    var collectionViewBottomInset: CGFloat = 0 {
        didSet {
            self.conversationCollectionView.contentInset.bottom = self.collectionViewBottomInset
            self.conversationCollectionView.verticalScrollIndicatorInsets.bottom = self.collectionViewBottomInset
        }
    }

    var indexPathForEditing: IndexPath?

    var collectionView: CollectionView {
        return self.conversationCollectionView
    }

    var inputTextView: InputTextView {
        return self.messageInputAccessoryView.textView
    }

    // Custom Input Accessory View
    lazy var messageInputAccessoryView = ConversationInputAccessoryView(with: self)

    override var inputAccessoryView: UIView? {
        // This is a hack to make the input hide during the presentation of the image picker. 
        self.messageInputAccessoryView.alpha = UIWindow.topMostController() == self ? 1.0 : 0.0
        return self.messageInputAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true 
    }

    init(channelID: ChannelId, messageID: MessageId) {
        self.messageController = ChatClient.shared.messageController(cid: channelID, messageId: messageID)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.conversationCollectionView)

        self.conversationCollectionView.dataSource = self.collectionViewManager
        self.conversationCollectionView.delegate = self.collectionViewManager

        Task {
            self.setupHandlers()
            await self.loadReplies(for: self.message)
            self.subscribeToUpdates()
        }
    }

    private func setupHandlers() {
        self.addKeyboardObservers()

        self.collectionViewManager.didTapEdit = { [unowned self] message, indexPath in
            self.indexPathForEditing = indexPath
            self.messageInputAccessoryView.edit(message: message)
        }

        self.conversationCollectionView.onDoubleTap { [unowned self] (doubleTap) in
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

    override func viewWasDismissed() {
        super.viewWasDismissed()

        self.collectionViewManager.reset()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.conversationCollectionView.expandToSuperviewSize()
    }
}
