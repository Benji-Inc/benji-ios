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

typealias ConversationViewControllerDelegates
= ConversationDetailViewControllerDelegate & ConversationViewControllerDelegate

@MainActor
protocol ConversationViewControllerDelegate: AnyObject {
    func conversationView(_ controller: ConversationViewController, didTapShare message: Messageable)
}

class ConversationViewController: BlurredViewController, CollectionViewInputHandler {

    lazy var detailVC = ConversationDetailViewController(conversation: self.conversation,
                                                         delegate: self.delegate)
    lazy var conversationCollectionView = ConversationCollectionView()
    lazy var collectionViewManager = ConversationCollectionViewManager(with: self.conversationCollectionView)

    private(set) var conversation: Conversation?
    private(set) var channelController: ChatChannelController?
    unowned let delegate: ConversationViewControllerDelegates

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
    lazy var messageInputAccessoryView = InputAccessoryView(with: self)

    override var inputAccessoryView: UIView? {
        // This is a hack to make the input hide during the presentation of the image picker. 
        self.messageInputAccessoryView.alpha = UIWindow.topMostController() == self ? 1.0 : 0.0
        return self.messageInputAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true 
    }

    init(conversation: Conversation?, delegate: ConversationViewControllerDelegates) {
        self.conversation = conversation
        self.delegate = delegate

        super.init()

        if let conversation = conversation {
            self.channelController = ChatClient.shared.channelController(for: conversation.cid)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.conversationCollectionView)

        self.addChild(viewController: self.detailVC, toView: self.view)

        self.conversationCollectionView.dataSource = self.collectionViewManager
        self.conversationCollectionView.delegate = self.collectionViewManager

        self.setupHandlers()
        self.subscribeToUpdates()
    }

    private func setupHandlers() {
        self.addKeyboardObservers()

        self.detailVC.$isHandlingTouches.mainSink { isHandlingTouches in
            if isHandlingTouches {
                self.resignFirstResponder()
            } else if !self.isFirstResponder {
                self.becomeFirstResponder()
            }
        }.store(in: &self.cancellables)

        KeyboardManger.shared.$isKeyboardShowing.mainSink { isShowing in
            self.detailVC.animator.fractionComplete = self.getDetailProgress()
        }.store(in: &self.cancellables)

        self.collectionViewManager.didTapShare = { [unowned self] message in
            self.delegate.conversationView(self, didTapShare: message)
        }

//        self.collectionViewManager.didTapResend = { [unowned self] message in
//            Task {
//                await self.resend(message: message)
//            }
//        }

        self.collectionViewManager.didTapEdit = { [unowned self] message, indexPath in
            self.indexPathForEditing = indexPath
            self.messageInputAccessoryView.edit(message: message)
        }

        #warning("Replace")
//        self.conversationCollectionView.onDoubleTap { [unowned self] (doubleTap) in
//            if self.messageInputAccessoryView.textView.isFirstResponder {
//                self.messageInputAccessoryView.textView.resignFirstResponder()
//            }
//        }
//
        if let conversation = self.conversation {
            self.load(conversation: conversation)
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

    func setupDetailAnimator() {
        self.detailVC.createAnimator()

        self.conversationCollectionView.publisher(for: \.contentOffset)
            .mainSink { (contentOffset) in
                self.detailVC.animator.fractionComplete = self.getDetailProgress()
                self.view.layoutNow()
            }.store(in: &self.cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.detailVC.view.expandToSuperviewWidth()
        self.detailVC.view.pin(.top)
        self.detailVC.view.centerOnX()

        self.conversationCollectionView.expandToSuperviewSize()
    }

    private func getDetailProgress() -> CGFloat {
        guard !KeyboardManger.shared.isKeyboardShowing else { return 0 }

        let threshold = ConversationDetailViewController.State.expanded.rawValue
        let offset = self.conversationCollectionView.contentOffset.y + self.conversationCollectionView.contentInset.top

        guard offset < threshold else { return 0 }

        let diff = threshold - offset
        let triggerThreshold = (diff / threshold)
        let pullRatio = clamp(triggerThreshold, 0.0, 1.0)
        return pullRatio
    }
}
