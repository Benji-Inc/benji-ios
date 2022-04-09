//
//  ThreadViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine
import StreamChat
import SwiftUI

class ThreadViewController: DiffableCollectionViewController<MessageSequenceSection,
                            MessageSequenceItem,
                            RepliesSequenceCollectionViewDataSource>,
                            MessageInteractableController,
                            SwipeableInputControllerHandler {
    
    
    var swipeableVC: SwipeableInputAccessoryViewController {
        return self.messageInputController
    }
    
    var blurView = DarkBlurView()
    let parentMessageView = MessageContentView()
    
    var messageContent: MessageContentView {
        if let first = self.collectionView.indexPathsForSelectedItems?.first,
                let cell = self.collectionView.cellForItem(at: first) as? MessageCell {
            return cell.content
        } else {
            return self.parentMessageView
        }
    }

    weak var messageContentDelegate: MessageContentDelegate? {
        get { return self.dataSource.messageContentDelegate }
        set { self.dataSource.messageContentDelegate = newValue }
    }

    // Detail View
    @ObservedObject private var messageState = MessageDetailViewState(message: nil)
    private lazy var detailView = MessageDetailView(config: self.messageState)
    lazy var detailVC = NavBarIgnoringHostingController(rootView: self.detailView)
        
    /// If true we should scroll to the last item in the collection in layout subviews.
    private var scrollToLastItemOnLayout: Bool = true
    
    private let threadCollectionView = ThreadCollectionView()

    /// A controller for the message that all the replies in this thread are responding to.
    let messageController: ChatMessageController
    var parentMessage: Message? {
        return self.messageController.message
    }
    /// The reply to show when this view controller initially loads its data.
    private let startingReplyId: MessageId?

    private(set) var conversationController: ConversationController?
    let pullView = PullView()

    var indexPathForEditing: IndexPath?

    var inputTextView: InputTextView {
        return self.messageInputController.swipeInputView.textView
    }

    // Custom Input Accessory View
    lazy var messageInputController: SwipeableInputAccessoryViewController = {
        let inputController = SwipeableInputAccessoryViewController()
        inputController.delegate = self.swipeInputDelegate
        inputController.swipeInputView.textView.restorationIdentifier = "thread"
        return inputController
    }()
    lazy var swipeInputDelegate = SwipeableInputAccessoryMessageSender(viewController: self,
                                                                       collectionView: self.threadCollectionView,
                                                                       isConversationList: false)

    override var inputAccessoryViewController: UIInputViewController? {
        return self.messageInputController
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    lazy var dismissInteractionController = PanDismissInteractionController(viewController: self)
        
    @Published var state: ConversationUIState = .read

    init(channelID: ChannelId,
         messageID: MessageId,
         startingReplyId: MessageId?) {

        self.messageController = ChatClient.shared.messageController(cid: channelID, messageId: messageID)
        self.conversationController = ChatClient.shared.channelController(for: channelID,
                                                                             messageOrdering: .topToBottom)
        self.startingReplyId = startingReplyId

        super.init(with: self.threadCollectionView)

        self.threadCollectionView.threadLayout.dataSource = self.dataSource
        self.messageController.listOrdering = .bottomToTop
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()
        
        self.messageInputController.resetExpression()
        
        self.view.backgroundColor = ThemeColor.B0.color.withAlphaComponent(0.5)

        self.modalPresentationStyle = .overCurrentContext

        self.view.insertSubview(self.blurView, belowSubview: self.collectionView)
        self.view.addSubview(self.parentMessageView)
        
        self.addChild(viewController: self.detailVC, toView: self.parentMessageView)
        self.detailVC.view.alpha = 0
        
        self.view.addSubview(self.pullView)

        self.collectionView.clipsToBounds = false
        self.configureCollectionLayout(for: .read)

        self.dismissInteractionController.handleCollectionViewPan(for: self.collectionView)
        self.dismissInteractionController.handlePan(for: self.parentMessageView)
        self.dismissInteractionController.handlePan(for: self.pullView)
        
        KeyboardManager.shared.$currentEvent
            .mainSink { [weak self] currentEvent in
                guard let `self` = self else { return }
                switch currentEvent {
                case .willShow:
                    self.state = .write
                case .willHide:
                    self.state = .read
                default:
                    break
                }
            }.store(in: &self.cancellables)
        
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.updateUI(for: state, forceLayout: false)
            }.store(in: &self.cancellables)
        
        self.collectionView.allowsMultipleSelection = false 
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()
        
        self.pullView.pinToSafeAreaTop()
        self.pullView.centerOnX()

        self.parentMessageView.match(.top, to: .bottom, of: self.pullView)
        self.parentMessageView.centerOnX()

        self.detailVC.view.expandToSuperviewWidth()
        self.detailVC.view.height = 25
        self.detailVC.view.pin(.bottom, offset: .long)
        self.detailVC.view.centerOnX()
    }

    override func layoutCollectionView(_ collectionView: UICollectionView) {
        collectionView.expandToSuperviewHeight()
        collectionView.width = self.view.width - Theme.ContentOffset.xtraLong.value.doubled
        collectionView.centerOnX()

        if self.scrollToLastItemOnLayout {
            self.scrollToLastItemOnLayout = false
            self.threadCollectionView.threadLayout.prepare()
            let maxOffset = self.threadCollectionView.threadLayout.maxZPosition
            self.threadCollectionView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: false)
            self.threadCollectionView.threadLayout.invalidateLayout()
        }
    }
    
    @MainActor
    func scrollToConversation(with cid: ConversationId,
                              messageId: MessageId?,
                              animateScroll: Bool,
                              animateSelection: Bool) async {
        guard let messageId = messageId else { return }
        
        Task {
            let cid = self.messageController.cid

            try? await self.messageController.loadNextReplies(including: messageId)

            let messageItem = MessageSequenceItem.message(cid: cid, messageID: messageId)

            guard let messageIndexPath = self.dataSource.indexPath(for: messageItem) else { return }

            let threadLayout = self.threadCollectionView.threadLayout
            guard let yOffset = threadLayout.itemFocusPositions[messageIndexPath] else { return }

            self.collectionView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: animateScroll)

            if animateSelection, let cell = self.collectionView.cellForItem(at: messageIndexPath) {
                await UIView.awaitAnimation(with: .fast, animations: {
                    cell.transform = CGAffineTransform.init(scaleX: 1.05, y: 1.05)
                })

                await UIView.awaitAnimation(with: .fast, animations: {
                    cell.transform = .identity
                })
            }
        }.add(to: self.autocancelTaskPool)
    }
    
    func updateUI(for state: ConversationUIState, forceLayout: Bool) {
        guard !self.isBeingOpen && !self.isBeingClosed else { return }

        self.configureCollectionLayout(for: state)

        Task {
            await self.dataSource.reconfigureAllItems()
            if state == .write {
                let maxOffset = self.threadCollectionView.threadLayout.maxZPosition
                self.collectionView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: true)
            }
        }
    }

    private func configureCollectionLayout(for state: ConversationUIState) {
        let threadLayout = self.threadCollectionView.threadLayout
        threadLayout.itemHeight
        = MessageContentView.bubbleHeight + old_MessageDetailView.height + Theme.ContentOffset.long.value
        
        switch state {
        case .read:
            let topOfStack = UIWindow.topWindow()!.safeAreaInsets.top + PullView.height + threadLayout.itemHeight + 20
            threadLayout.topOfStackY = topOfStack
            threadLayout.spacingKeyPoints = [0, 20, 40, 64]
            
            UIView.animate(withDuration: Theme.animationDurationFast) {
                self.parentMessageView.alpha = 1.0
            } completion: { _ in
                self.view.bringSubviewToFront(self.parentMessageView)
                self.view.bringSubviewToFront(self.pullView)
            }

        case .write:
            let topOfStack = self.pullView.bottom
            threadLayout.topOfStackY = topOfStack
            threadLayout.spacingKeyPoints = [0, 8, 14, 16]
            
            UIView.animate(withDuration: Theme.animationDurationFast) {
                self.parentMessageView.alpha = 0
            } completion: { _ in
                self.view.bringSubviewToFront(self.collectionView)
                self.view.bringSubviewToFront(self.pullView)
            }
        }
    }

    // MARK: Data Loading

    override func getAllSections() -> [MessageSequenceSection] {
        return [.messages]
    }

    override func retrieveDataForSnapshot() async -> [MessageSequenceSection : [MessageSequenceItem]] {
        var data: [MessageSequenceSection: [MessageSequenceItem]] = [:]

        do {
            try await self.messageController.loadPreviousReplies()

            if let startingReplyId = self.startingReplyId {
                try await self.messageController.loadNextReplies(including: startingReplyId)
            }

            let cid = self.messageController.cid

            let messages = self.messageController.replies.map { message in
                return MessageSequenceItem.message(cid: cid, messageID: message.id)
            }
            data[.messages] = Array(messages)
        } catch {
            logError(error)
        }
        
        return data
    }

    override func collectionViewDataWasLoaded() {
        super.collectionViewDataWasLoaded()

        self.subscribeToUpdates()

        // Setting this here fixes issue with recursion during presentation.
        if let msg = self.messageController.message {
            self.messageState.message = msg
        }
        
        if let replyId = self.startingReplyId {
            Task {
                await self.scrollToConversation(with: self.messageController.cid,
                                                messageId: replyId,
                                                animateScroll: false,
                                                animateSelection: false)
            }
        }
        
        self.scrollToLastItemOnLayout = true
        self.view.layoutNow()
    }

    override func getAnimationCycle(with snapshot: NSDiffableDataSourceSnapshot<MessageSequenceSection,
                                    MessageSequenceItem>) -> AnimationCycle? {

        let cid = self.messageController.cid

        let startMessageIndex: Int
        if let startingReplyId = self.startingReplyId {
            startMessageIndex
            = snapshot.indexOfItem(.message(cid: cid, messageID: startingReplyId)) ?? 0
        } else {
            startMessageIndex = self.messageController.replies.count - 1
        }

        let layout = self.threadCollectionView.threadLayout
        let scrollToOffset = CGPoint(x: 0, y: layout.itemHeight * CGFloat(startMessageIndex))
        return AnimationCycle(inFromPosition: nil,
                              outToPosition: nil,
                              shouldConcatenate: false,
                              scrollToOffset: scrollToOffset)
    }
}
// MARK: - Messaging

extension ThreadViewController: MessageSendingViewControllerType {

    func getCurrentMessageSequence() -> MessageSequence? {
        return self.parentMessage
    }

    func set(messageSequencePreparingToSend: MessageSequence?) {
        self.dataSource.shouldPrepareToSend = messageSequencePreparingToSend.exists

        guard let message = self.messageController.message else { return }
        self.dataSource.set(messageSequence: message)
    }

    func sendMessage(_ message: Sendable) {
        Task {
            do {
                try await self.messageController.createNewReply(with: message)
            } catch {
                logError(error)
            }
        }.add(to: self.autocancelTaskPool)
    }

    func createNewConversation(_ sendable: Sendable) {
        // Do nothing. New conversations can't be created from a thread view controller.
    }
}

// MARK: - TransitionableViewController

extension ThreadViewController: TransitionableViewController {
    
    var receivingPresentationType: TransitionType {
        return .message(self.parentMessageView)
    }
    
    var receivingDismissalType: TransitionType {
        if let first = self.collectionView.indexPathsForSelectedItems?.first,
                let cell = self.collectionView.cellForItem(at: first) as? MessageCell {
            return .message(cell.content)
        } else {
            return .message(self.parentMessageView)
        }
    }

    var sendingDismissalType: TransitionType {
        return .message(self.parentMessageView)
    }
    
    var sendingPresentationType: TransitionType {
        guard let first = self.collectionView.indexPathsForSelectedItems?.first,
                let cell = self.collectionView.cellForItem(at: first) as? MessageCell else { return .fade }
        return .message(cell.content)
    }
    
    func handleFinalPresentation() {
        self.detailVC.view.alpha = 1.0
    }
    
    func handlePresentationCompleted() {
        guard self.messageController.message.exists else { return }
        self.loadInitialData()
    }
    
    func handleInitialDismissal() {
        self.collectionView.alpha = 0
        self.detailVC.view.alpha = 0
        self.pullView.alpha = 0.0
    }
    
    func handleDismissal() {
        self.pullView.bottom = self.messageContent.top
    }
    
    func handleCompletedDismissal() {
        if let selectedIndexPath = self.collectionView.indexPathsForSelectedItems?.first {
            self.collectionView.deselectItem(at: selectedIndexPath, animated: false)
        }
    }
}

// MARK: - Updates and Subscription

extension ThreadViewController {

    func subscribeToUpdates() {
        self.collectionView.backView.didSelect { [unowned self] in
            if self.messageInputController.swipeInputView.textView.isFirstResponder {
                self.messageInputController.swipeInputView.textView.resignFirstResponder()
            } else {
                self.messageInputController.swipeInputView.textView.becomeFirstResponder()
            }
        }

        self.messageInputController.swipeInputView.textView.$inputText.mainSink { [unowned self] _ in
            guard let enabled = self.conversationController?.areTypingEventsEnabled, enabled else { return }
            self.conversationController?.sendKeystrokeEvent(completion: nil)
        }.store(in: &self.cancellables)

        self.messageController.messageChangePublisher.mainSink { [unowned self] changes in
            guard let msg = self.messageController.message else { return }
            self.parentMessageView.configure(with: msg)
            self.messageState.message = msg
        }.store(in: &self.cancellables)

        self.messageController.repliesChangesPublisher.mainSink { [unowned self] changes in
            guard let message = self.messageController.message else { return }
            self.dataSource.set(messageSequence: message)
        }.store(in: &self.cancellables)

        let members = self.messageController.message?.threadParticipants.filter { member in
            return member.personId != ChatClient.shared.currentUserId
        } ?? []

        self.messageInputController.swipeInputView.textView.setPlaceholder(for: members, isReply: true)
    }
}
