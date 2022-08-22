//
//  CommentsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import PhotosUI
import Transitions

/// A view controller for displaying a single conversation.
class CommentsViewController: InputHandlerViewContoller,
                                  ConversationListCollectionViewLayoutDelegate {
    
    override var analyticsIdentifier: String? {
        return "SCREEN_COMMENTS"
    }
    
    var messageContentDelegate: MessageContentDelegate? {
        get { return self.dataSource.messageContentDelegate}
        set { self.dataSource.messageContentDelegate = newValue }
    }
    
    lazy var dismissInteractionController: PanDismissInteractionController? = nil

    // Collection View
    lazy var dataSource = ConversationCollectionViewDataSource(collectionView: self.collectionView)
    lazy var collectionView = ConversationListCollectionView()

    var blurView = DarkBlurView()

    private(set) var conversationController: ConversationController?

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
        return self.presentedViewController.isNil
    }

    @Published var state: ConversationUIState = .read

    /// The id of the conversation this VC will display.
    @Published var conversationId: String?
    var startingMessageId: String?
    private let openReplies: Bool

    init(conversationId: String?,
         startingMessageId: String?,
         openReplies: Bool) {

        self.conversationId = conversationId
        self.startingMessageId = startingMessageId
        self.openReplies = openReplies

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        
        self.view.insertSubview(self.blurView, belowSubview: self.collectionView)
                
        self.view.addSubview(self.collectionView)
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.conversationLayout.delegate = self
        self.dataSource.uiState = .write
        
        self.subscribeToUIUpdates()
        self.setupInputHandlers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard self.presentedViewController.isNil else { return }
        
        self.blurView.expandToSuperviewSize()
        self.collectionView.expandToSuperviewWidth()
        self.collectionView.height = self.view.height - self.view.safeAreaInsets.top - 30
        self.collectionView.pin(.top, offset: .xtraLong)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        once(caller: self, token: "initializeCollectionView") {
            
            self.$conversationId
                .removeDuplicates()
                .mainSink { [unowned self] conversationId in
                
                    if let conversationId = conversationId {
                        Task {
                            // Initialize the datasource before listening for updates to ensure that the sections
                            // are set up.
                            guard let controller = JibberChatClient.shared.conversationController(for: conversationId)  else {
                                return
                            }

                            self.conversationController = controller
                            await self.initializeDataSource()
                            self.subscribeToConversationUpdates()
                        }
                    }
                }.store(in: &self.cancellables)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.resignFirstResponder()
    }
    
    override func viewWasDismissed() {
        super.viewWasDismissed()
        
        ConversationsManager.shared.activeConversation = nil
    }

    func updateUI(for state: ConversationUIState, forceLayout: Bool = false) {
        guard self.presentedViewController.isNil || forceLayout else { return }
        
        self.dataSource.uiState = state
        self.dataSource.reconfigureAllItems()
    }

    // MARK: - Message Loading and Updates

    @MainActor
    func initializeDataSource() async {
        guard let controller = self.conversationController else {
            return
        }

        self.collectionView.animationView.play()
        
        try? await controller.synchronize()

        let snapshot = self.dataSource.updatedSnapshot(with: controller)

        let animationCycle = AnimationCycle(inFromPosition: .inward,
                                            outToPosition: .inward,
                                            shouldConcatenate: false)

        await self.dataSource.apply(snapshot,
                                    collectionView: self.collectionView,
                                    animationCycle: animationCycle)

        self.collectionView.animationView.stop()

        Task {
            if let conversationId = conversationId {
                await self.scrollToConversation(with: conversationId,
                                                messageId: self.startingMessageId,
                                                viewReplies: self.openReplies)
            }
        }.add(to: self.autocancelTaskPool)
    }

    @MainActor
    func scrollToConversation(with conversationId: String,
                              messageId: String?,
                              viewReplies: Bool = false,
                              animateScroll: Bool = true,
                              animateSelection: Bool = true) async {
        
        guard let conversationIndexPath = self.dataSource.indexPath(for: .conversation(conversationId)) else { return }
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

        let messageController = JibberChatClient.shared.messageController(for: conversationId, id: messageId)
        try? await messageController?.synchronize()
        guard let message = messageController?.message else { return }

        // Determine if this is a reply message or regular message.
        if let parentMessageId = message.parentMessageId {
            // It's a reply, select the parent message so we can open the thread experience.
            await messagesCell.scrollToMessage(with: parentMessageId,
                                               animateScroll: animateScroll,
                                               animateSelection: animateSelection)

            if let messageCell = messagesCell.getFrontmostCell() {
                self.messageContentDelegate?.messageContent(messageCell.content,
                                                            didTapMessage: message)
            }
        } else if viewReplies {
            // It's not a parent message, but we still want to see the replies.
            await messagesCell.scrollToMessage(with: messageId,
                                               animateScroll: animateScroll,
                                               animateSelection: animateSelection)

            if let messageCell = messagesCell.getFrontmostCell() {
                self.messageContentDelegate?.messageContent(messageCell.content,
                                                            didTapViewReplies: message)
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

    // MARK: - ConversationListCollectionViewLayoutDelegate

    func conversationListCollectionViewLayout(_ layout: ConversationListCollectionViewLayout,
                                              conversationIdFor indexPath: IndexPath) -> String? {

        let item = self.dataSource.itemIdentifier(for: indexPath)
        switch item {
        case .conversation(let conversationId):
            return conversationId
        case .none:
            return nil
        }
    }

    func conversationListCollectionViewLayout(_ layout: ConversationListCollectionViewLayout,
                                              didUpdateCentered conversationId: String?) {

        self.updateUI(withCenteredConversationId: conversationId)
    }

    /// A task for updating the message input accessory.
    private var messageInputTask: Task<Void, Never>?
    /// A task to become or resign first responder status.
    private var firstResponderTask: Task<Void, Never>?

    private func updateUI(withCenteredConversationId conversationId: String?) {
        self.messageInputTask?.cancel()
        self.firstResponderTask?.cancel()

        // Reset the input accessory view.
        self.messageInputController.updateSwipeHint(shouldPlay: false)

        if let conversationId = conversationId, let controller = JibberChatClient.shared.conversationController(for: conversationId) {
            
            // Sets the active conversation
            ConversationsManager.shared.activeConversation = controller.conversation
            ConversationsManager.shared.activeController = controller

            self.messageInputTask = Task { [weak self] in
                let people = await JibberChatClient.shared.getPeople(for: controller.conversation!)

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

extension CommentsViewController: MessageSendingViewControllerType {

    func getCurrentMessageSequence() -> MessageSequence? {
        return self.getCurrentConversationController()?.conversation
    }

    func set(messageSequencePreparingToSend: MessageSequence?) {
        self.dataSource.set(conversationPreparingToSend: messageSequencePreparingToSend?.id)
    }

    func sendMessage(_ message: Sendable) async throws {
        guard let conversationId = self.getCurrentMessageSequence()?.id else { return }

        let conversationController = JibberChatClient.shared.conversationController(for: conversationId)

        try await conversationController?.createNewMessage(with: message)
    }
}

// MARK: - TransitionableViewController

extension CommentsViewController: TransitionableViewController {

    var presentationType: TransitionType {
        return .modal
    }

    func getFromVCPresentationType(for toVCPresentationType: TransitionType) -> TransitionType {
        switch toVCPresentationType {
        case .custom(type: let type, _, _):
            guard type == "message", let messageContent = self.getCentmostMessageCellContent() else { return toVCPresentationType }
            return .custom(type: "message", model: messageContent, duration: Theme.animationDurationSlow)
        default:
            break
        }

        return toVCPresentationType
    }

    func getToVCDismissalType(for fromVCDismissalType: TransitionType) -> TransitionType {
        switch fromVCDismissalType {
        case .custom(type: let type, _, _):
            guard type == "message", let messageContent = self.getCentmostMessageCellContent() else { return fromVCDismissalType }
            return .custom(type: "message", model: messageContent, duration: Theme.animationDurationSlow)
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

extension CommentsViewController: MessageInteractableController {
    
    var messageContent: MessageContentView? {
        return self.getCentmostMessageCellContent()
    }
    
    func handleDismissal() {}
    func handleInitialDismissal() {}
    func handleFinalPresentation() {}
    func handlePresentationCompleted() {}
    func handleCompletedDismissal() {}
}
