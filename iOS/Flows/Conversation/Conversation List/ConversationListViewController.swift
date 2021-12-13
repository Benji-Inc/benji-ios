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

    var headerHeight: CGFloat {
        switch self {
        case .read:
            return 60
        case .write:
            return 44
        }
    }
}

class ConversationListViewController: FullScreenViewController,
                                      UICollectionViewDelegate,
                                      UICollectionViewDelegateFlowLayout,
                                      ActiveConversationable {

    lazy var dataSource = ConversationListCollectionViewDataSource(collectionView: self.collectionView)
    lazy var collectionView = ConversationListCollectionView()

    lazy var headerVC = ConversationHeaderViewController()

    private(set) var conversationListController: ConversationListController

    var selectedMessageView: MessageContentView?

    // Input handlers
    var onSelectedMessage: ((ChannelId, MessageId) -> Void)?

    // Custom Input Accessory View
    lazy var messageInputAccessoryView: ConversationInputAccessoryView = {
        let inputView: ConversationInputAccessoryView = ConversationInputAccessoryView.fromNib()
        inputView.delegate = self.swipeInputDelegate
        inputView.textView.restorationIdentifier = "list"
        return inputView
    }()
    lazy var swipeInputDelegate = SwipeableInputAccessoryMessageSender(viewController: self,
                                                                       collectionView: self.collectionView,
                                                                       isConversationList: true)

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
        = members.isEmpty ? .containMembers(userIds: [User.current!.objectId!]) : .containOnlyMembers(members)

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

        self.contentContainer.addSubview(self.collectionView)
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.delegate = self

        self.addChild(viewController: self.headerVC, toView: self.contentContainer)
        self.subscribeToKeyboardUpdates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.headerVC.view.expandToSuperviewWidth()
        self.headerVC.view.height = self.state.headerHeight

        let headerOffset: Theme.ContentOffset = self.state == .read ? .xtraLong : .standard
        self.headerVC.view.pin(.top, offset: headerOffset)

        self.collectionView.expandToSuperviewWidth()
        self.collectionView.top = self.headerVC.view.bottom
        self.collectionView.height = self.contentContainer.height - ConversationUIState.write.headerHeight

        // If we're in the write mode, adjust the position of the subviews to
        // accomodate the text input, if necessary.
        if self.state == .write {
            self.setYOffsets()
        }
    }

    /// Returns how much the collection view y position should  be adjusted to ensure that the text message input
    /// and message drop zone don't overlap.
    private func setYOffsets() {
        let dropZoneFrame = self.collectionView.getMessageDropZoneFrame(convertedTo: self.contentContainer)
        self.swipeInputDelegate.sendMessageDropZone.frame = dropZoneFrame

        guard let cell = self.collectionView.getBottomFrontmostCell() else { return }

        let cellFrame = self.contentContainer.convert(cell.bounds, from: cell)
        let accessoryFrame = self.contentContainer.convert(self.messageInputAccessoryView.bounds, from: self.messageInputAccessoryView)

        let diff = cellFrame.bottom - accessoryFrame.top
        self.collectionView.top += -clamp(diff, min: 0)
        self.swipeInputDelegate.sendMessageDropZone.top += -clamp(diff, min: 0)

        //TODO fix this magic number.
        self.headerVC.view.alpha = self.collectionView.top < 25 ? 0 : 1.0
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

        let section = ConversationListSection(conversationsController: self.conversationListController)
        snapshot.appendSections([section])
        snapshot.appendItems(conversations.asConversationCollectionItems)

        if !self.conversationListController.hasLoadedAllPreviousChannels && conversations.count > 0 {
            snapshot.appendItems([.loadMore], toSection: section)
        }

        var startingIndexPath: IndexPath? = nil
        if let startingConversationID = self.startingConversationID {
            startingIndexPath = snapshot.indexPathOfItem(.conversation(startingConversationID))
        }

        let animationCycle = AnimationCycle(inFromPosition: .inward,
                                            outToPosition: .inward,
                                            shouldConcatenate: false,
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
}

// MARK: - MessageSendingViewControllerType

extension ConversationListViewController: MessageSendingViewControllerType {

    func set(shouldLayoutForDropZone: Bool) {
        self.dataSource.layoutForDropZone = shouldLayoutForDropZone
    }

    func getCurrentMessageSequence() -> MessageSequence? {
        guard let centeredCell = self.collectionView.getCentermostVisibleCell() as? ConversationMessagesCell,
              let cid = centeredCell.conversation?.streamCID else {
                  return nil
              }

        return ChatClient.shared.channelController(for: cid).conversation
    }

    func set(messageSequencePreparingToSend: MessageSequence?, reloadData: Bool) {
        self.dataSource.set(conversationPreparingToSend: messageSequencePreparingToSend?.streamCID,
                            reloadData: reloadData)
    }

    func createNewConversation(_ sendable: Sendable) {
        Task {
            let username = User.current?.initials ?? ""
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

    func sendMessage(_ message: Sendable) {
        guard let cid = self.getCurrentMessageSequence()?.streamCID else { return }
        let conversationController = ChatClient.shared.channelController(for: cid)
        Task {
            do {
                try await conversationController.createNewMessage(with: message)
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
