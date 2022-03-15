//
//  newWelcomeViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Parse
import Combine

class WelcomeViewController: DiffableCollectionViewController<MessageSequenceSection,
                             MessageSequenceItem,
                             MessageSequenceCollectionViewDataSource>,
                             Sizeable,
                             Completable {
    
    typealias ResultType = SelectionType
    
    enum SelectionType {
        case waitlist
        case rsvp
    }
    
    var didLoadConversation: ((Conversation) -> Void)? 
    var onDidComplete: ((Result<SelectionType, Error>) -> Void)?
    
    let waitlistButton = ThemeButton()
    let rsvpButton = ThemeButton()
        
    var welcomeCollectionView: WelcomeCollectionView {
        return self.collectionView as! WelcomeCollectionView
    }
    
    private(set) var conversationController: ConversationController?
    
    override var analyticsIdentifier: String? {
        return "SCREEN_WELCOME"
    }
    
    init() {
        super.init(with: WelcomeCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()
        
        self.welcomeCollectionView.timeMachineLayout.dataSource = self.dataSource
        
        self.collectionView.clipsToBounds = false
        
        self.view.addSubview(self.waitlistButton)
        self.waitlistButton.set(style: .custom(color: .D1, textColor: .white, text: "Begin"))
        self.waitlistButton.didSelect { [unowned self] in
            AnalyticsManager.shared.trackEvent(type: .onboardingBeginTapped, properties: nil)
            self.onDidComplete?(.success((.waitlist)))
        }
        
        self.view.addSubview(self.rsvpButton)
        self.rsvpButton.set(style: .custom(color: .B5, textColor: .T4, text: "Enter Code"))
        self.rsvpButton.didSelect { [unowned self] in
            AnalyticsManager.shared.trackEvent(type: .onboardingRSVPTapped, properties: nil)
            self.onDidComplete?(.success((.rsvp)))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInitialData()
    }
    
    override func collectionViewDataWasLoaded() {
        super.collectionViewDataWasLoaded()
        
        if let convo = self.conversationController?.conversation {
            self.didLoadConversation?(convo)
        }
        
        self.updateContentOffset()
    }
    
    override func getAnimationCycle(with snapshot: NSDiffableDataSourceSnapshot<MessageSequenceSection, MessageSequenceItem>) -> AnimationCycle? {
        let count = snapshot.numberOfItems(inSection: .messages) - 1
        let maxOffset = CGFloat(count) * self.welcomeCollectionView.timeMachineLayout.itemHeight
        
        return AnimationCycle(inFromPosition: nil,
                              outToPosition: nil,
                              shouldConcatenate: false,
                              scrollToOffset: CGPoint(x: 0, y: maxOffset))
    }
    
    var scrollTask: Task<Void, Never>?
    func updateContentOffset() {
        // Cancel any currently running scroll tasks.
        self.scrollTask?.cancel()
        
        self.scrollTask = Task { [weak self] in
            guard let `self` = self else { return }
            var currentOffset = self.welcomeCollectionView.contentOffset
            currentOffset.y = round(currentOffset.y / self.welcomeCollectionView.timeMachineLayout.itemHeight) * self.welcomeCollectionView.timeMachineLayout.itemHeight
            
            // Wait 2 seconds before scrolling
            await Task.snooze(seconds: 2)
            // Don't scroll if cancelled.
            guard !Task.isCancelled else { return }
            let yOffset = currentOffset.y - self.welcomeCollectionView.timeMachineLayout.itemHeight
            let newOffset = clamp(yOffset, min: 0)
            self.welcomeCollectionView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: true)
            
            guard !Task.isCancelled else { return }
            await Task.snooze(seconds: 0.3)
            self.updateContentOffset()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.rsvpButton.setSize(with: self.view.width)
        self.rsvpButton.pinToSafeAreaBottom()
        self.rsvpButton.centerOnX()
        
        self.waitlistButton.setSize(with: self.view.width)
        self.waitlistButton.match(.bottom, to: .top, of: self.rsvpButton, offset: .negative(.standard))
        
        self.waitlistButton.centerOnX()
    }
    
    override func layoutCollectionView(_ collectionView: UICollectionView) {
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.pin(.top, offset: .custom(self.view.height * 0.25))
        self.collectionView.width = Theme.getPaddedWidth(with: self.view.width)
        self.collectionView.height = self.view.height - self.collectionView.top
        self.collectionView.centerOnX()
    }
    
    // MARK: Data Loading

    override func getAllSections() -> [MessageSequenceSection] {
        return [.messages]
    }

    override func retrieveDataForSnapshot() async -> [MessageSequenceSection : [MessageSequenceItem]] {
        var data: [MessageSequenceSection: [MessageSequenceItem]] = [:]
        
        do {
            if !ChatClient.isConnected {
                try await ChatClient.connectAnonymousUser()
            }

            guard let conversationId = PFConfig.current().welcomeConversationCID else { return data }
            let cid = ChannelId(type: .custom("onboarding"), id: conversationId)
            let conversationController
            = ChatClient.shared.channelController(for: cid,
                                                     messageOrdering: .topToBottom)

            self.conversationController = conversationController

            // Ensure that we've synchronized the conversation controller with the backend.
            if conversationController.channel.isNil {
                try await conversationController.synchronize()
            } else if let conversation = conversationController.channel, conversation.messages.isEmpty {
                try await conversationController.synchronize()
            }

            try await conversationController.loadPreviousMessages()

            let allMessageItems: [MessageSequenceItem] = conversationController.messages.compactMap({ message in
                guard !message.isDeleted else { return nil }

                return MessageSequenceItem.message(cid: cid,
                                                   messageID: message.id,
                                                   showDetail: false)
            })

            data[.messages] = allMessageItems
        } catch {
            logError(error)
        }
        
        return data
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        super.scrollViewWillBeginDragging(scrollView)
        self.scrollTask?.cancel()
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        self.updateContentOffset()
    }
}
