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
import PhotosUI

enum ConversationUIState: String {
    case read // Keyboard is NOT shown
    case write // Keyboard IS shown

    var headerHeight: CGFloat {
        return 46
    }
}

/// A view controller for displaying a single conversation.
class ConversationViewController: InputHandlerViewContoller,
                                  ConversationListCollectionViewLayoutDelegate {
    
    override var analyticsIdentifier: String? {
        return "SCREEN_CONVERSATION_LIST"
    }

    var messageContentDelegate: MessageContentDelegate? {
        get { return self.dataSource.messageContentDelegate}
        set { self.dataSource.messageContentDelegate = newValue }
    }
    
    var blurView = DarkBlurView()
    lazy var dismissInteractionController = PanDismissInteractionController(viewController: self)

    // Collection View
    lazy var dataSource = ConversationListCollectionViewDataSource(collectionView: self.collectionView)
    lazy var collectionView = ConversationListCollectionView()

    lazy var headerVC = ConversationHeaderViewController()

    private(set) var conversationListController: ConversationListController

    var swipeableVC: SwipeableInputAccessoryViewController {
        return self.messageInputController
    }

    // Custom Input Accessory View
    lazy var messageInputController: SwipeableInputAccessoryViewController = {
        let inputController = SwipeableInputAccessoryViewController()
        inputController.delegate = self.swipeInputDelegate
        inputController.swipeInputView.textView.restorationIdentifier = "list"
        return inputController
    }()
    
    lazy var swipeInputDelegate = SwipeableInputAccessoryMessageSender(viewController: self,
                                                                       collectionView: self.collectionView)

    override var inputAccessoryViewController: UIInputViewController? {
        return self.presentedViewController.isNil ? self.messageInputController : nil
    }
    override var canBecomeFirstResponder: Bool {
        return self.presentedViewController.isNil && ConversationsManager.shared.activeConversation.exists
    }

    @Published var state: ConversationUIState = .read

    /// The id of the conversation this VC will display.
    private let cid: ConversationId
    private let startingMessageID: MessageId?
    private let openReplies: Bool

    init(cid: ConversationId,
         startingMessageID: MessageId?,
         openReplies: Bool) {

        self.cid = cid
        self.startingMessageID = startingMessageID
        self.openReplies = openReplies

        let filter: Filter<ChannelListFilterScope> = .equal(.cid, to: cid)

        let query = ChannelListQuery(filter: filter, messagesLimit: .messagesPageSize)
        
        self.conversationListController = ChatClient.shared.channelListController(query: query)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()
        
        self.view.set(backgroundColor: .B0)
        
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
        self.collectionView.match(.top, to: .bottom, of: self.headerVC.view, offset: .xtraLong)
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
        self.collectionView.animationView.play()
        
        try? await self.conversationListController.synchronize()
        try? await self.conversationListController.loadNextConversations(limit: .channelsPageSize)

        let conversations = self.conversationListController.conversations

        let snapshot = self.dataSource.updatedSnapshot(with: self.conversationListController)

        // Automatically scroll to the conversation.
        let startingIndexPath: IndexPath
        if let conversationIndexPath = snapshot.indexPathOfItem(.conversation(cid)) {
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

        self.collectionView.animationView.stop()

        Task {
            await self.scrollToConversation(with: self.cid,
                                            messageId: self.startingMessageID,
                                            viewReplies: self.openReplies)
        }.add(to: self.autocancelTaskPool)
    }

    @MainActor
    func scrollToConversation(with cid: ConversationId,
                              messageId: MessageId?,
                              viewReplies: Bool = false,
                              animateScroll: Bool = true,
                              animateSelection: Bool = true) async {
        
        guard let conversationIndexPath = self.dataSource.indexPath(for: .conversation(cid)) else { return }
        self.collectionView.scrollToItem(at: conversationIndexPath,
                                         at: .centeredHorizontally,
                                         animated: true)
        
        guard let cell = self.collectionView.cellForItem(at: conversationIndexPath),
              let messagesCell = cell as? ConversationMessagesCell else {
            return
        }

        guard let messageId = messageId else {
            self.collectionView.scrollToItem(at: conversationIndexPath,
                                             at: .centeredHorizontally,
                                             animated: false)
            return
        }

        let messageController = ChatClient.shared.messageController(cid: cid, messageId: messageId)
        try? await messageController.synchronize()
        guard let message = messageController.message else { return }

        // Determine if this is a reply message or regular message.
        if let parentMessageId = message.parentMessageId {
            // It's a reply, select the parent message so we can open the thread experience.
            await messagesCell.scrollToMessage(with: parentMessageId,
                                               animateScroll: animateScroll,
                                               animateSelection: animateSelection)

            if let messageCell = messagesCell.getFrontmostCell() {
                self.messageContentDelegate?.messageContent(messageCell.content,
                                                            didTapMessage: (cid, messageId))
            }
        } else if viewReplies {
            // It's not a parent message, but we still want to see the replies.
            await messagesCell.scrollToMessage(with: messageId,
                                               animateScroll: animateScroll,
                                               animateSelection: animateSelection)

            if let messageCell = messagesCell.getFrontmostCell() {
                self.messageContentDelegate?.messageContent(messageCell.content,
                                                            didTapViewReplies: (cid, messageId))
            }
        } else {
            await messagesCell.scrollToMessage(with: messageId,
                                               animateScroll: animateScroll,
                                               animateSelection: animateSelection)
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
                await ToastScheduler.shared.schedule(toastType: .error(error))
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

        self.updateUI(withCenteredCid: cid)
    }

    /// A task for updating the message input accessory.
    private var messageInputTask: Task<Void, Never>?
    /// A task to become or resign first responder status.
    private var firstResponderTask: Task<Void, Never>?

    private func updateUI(withCenteredCid cid: ConversationId?) {
        self.messageInputTask?.cancel()
        self.firstResponderTask?.cancel()

        // Reset the input accessory view.
        self.messageInputController.updateSwipeHint(shouldPlay: false)

        if let cid = cid, let conversation = Conversation.conversation(cid) {
            
            // Sets the active conversation
            ConversationsManager.shared.activeConversation = conversation
            ConversationsManager.shared.activeController = ConversationController.controller(cid)

            self.messageInputTask = Task { [weak self] in
                let people = await PeopleStore.shared.getPeople(for: conversation)

                guard !Task.isCancelled else { return }

                self?.messageInputController.resetExpression()
                self?.messageInputController.swipeInputView.textView.setPlaceholder(for: people,
                                                                                    isReply: false)
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
            ConversationsManager.shared.activeController = nil

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

extension ConversationViewController: MessageSendingViewControllerType {

    func getCurrentMessageSequence() -> MessageSequence? {
        return self.getCurrentConversationController()?.conversation
    }

    func set(messageSequencePreparingToSend: MessageSequence?) {
        self.dataSource.set(conversationPreparingToSend: messageSequencePreparingToSend?.streamCID)
    }

    func sendMessage(_ message: Sendable) async throws {
        guard let cid = self.getCurrentMessageSequence()?.streamCID else { return }

        let conversationController = ChatClient.shared.channelController(for: cid)

        try await conversationController.createNewMessage(with: message)
    }
}

// MARK: - TransitionableViewController

extension ConversationViewController: TransitionableViewController {

    var presentationType: TransitionType {
        return .fadeOutIn
    }

    var dismissalType: TransitionType {
        return self.presentationType
    }

    func getFromVCPresentationType(for toVCPresentationType: TransitionType) -> TransitionType {
        switch toVCPresentationType {
        case .message:
            guard let messageContent = self.getCentmostMessageCellContent() else { break }
            return .message(messageContent)
        default:
            break
        }

        return toVCPresentationType
    }

    func getToVCDismissalType(for fromVCDismissalType: TransitionType) -> TransitionType {
        switch fromVCDismissalType {
        case .message:
            guard let messageContent = self.getCentmostMessageCellContent() else { break }
            return .message(messageContent)
        default:
            break
        }

        return fromVCDismissalType
    }

    func getCentmostMessageCellContent() -> MessageContentView? {
        guard let messagesCell = self.collectionView.getCentermostVisibleCell() as? ConversationMessagesCell else {
            return nil
        }

        return messagesCell.getFrontmostCell()?.content
    }
}

extension ConversationViewController: MessageInteractableController {
    
    var messageContent: MessageContentView {
        return self.getCentmostMessageCellContent()!
    }
    
    func handleDismissal() {}
    func handleInitialDismissal() {}
    func handleFinalPresentation() {}
    func handlePresentationCompleted() {}
    func handleCompletedDismissal() {}
}
