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
    
    private let topGradientView
    = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                   startPoint: .topCenter,
                   endPoint: .bottomCenter)
    
    private let bottomGradientView
      = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                     startPoint: .bottomCenter,
                     endPoint: .topCenter)
        
    let conversationController: ConversationController
    
    init(with cid: ConversationId) {
        self.conversationController = ConversationController.controller(cid)
        let cv = CollectionView(layout: ConversationDetailCollectionViewLayout())
        cv.showsHorizontalScrollIndicator = false
        cv.contentInset = UIEdgeInsets(top: 30,
                                       left: 0,
                                       bottom: 100,
                                       right: 0)
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
        
        self.view.addSubview(self.topGradientView)
        self.view.addSubview(self.bottomGradientView)
        
        self.collectionView.allowsMultipleSelection = false
        
        Client.shared.shouldPrintWebSocketLog = false
        let reservationQuery = Reservation.allUnclaimedWithContactQuery()
        let reservationSubscription = Client.shared.subscribe(reservationQuery)
        reservationSubscription.handleEvent { [unowned self] query, event in
            
            // If a reservation related to this conversation is updated, then reload the data.
            switch event {
            case .entered(let object), .created(let object),
                    .updated(let object), .left(let object), .deleted(let object):
                
                guard let reservation = object as? Reservation,
                      let cid = reservation.conversationCid else { return }
                
                let conversation = conversationController.conversation
                
                guard cid == self.conversationController.cid?.description else { return }
                self.startLoadDataTask(with: conversation)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.startLoadDataTask(with: self.conversationController.conversation)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.topGradientView.expandToSuperviewWidth()
        self.topGradientView.height = Theme.ContentOffset.screenPadding.value
        self.topGradientView.pin(.top)
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
    }
    
    /// A task for loading data and subscribing to conversation updates.
    private var loadDataTask: Task<Void, Never>?
    
    private func startLoadDataTask(with conversation: Conversation?) {
        self.loadDataTask?.cancel()
        
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
                    let member = Member(personId: event.user.personId,
                                        conversationController: self.conversationController)
                    self.dataSource.deleteItems([.member(member)])
                case let event as MemberUpdatedEvent:
                    let member = Member(personId: event.member.personId,
                                        conversationController: self.conversationController)
                    self.dataSource.reconfigureItems([.member(member)])
                default:
                    break
                }
            }).store(in: &self.conversationCancellables)
    }
    
    func reloadPeople(with people: [Person]) async {
        let items: [ConversationDetailItemType] = people.compactMap({ member in
            let member = Member(personId: member.personId,
                                conversationController: self.conversationController)
            return .member(member)
        })
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems([], in: .people)
        snapshot.setItems(items, in: .people)
        await self.dataSource.apply(snapshot)
    }
    
    private func add(member: ChatChannelMember) {
        let member = Member(personId: member.personId, conversationController: self.conversationController)
        self.dataSource.appendItems([.member(member)], toSection: .people)
    }
    
    override func getAllSections() -> [ConversationDetailCollectionViewDataSource.SectionType] {
        return ConversationDetailCollectionViewDataSource.SectionType.allCases
    }
    
    override func retrieveDataForSnapshot() async -> [ConversationDetailCollectionViewDataSource.SectionType: [ConversationDetailCollectionViewDataSource.ItemType]] {
        
        var data: [ConversationDetailSectionType: [ConversationDetailItemType]] = [:]
        
        let conversation = self.conversationController.conversation
        
        data[.info] = [.info(conversation.cid), .editTopic(conversation.cid)]
        
        let members = await PeopleStore.shared.getPeople(for: conversation)
        
        data[.people] = members.compactMap({ member in
            let member = Member(personId: member.personId,
                                conversationController: self.conversationController)
            return .member(member)
        })
        
        var pinnedItems: [ConversationDetailItemType] = conversation.pinnedMessages.compactMap({ message in
            return .pinnedMessage(PinModel(cid: message.cid, messageId: message.id))
        })
        
        if pinnedItems.isEmpty {
            pinnedItems = [.pinnedMessage(PinModel(cid: nil, messageId: nil))]
        }
        
        data[.pins] = pinnedItems
        
        if conversation.isOwnedByMe {
            data[.people]?.append(.detail(.add))
            data[.options] = [.detail(.hide), .detail(.leave), .detail(.delete)]
        } else {
            data[.options] = [.detail(.hide), .detail(.leave)]
        }
        
        return data
    }
}
