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

enum ConversationUIState: String {
    case read // Keyboard is NOT shown
    case write // Keyboard IS shown

    var headerHeight: CGFloat {
        return 46
    }
}

class ConversationListViewController: InputHandlerViewContoller, ConversationListCollectionViewLayoutDelegate {
    
    override var analyticsIdentifier: String? {
        return "SCREEN_CONVERSATION_LIST"
    }
    
    // Collection View
    lazy var dataSource = ConversationListCollectionViewDataSource(collectionView: self.collectionView)
    lazy var collectionView = ConversationListCollectionView()

    lazy var headerVC = ConversationHeaderViewController()

    private(set) var conversationListController: ConversationListController

    var selectedMessageView: MessageContentView?

    // Input handlers
    var onSelectedMessage: ((_ cid: ChannelId, _ messageId: MessageId, _ replyId: MessageId?) -> Void)?

    var swipeableVC: SwipeableInputAccessoryViewController {
        return messageInputController
    }

    // Custom Input Accessory View
    lazy var messageInputController: SwipeableInputAccessoryViewController = {
        let inputController = SwipeableInputAccessoryViewController()
        inputController.delegate = self.swipeInputDelegate
        inputController.swipeInputView.textView.restorationIdentifier = "list"
        return inputController
    }()
    lazy var swipeInputDelegate = SwipeableInputAccessoryMessageSender(viewController: self,
                                                                       collectionView: self.collectionView,
                                                                       isConversationList: true)

    override var inputAccessoryViewController: UIInputViewController? {
        return self.presentedViewController.isNil ? self.messageInputController : nil
    }
    override var canBecomeFirstResponder: Bool {
        return self.presentedViewController.isNil && ConversationsManager.shared.activeConversation.exists
    }

    @Published var state: ConversationUIState = .read

    /// A list of conversation members used to filter conversations. We'll only show conversations with this exact set of members.
    private let members: [ConversationMember]
    /// The id of the conversation we should land on when this VC appears.
    private let startingConversationID: ConversationId?
    private let startingMessageID: MessageId?

    init(members: [ConversationMember],
         startingConversationID: ConversationId?,
         startingMessageID: MessageId?) {

        self.members = members
        self.startingConversationID = startingConversationID
        self.startingMessageID = startingMessageID

        let filter: Filter<ChannelListFilterScope>
        = members.isEmpty ? .containMembers(userIds: [User.current()!.objectId!]) : .containOnlyMembers(members)

        let query = ChannelListQuery(filter: .and([.equal("hidden", to: false), filter]),
                                     sort: [Sorting(key: .createdAt, isAscending: true)],
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
        
        self.view.addSubview(self.collectionView)
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.conversationLayout.delegate = self

        self.addChild(viewController: self.headerVC, toView: self.view)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard self.presentedViewController.isNil else { return }

        self.headerVC.view.expandToSuperviewWidth()
        self.headerVC.view.height = self.state.headerHeight
        self.headerVC.view.pinToSafeArea(.top, offset: .noOffset)

        self.collectionView.expandToSuperviewWidth()
        self.collectionView.match(.top, to: .bottom, of: self.headerVC.view, offset: .standard)
        self.collectionView.height = self.view.height - self.headerVC.view.bottom
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        once(caller: self, token: "initializeCollectionView") {
            Task {
                self.subscribeToUIUpdates()
                self.setupInputHandlers()
                // Initialize the datasource before listening for updates to ensure that the sections
                // are set up.
                await self.initializeDataSource()
                self.subscribeToConversationUpdates()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.resignFirstResponder()
    }

    func updateUI(for state: ConversationUIState, forceLayout: Bool = false) {
        guard self.presentedViewController.isNil || forceLayout else { return }

        self.headerVC.update(for: state)
        self.dataSource.uiState = state

        self.dataSource.reconfigureAllItems()
    }

    // MARK: - Message Loading and Updates

    @MainActor
    func initializeDataSource() async {
        try? await self.conversationListController.synchronize()
        try? await self.conversationListController.loadNextConversations(limit: .channelsPageSize)

        let conversations = self.conversationListController.conversations

        let snapshot = self.dataSource.updatedSnapshot(with: self.conversationListController)

        // Automatically scroll to the latest conversation.
        let startingIndexPath: IndexPath
        if let startingConversationID = self.startingConversationID,
           let conversationIndexPath = snapshot.indexPathOfItem(.conversation(startingConversationID)) {
            startingIndexPath = conversationIndexPath
        } else {
            startingIndexPath = IndexPath(item: clamp(conversations.count - 1, min: 0) , section: 0)
        }

        let animationCycle = AnimationCycle(inFromPosition: .inward,
                                            outToPosition: .inward,
                                            shouldConcatenate: false,
                                            scrollToIndexPath: startingIndexPath)

        await self.dataSource.apply(snapshot,
                                    collectionView: self.collectionView,
                                    animationCycle: animationCycle)

        guard let startingConversationID = self.startingConversationID else { return }

        Task {
            await self.scrollToConversation(with: startingConversationID, messageID: self.startingMessageID)
        }.add(to: self.autocancelTaskPool)
    }

    @MainActor
    func scrollToConversation(with cid: ConversationId, messageID: MessageId?) async {
        guard let conversationIndexPath = self.dataSource.indexPath(for: .conversation(cid)) else { return }
        self.collectionView.scrollToItem(at: conversationIndexPath,
                                         at: .centeredHorizontally,
                                         animated: true)

        guard let messageID = messageID else { return }

        guard let cell = self.collectionView.cellForItem(at: conversationIndexPath),
              let messagesCell = cell as? ConversationMessagesCell else {
                  return
              }

        let messageController = ChatClient.shared.messageController(cid: cid, messageId: messageID)

        try? await messageController.synchronize()

        guard let message = messageController.message else { return }

        // Determine if this is a reply message or regular message. If it's a reply, select the parent
        // message so we can open the thread experience.
        if let parentMessageId = message.parentMessageId {
            await messagesCell.scrollToMessage(with:  parentMessageId, animateSelection: true)
            self.selectedMessageView = messagesCell.getBottomFrontmostCell()?.content
            self.onSelectedMessage?(cid, parentMessageId, messageID)
        } else {
            await messagesCell.scrollToMessage(with: messageID, animateSelection: true)
            
        }
    }

    func getCurrentConversationController() -> ConversationController? {
        guard let centeredCell
                = self.collectionView.getCentermostVisibleCell() as? ConversationMessagesCell else {
            return nil
        }

        return centeredCell.conversationController
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
                logError(error)
            }
            self.isLoadingConversations = false
        }.add(to: self.autocancelTaskPool)
    }

    // MARK: - ConversationListCollectionViewLayoutDelegate

    func conversationListCollectionViewLayout(_ layout: ConversationListCollectionViewLayout,
                                              cidFor indexPath: IndexPath) -> ConversationId? {

        let item = self.dataSource.itemIdentifier(for: indexPath)
        switch item {
        case .conversation(let cid):
            return cid
        case .loadMore, .newConversation, .none, .upsell, .invest:
            return nil
        }
    }

    func conversationListCollectionViewLayout(_ layout: ConversationListCollectionViewLayout,
                                              didUpdateCentered cid: ConversationId?) {

        self.update(withCenteredCid: cid)
    }

    /// A task for updating the message input accessory.
    private var messageInputTask: Task<Void, Never>?
    /// A task to become or resign first responder status.
    private var firstResponderTask: Task<Void, Never>?

    private func update(withCenteredCid cid: ConversationId?) {
        self.messageInputTask?.cancel()
        self.firstResponderTask?.cancel()

        // Reset the input accessory view.
        self.messageInputController.updateSwipeHint(shouldPlay: false)

        if let cid = cid {
            let conversation = Conversation.conversation(cid)
            // Sets the active conversation
            ConversationsManager.shared.activeConversation = conversation

            self.messageInputTask = Task { [weak self] in
                let people = await PeopleStore.shared.getPeople(for: conversation)

                guard !Task.isCancelled else { return }

                self?.messageInputController.resetEmotion()
                self?.messageInputController.resetDeliveryType()
                self?.messageInputController.swipeInputView.textView.setPlaceholder(for: people, isReply: false)
                self?.messageInputController.updateSwipeHint(shouldPlay: true)
            }

            self.firstResponderTask = Task { [weak self] in
                await Task.sleep(seconds: 0.25)

                guard !Task.isCancelled else { return }

                // The input accessory view should be shown when centered on a conversation. If there's not
                // already set as first responder, then make the VC first responder.
                if UIResponder.firstResponder.isNil {
                    self?.becomeFirstResponder()
                }
            }
        } else {
            ConversationsManager.shared.activeConversation = nil

            self.messageInputController.updateSwipeHint(shouldPlay: true)

            self.firstResponderTask = Task {
                await Task.sleep(seconds: 0.25)

                guard !Task.isCancelled else { return }

                // Hide the keyboard and accessory view when we're not centered on a conversation.
                UIResponder.firstResponder?.resignFirstResponder()
            }
        }
    }
}

// MARK: - MessageSendingViewControllerType

extension ConversationListViewController: MessageSendingViewControllerType {

    func getCurrentMessageSequence() -> MessageSequence? {
        return self.getCurrentConversationController()?.conversation
    }

    func set(messageSequencePreparingToSend: MessageSequence?) {
        self.dataSource.set(conversationPreparingToSend: messageSequencePreparingToSend?.streamCID)
    }

    func createNewConversation(_ sendable: Sendable) {
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

                ConversationsManager.shared.activeConversation = controller.conversation

                try await controller.createNewMessage(with: sendable)
            } catch {
                logError(error)
            }
        }
    }

    func sendMessage(_ message: Sendable) {
        guard let cid = self.getCurrentMessageSequence()?.streamCID else {
            self.createNewConversation(message)
            return
        }

        let conversationController = ChatClient.shared.channelController(for: cid)

        Task {
            do {
                try await conversationController.createNewMessage(with: message)
            } catch {
                logError(error)
            }
        }
    }
}

// MARK: - TransitionableViewController

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
