//
//  ConversationListViewController.swift
//  Jibber
//
//  Created by Martin Young on 11/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine

enum ConversationUIState {
    case read // Keyboard is NOT shown
    case write // Keyboard IS shown
}

class ConversationListViewController: FullScreenViewController,
                                      UICollectionViewDelegate,
                                      UICollectionViewDelegateFlowLayout,
                                      SwipeableInputAccessoryViewDelegate, ActiveConversationable {

    lazy var dataSource = ConversationCollectionViewDataSource(collectionView: self.collectionView)
    lazy var collectionView = ConversationListCollectionView()
    /// Denotes where a message should be dragged and dropped to send.
    let sendMessageDropZone = MessageDropZoneView()

    lazy var headerVC = ConversationHeaderViewController()

    private(set) var conversationListController: ConversationListController

    var selectedMessageView: MessageContentView?

    // Input handlers
    var onSelectedMessage: ((ChannelId, MessageId) -> Void)?

    // Custom Input Accessory View
    lazy var messageInputAccessoryView: ConversationInputAccessoryView = {
        let inputView: ConversationInputAccessoryView = ConversationInputAccessoryView.fromNib()
        inputView.delegate = self
        inputView.textView.restorationIdentifier = "list"
        return inputView
    }()

    override var inputAccessoryView: UIView? {
        return self.presentedViewController.isNil ? self.messageInputAccessoryView : nil
    }

    override var canBecomeFirstResponder: Bool {
        return self.presentedViewController.isNil
    }

    @Published var state: ConversationUIState = .read

    /// A list of conversation members used to filter conversations. We'll only show conversations with this exact set of members.
    private let members: [ConversationMember]
    /// The id of the conversation we should land on when this VC appears.
    private let startingConversationID: ConversationID?

    init(members: [ConversationMember], startingConversationID: ConversationID?) {
        self.members = members
        self.startingConversationID = startingConversationID

        let filter: Filter<ChannelListFilterScope>
        = members.isEmpty ? .containMembers(userIds: [User.current()!.objectId!]) : .containOnlyMembers(members)

        let query = ChannelListQuery(filter: filter,
                                     sort: [Sorting(key: .createdAt, isAscending: false)],
                                     pageSize: .channelsPageSize,
                                     messagesLimit: .messagesPageSize)
        self.conversationListController
        = ChatClient.shared.channelListController(query: query)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.headerVC, toView: self.contentContainer)

        self.contentContainer.addSubview(self.collectionView)
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.delegate = self

        self.subscribeToKeyboardUpdates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        switch self.state {
        case .read:
            self.headerVC.view.height = 96
        case .write:
            self.headerVC.view.height = 60
        }

        self.headerVC.view.pinToSafeAreaTop()
        self.headerVC.view.expandToSuperviewWidth()

        self.collectionView.expandToSuperviewWidth()
        self.collectionView.match(.top,
                                  to: .bottom,
                                  of: self.headerVC.view,
                                  offset: .negative(.long))
        self.collectionView.height = self.contentContainer.height - 96

        // If we're in the write mode, adjust the position of the collectionview to
        // accomodate the text input, if necessary.
        if self.state == .write {
            self.collectionView.top += self.getCollectionViewYOffset()
        }
    }

    /// Returns how much the collection view y position should  be adjusted to ensure that the text message input
    /// and message drop zone don't overlap.
    private func getCollectionViewYOffset() -> CGFloat {
        let dropZoneFrame = self.collectionView.getMessageDropZoneFrame(convertedTo: self.contentContainer)
        let textView: InputTextView = self.messageInputAccessoryView.textView
        let textViewFrame = textView.convert(textView.bounds, to: self.contentContainer)

        let overlapAmount = dropZoneFrame.bottom + Theme.contentOffset - textViewFrame.top
        return -clamp(overlapAmount, min: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        KeyboardManager.shared.addKeyboardObservers(with: self.inputAccessoryView)
        self.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        KeyboardManager.shared.reset()
        self.resignFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        once(caller: self, token: "initializeCollectionView") {
            Task {
                self.setupInputHandlers()
                // Initialize the datasource before listening for updates to ensure that the sections
                // are set up.
                await self.initializeDataSource()
                self.subscribeToUpdates()
            }
        }
    }

    func updateUI(for state: ConversationUIState) {
        guard self.presentedViewController.isNil else { return }

        self.headerVC.update(for: state)

        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.view.layoutNow()
        }
    }

    private var typingSubscriber: AnyCancellable?
    var conversationController: ConversationController?

    func updateCenterMostCell() {
        guard let cell = self.collectionView.getCentermostVisibleCell() as? ConversationMessagesCell else {
            return
        }

        guard let ip = self.collectionView.centerIndexPath(), let conversation = self.conversationListController.conversations[safe: ip.item] else { return }

        /// Sets the active conversation
        ConversationsManager.shared.activeConversation = conversation

        let members = conversation.lastActiveMembers.filter { member in
            return member.id != ChatClient.shared.currentUserId
        }
        self.messageInputAccessoryView.textView.setPlaceholder(for: members, isReply: false)

        // If there's a centered cell, update the layout
        if let currentConversation = self.activeConversation {
            self.conversationController = ChatClient.shared.channelController(for: currentConversation.cid)

            ConversationsManager.shared.$reactionEvent.mainSink { event in
                guard let event = event else { return }
                cell.updateMessages(with: event)
            }.store(in: &self.cancellables)

            self.conversationController?.messagesChangesPublisher.mainSink(receiveValue: { [unowned self] changes in
                if let activeConversation = self.conversationController?.conversation {
                    cell.set(sequence: activeConversation)
                }
            }).store(in: &self.cancellables)

            self.typingSubscriber = self.conversationController?
                .typingUsersPublisher
                .mainSink(receiveValue: { [unowned self] typingUsers in
                    let nonMeUsers = typingUsers.filter { user in
                        return user.userObjectID != User.current()?.objectId
                    }
                    // TODO: Update the typing indicator.
                })

            UIView.animate(withDuration: Theme.animationDurationFast) {
                self.view.layoutNow()
            }
        }
    }

    // MARK: - Message Loading and Updates

    @MainActor
    func initializeDataSource() async {
        try? await self.conversationListController.synchronize()
        try? await self.conversationListController.loadNextConversations(limit: .channelsPageSize)

        let conversations = self.conversationListController.conversations

        var snapshot = self.dataSource.snapshot()

        let section = ConversationSection(sectionID: "channelList",
                                          conversationsController: self.conversationListController)
        snapshot.appendSections([section])
        snapshot.appendItems(conversations.asConversationCollectionItems)

        if !self.conversationListController.hasLoadedAllPreviousChannels && conversations.count > 0 {
            snapshot.appendItems([.loadMore], toSection: section)
        }

        var startingIndexPath: IndexPath? = nil
        if let startingConversationID = self.startingConversationID {
            startingIndexPath = snapshot.indexPathOfItem(.messages(startingConversationID.description))
        }

        let animationCycle = AnimationCycle(inFromPosition: .right,
                                            outToPosition: .left,
                                            shouldConcatenate: true,
                                            scrollToIndexPath: startingIndexPath)

        await self.dataSource.apply(snapshot,
                                    collectionView: self.collectionView,
                                    animationCycle: animationCycle)

        self.updateCenterMostCell()
    }


    // MARK: - UICollection Input Handlers

    /// If true, the conversation controller is currently loading more conversations.
    @Atomic private var isLoadingConversations = false
    func loadMoreConversationsIfNeeded() {
        // If all the conversations are loaded, there's no need to fetch more.
        guard !self.conversationListController.hasLoadedAllPreviousChannels else { return }

        Task {
            guard !isLoadingConversations else { return }

            self.isLoadingConversations = true
            do {
                try await self.conversationListController.loadNextConversations(limit: .channelsPageSize)
            } catch {
                logDebug(error)
            }
            self.isLoadingConversations = false
        }.add(to: self.taskPool)
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        // Always scroll so that a cell is centered when we stop scrolling.
        var newXOffset = CGFloat.greatestFiniteMagnitude
        let targetOffset = targetContentOffset.pointee

        let targetRect = CGRect(x: targetOffset.x,
                                y: targetOffset.y,
                                width: scrollView.width,
                                height: scrollView.height)

        let layout = self.collectionView.conversationLayout
        guard let layoutAttributes = layout.layoutAttributesForElements(in: targetRect) else { return }

        // Find the item whose center is closest to the proposed offset and set that as the new scroll target
        for elementAttributes in layoutAttributes {
            let possibleNewOffset = elementAttributes.frame.centerX - collectionView.halfWidth
            if abs(possibleNewOffset - targetOffset.x) < abs(newXOffset - targetOffset.x) {
                newXOffset = possibleNewOffset
            }
        }

        targetContentOffset.pointee = CGPoint(x: newXOffset, y: targetOffset.y)

        self.updateCenterMostCell()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.updateCenterMostCell()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.updateCenterMostCell()
    }

    // MARK: - SwipeableInputAccessoryViewDelegate

    /// The type of message send method that the conversation VC is prepped for.
    private enum SendMode {
        /// The message will be sent to currently centered message.
        case message
        /// The message will the first in a new conversation.
        case newConversation
    }

    /// The collection view's content offset at the first call to prepare for a swipe. Used to reset the the content offset after a swipe is cancelled.
    private var initialContentOffset: CGPoint?
    /// The last swipe position type that was registersed, if any.
    private var currentSendMode: SendMode?

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, swipeIsEnabled isEnabled: Bool) {
        if isEnabled {
            guard self.sendMessageDropZone.superview.isNil else { return }
            // Animate in the send overlay
            self.contentContainer.addSubview(self.sendMessageDropZone)
            self.sendMessageDropZone.alpha = 0
            self.sendMessageDropZone.setState(.newMessage, messageColor: self.collectionView.getDropZoneColor())
            UIView.animate(withDuration: Theme.animationDurationStandard) {
                self.sendMessageDropZone.alpha = 1
            }

            // Show the send message overlay so the user can see where to drag the message
            let overlayFrame = self.collectionView.getMessageDropZoneFrame(convertedTo: self.contentContainer)
            self.sendMessageDropZone.frame = overlayFrame

            view.dropZoneFrame = view.convert(self.sendMessageDropZone.bounds, from: self.sendMessageDropZone)

            self.sendMessageDropZone.centerOnX()
        } else {
            UIView.animate(withDuration: Theme.animationDurationStandard) {
                self.sendMessageDropZone.alpha = 0
            } completion: { didFinish in
                self.sendMessageDropZone.removeFromSuperview()
            }
        }
    }

    func swipeableInputAccessoryDidBeginSwipe(_ view: SwipeableInputAccessoryView) {
        self.initialContentOffset = self.collectionView.contentOffset
        self.currentSendMode = nil

        self.collectionView.isUserInteractionEnabled = false

        if let currentCell = self.collectionView.getCentermostVisibleCell() as? ConversationMessagesCell {
            currentCell.prepareForNewMessage()
        }
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didUpdate sendable: Sendable,
                                 withPreviewFrame frame: CGRect) {

        let newSendType = self.getSendMode(forPreviewFrame: frame)

        // Don't do redundant send preparations.
        guard newSendType != self.currentSendMode else { return }

        self.prepareForSend(with: newSendType)

        self.currentSendMode = newSendType
    }

    private func prepareForSend(with position: SendMode) {
        switch position {
        case .message:
            self.sendMessageDropZone.setState(.newMessage,
                                             messageColor: self.collectionView.getDropZoneColor())
            if let initialContentOffset = self.initialContentOffset {
                self.collectionView.setContentOffset(initialContentOffset, animated: true)
            }
        case .newConversation:
            let newXOffset
            = -self.collectionView.width + self.collectionView.conversationLayout.minimumLineSpacing

            self.sendMessageDropZone.setState(.newConversation, messageColor: nil)
            self.collectionView.setContentOffset(CGPoint(x: newXOffset, y: 0), animated: true)
        }
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 triggeredSendFor sendable: Sendable,
                                 withPreviewFrame frame: CGRect) -> Bool {

        // Ensure that the preview has been dragged far up enough to send.
        let dropZoneFrame = view.dropZoneFrame
        let shouldSend = dropZoneFrame.bottom > frame.centerY

        guard shouldSend else {
            // Reset the collectionview content offset back to where we started.
            if let initialContentOffset = self.initialContentOffset {
                self.collectionView.setContentOffset(initialContentOffset, animated: true)
            }
            return false
        }

        switch self.currentSendMode {
        case .message:
            guard let currentIndexPath = self.collectionView.getCentermostVisibleIndex(),
                  let currentItem = self.dataSource.itemIdentifier(for: currentIndexPath),
                  case let .messages(conversationID) = currentItem,
                  let cid = try? ConversationID(cid: conversationID) else {

                      // If there is no current message to reply to, assume we're sending a new message
                      self.createNewConversation(sendable)
                      return true
                  }

            self.reply(to: cid, sendable: sendable)
        case .newConversation:
            self.createNewConversation(sendable)
        case .none:
            return false
        }

        return true
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didFinishSwipeSendingSendable didSend: Bool) {
        
        self.collectionView.isUserInteractionEnabled = true

        if let currentCell = self.collectionView.getCentermostVisibleCell() as? ConversationMessagesCell {
            currentCell.unprepareForNewMessage(reloadMessages: !didSend)
        }
    }

    /// Gets the send position for the given preview view frame.
    private func getSendMode(forPreviewFrame frame: CGRect) -> SendMode {
        switch self.currentSendMode {
        case .message, .none:
            // If we're in the message mode, switch to newConversation when the user
            // has dragged far enough to the right.
            if frame.right > self.view.width - 10 {
                return .newConversation
            } else {
                return .message
            }
        case .newConversation:
            // If we're in newConversation mode, switch to newMessage mode if the user drags far enough to the left.
            if frame.left < 10 {
                return .message
            } else {
                return .newConversation
            }
        }
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 updatedFrameOf textView: InputTextView) {

        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.view.layoutNow()
        }
    }

    // MARK: - Send Message Functions

    private func createNewConversation(_ sendable: Sendable) {
        Task {
            let username = User.current()?.initials ?? ""
            let channelId = ChannelId(type: .messaging, id: username+"-"+UUID().uuidString)
            let userIDs = Set(self.members.userIDs)

            do {
                let controller = try ChatClient.shared.channelController(createChannelWithId: channelId,
                                                                         name: nil,
                                                                         imageURL: nil,
                                                                         team: nil,
                                                                         members: userIDs,
                                                                         isCurrentUserMember: true,
                                                                         messageOrdering: .bottomToTop,
                                                                         invites: [],
                                                                         extraData: [:])

                try await controller.synchronize()
                try await controller.createNewMessage(with: sendable)
            } catch {
                logDebug(error)
            }
        }.add(to: self.taskPool)
    }

    private func reply(to cid: ConversationID, sendable: Sendable) {
        let conversationController = ChatClient.shared.channelController(for: cid)
        Task {
            do {
                try await conversationController.createNewMessage(with: sendable)
            } catch {
                logDebug(error)
            }
        }.add(to: self.taskPool)
    }
}

extension ConversationListViewController: TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .fade
    }

    var receivingDismissalType: TransitionType {
        if let view = self.selectedMessageView {
            return .message(view)
        }
        return .fade
    }

    var sendingPresentationType: TransitionType {
        if let view = self.selectedMessageView {
            return .message(view)
        }
        return .fade
    }
}
