//
//  MembersViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine
import ParseLiveQuery

class ConversationDetailViewController: DiffableCollectionViewController<ConversationDetailCollectionViewDataSource.SectionType,
                                        ConversationDetailCollectionViewDataSource.ItemType,
                                        ConversationDetailCollectionViewDataSource>,
                                        ActiveConversationable {
    
    var conversationController: ConversationController?
    
    init() {
        let cv = CollectionView(layout: ConversationDetailCollectionViewLayout())
        cv.showsHorizontalScrollIndicator = false
        super.init(with: cv)
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
        
        self.view.set(backgroundColor: .B0)
        
        self.collectionView.allowsMultipleSelection = false
        
        ConversationsManager.shared.$activeConversation
            .removeDuplicates()
            .mainSink { [unowned self] conversation in
                self.startLoadDataTask(with: conversation)
            }.store(in: &self.cancellables)
        
        Client.shared.shouldPrintWebSocketLog = false
        let reservationQuery = Reservation.allUnclaimedWithContactQuery()
        let reservationSubscription = Client.shared.subscribe(reservationQuery)
        reservationSubscription.handleEvent { [unowned self] query, event in
            guard let conversationController = self.conversationController else { return }
            
            // If a reservation related to this conversation is updated, then reload the data.
            switch event {
            case .entered(let object), .created(let object),
                    .updated(let object), .left(let object), .deleted(let object):
                
                guard let reservation = object as? Reservation,
                      let cid = reservation.conversationCid else { return }
                
                let conversation = conversationController.conversation
                
                guard cid == conversationController.cid?.description else { return }
                self.startLoadDataTask(with: conversation)
            }
        }
    }
    
    /// A task for loading data and subscribing to conversation updates.
    private var loadDataTask: Task<Void, Never>?
    
    private func startLoadDataTask(with conversation: Conversation?) {
        self.loadDataTask?.cancel()
        
        if let cid = conversation?.cid {
            self.conversationController = ConversationController.controller(cid)
        } else {
            self.conversationController = nil
        }
        
        self.loadDataTask = Task { [weak self] in
            guard let conversationController = self?.conversationController else {
                // If there's no current conversation, then there's nothing to show.
                await self?.dataSource.deleteAllItems()
                return
            }
            
            await self?.loadData()
            
            guard !Task.isCancelled else { return }
            
            self?.subscribeToUpdates(for: conversationController)
        }
    }
    
    /// The subscriptions for the current conversation.
    private var conversationCancellables = Set<AnyCancellable>()
    
    private func subscribeToUpdates(for conversationController: ConversationController) {
        // Clear out previous subscriptions.
        self.conversationCancellables.removeAll()
        
        conversationController
            .typingUsersPublisher
            .mainSink(receiveValue: { [unowned self] typingUsers in
                self.dataSource.reconfigureAllItems()
            }).store(in: &self.conversationCancellables)
        
        conversationController
            .memberEventPublisher
            .mainSink(receiveValue: { [unowned self] event in
                switch event as MemberEvent {
                case let event as MemberAddedEvent:
                    self.add(member: event.member)
                case let event as MemberRemovedEvent:
                    guard let conversationController = self.conversationController else { return }
                    let member = Member(personId: event.user.personId,
                                        conversationController: conversationController)
                    self.dataSource.deleteItems([.member(member)])
                case let event as MemberUpdatedEvent:
                    guard let conversationController = self.conversationController else { return }
                    let member = Member(personId: event.member.personId,
                                        conversationController: conversationController)
                    self.dataSource.reconfigureItems([.member(member)])
                default:
                    break
                }
            }).store(in: &self.conversationCancellables)
    }
    
    private func add(member: ChatChannelMember) {
        guard let conversationController = self.conversationController else { return }
        
        let member = Member(personId: member.personId, conversationController: conversationController)
        self.dataSource.appendItems([.member(member)], toSection: .people)
    }
    
    /// A task for scrolling to a specific chat user.
    private var scrollToUserTask: Task<Void, Never>?
    
    func scroll(to user: ChatUser) {
        self.scrollToUserTask?.cancel()
        
        self.scrollToUserTask = Task { [weak self] in
            // Wait for the data to finish loading before we try to scroll to a specific user.
            await self?.loadDataTask?.value
            
            guard !Task.isCancelled,
                  let controller = self?.conversationController else { return }
            
            let member = Member(personId: user.personId, conversationController: controller)
            guard let ip = self?.dataSource.indexPath(for: .member(member)) else { return }
            
            self?.collectionView.scrollToItem(at: ip, at: .centeredHorizontally, animated: true)
        }
    }
    
    // MARK: - Data Loading
    
    override func getAnimationCycle(with snapshot: NSDiffableDataSourceSnapshot<ConversationDetailSectionType, ConversationDetailItemType>)
    -> AnimationCycle? {
        
        // Center on the user who sent the most recent message.
        var centeredIndexPath = IndexPath(item: 0, section: 0)
        if let conversationController = conversationController,
           let nonCurrentUserMessage = conversationController.messages.first(where: { message in
               return !message.isFromCurrentUser
           }) {
            let user = nonCurrentUserMessage.author
            let member = Member(personId: user.personId, conversationController: conversationController)
            
            if let memberIndexPath = snapshot.indexPathOfItem(.member(member)) {
                centeredIndexPath = memberIndexPath
            }
        }
        
        return AnimationCycle(inFromPosition: nil,
                              outToPosition: nil,
                              shouldConcatenate: false,
                              scrollToIndexPath: centeredIndexPath)
    }
    
    override func getAllSections() -> [ConversationDetailCollectionViewDataSource.SectionType] {
        return ConversationDetailCollectionViewDataSource.SectionType.allCases
    }
    
    override func retrieveDataForSnapshot() async -> [ConversationDetailCollectionViewDataSource.SectionType: [ConversationDetailCollectionViewDataSource.ItemType]] {
        
        var data: [ConversationDetailCollectionViewDataSource.SectionType: [ConversationDetailCollectionViewDataSource.ItemType]] = [:]
        
        guard let conversationController = self.conversationController else { return data }
        let conversation = conversationController.conversation
        
        let members = await PeopleStore.shared.getPeople(for: conversation)
        
        data[.people] = members.compactMap({ member in
            let member = Member(personId: member.personId,
                                conversationController: conversationController)
            return .member(member)
        })
        
        data[.people]?.append(.add(conversation.cid))
        
        return data
    }
}
