//
//  MessageDetailViewController.swift
//  Jibber
//
//  Created by Martin Young on 2/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Transitions

class MessageDetailViewController: DiffableCollectionViewController<MessageDetailDataSource.SectionType,
                                   MessageDetailDataSource.ItemType,
                                   MessageDetailDataSource>,
                                   MessageInteractableController {
    var blurView = DarkBlurView()
    
    lazy var dismissInteractionController: PanDismissInteractionController? = PanDismissInteractionController(viewController: self)

    private(set) var message: Messageable
    var messageController: MessageController?
    
    var messageContent: MessageContentView? {
        return self.messageContentView
    }
    
    private let topGradientView = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .topCenter,
                                                  endPoint: .bottomCenter)
    
    private let bottomGradientView = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .bottomCenter,
                                                  endPoint: .topCenter)
    
    private let messageContentView = MessageContentView()
    
    let pullView = PullView()
    
    init(message: Messageable) {
        self.message = message
        
        super.init(with: MessageDetailCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .overCurrentContext
        
        self.dismissInteractionController?.handlePan(for: self.messageContentView)
        self.dismissInteractionController?.handleCollectionViewPan(for: self.collectionView)
        self.dismissInteractionController?.handlePan(for: self.pullView)
        
        self.view.addSubview(self.blurView)
        
        self.view.addSubview(self.messageContentView)
        self.messageContentView.configure(with: self.message)
        
        self.view.addSubview(self.pullView)
    
        self.view.addSubview(self.bottomGradientView)
        
        self.collectionView.allowsMultipleSelection = false
        
        self.view.bringSubviewToFront(self.collectionView)
        
        self.view.addSubview(self.bottomGradientView)
        self.view.addSubview(self.topGradientView)
        self.topGradientView.roundCorners()
    }
    
    override func viewDidLayoutSubviews() {
        
        self.blurView.expandToSuperviewSize()
        
        self.messageContentView.centerOnX()
        self.messageContentView.bottom = self.view.height * 0.5
        
        self.pullView.match(.bottom, to: .top, of: self.messageContentView)
        self.pullView.centerOnX()
        
        super.viewDidLayoutSubviews()
        
        self.topGradientView.expandToSuperviewWidth()
        self.topGradientView.height = Theme.ContentOffset.xtraLong.value
    
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
    }
    
    override func layoutCollectionView(_ collectionView: UICollectionView) {
        self.collectionView.expandToSuperviewWidth()
        self.collectionView.height = self.view.height - self.messageContentView.bottom - Theme.ContentOffset.xtraLong.value
    }
    
    override func collectionViewDataWasLoaded() {
        super.collectionViewDataWasLoaded()
        
        self.subscribeToUpdates()
    }
    
    override func getAllSections() -> [MessageDetailDataSource.SectionType] {
        return MessageDetailDataSource.SectionType.allCases
    }

    @MainActor
    override func retrieveDataForSnapshot() async -> [MessageDetailDataSource.SectionType : [MessageDetailDataSource.ItemType]] {
        var data: [MessageDetailDataSource.SectionType : [MessageDetailDataSource.ItemType]] = [:]
    
        guard let controller = ChatClient.shared.messageController(for: self.message),
                let msg = controller.message else { return data }
        
        self.messageController = controller
        
        if let details = msg.pinDetails, details.pinnedBy.isCurrentUser {
            data[.options] = [.option(.viewThread), .option(.unpin), .option(.quote), .more(MoreOptionModel(message: msg, option: .more))].reversed()
        } else {
            data[.options] = [.option(.viewThread), .option(.pin), .option(.quote), .more(MoreOptionModel(message: msg, option: .more))].reversed()
        }
            
        let reads:[MessageDetailDataSource.ItemType] = msg.readReactions.filter({ reaction in
            return !reaction.author.isCurrentUser
        }).compactMap({ read in
            return .read(ReadViewModel(readReaction: read))
        })
        
        if reads.isEmpty {
            data[.reads] = [.read(ReadViewModel(readReaction: nil))]
        } else {
            data[.reads] = reads
        }
        
        data[.metadata] = [.info(msg)]
        
        return data
    }
    
    private func subscribeToUpdates() {
        
        self.messageController?
            .messageChangePublisher
            .mainSink(receiveValue: { [unowned self] change in
                switch change {
                case .create(let msg):
                    self.message = msg
                case .update(let msg):
                    self.message = msg
                case .remove(let msg):
                    self.message = msg
                }
                self.messageContentView.configure(with: self.message)
                self.reloadDetailData()
            }).store(in: &self.cancellables)
    }
    
    /// The currently running task that is loading.
    private var loadTask: Task<Void, Never>?
    
    private func reloadDetailData() {
        self.loadTask?.cancel()
        
        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            guard let controller = self.messageController, let msg = controller.message else { return }
            
            try? await controller.synchronize()
                        
            var snapshot = self.dataSource.snapshot()
            
            let optionItems: [MessageDetailDataSource.ItemType]
            if let details = msg.pinDetails, details.pinnedBy.isCurrentUser {
                optionItems = [.option(.viewThread),
                               .option(.unpin),
                               .option(.quote),
                               .more(MoreOptionModel(message: msg, option: .more))].reversed()
            } else {
                optionItems = [.option(.viewThread),
                               .option(.pin),
                               .option(.quote),
                               .more(MoreOptionModel(message: msg, option: .more))]
                    .reversed()
            }
            
            snapshot.setItems(optionItems, in: .options)

            let reads: [MessageDetailDataSource.ItemType] = msg.readReactions.filter({ reaction in
                return !reaction.author.isCurrentUser
            }).compactMap({ read in
                return .read(ReadViewModel(readReaction: read))
            })
            
            if reads.isEmpty {
                snapshot.setItems([.read(ReadViewModel(readReaction: nil))], in: .reads)
            } else {
                snapshot.setItems(reads, in: .reads)
            }
            
            snapshot.setItems([.info(msg)], in: .metadata)
            
            await self.dataSource.apply(snapshot)
        }
    }
}

extension MessageDetailViewController: TransitionableViewController {

    var presentationType: TransitionType {
        return .custom(type: "message", model: self.messageContentView, duration: Theme.animationDurationSlow)
    }

    var dismissalType: TransitionType {
        return .custom(type: "message", model: self.messageContentView, duration: Theme.animationDurationSlow)
    }

    func getFromVCPresentationType(for toVCPresentationType: TransitionType) -> TransitionType {
        switch toVCPresentationType {
        case .custom(type: let type, _, _):
            guard type == "message" else { return toVCPresentationType }
            return .custom(type: "message", model: self.messageContentView, duration: Theme.animationDurationSlow)
        default:
            return toVCPresentationType
        }
    }

    func getToVCDismissalType(for fromVCDismissalType: TransitionType) -> TransitionType {
        switch fromVCDismissalType {
        case .custom(type: let type, _, _):
            guard type == "message" else { return fromVCDismissalType }
            return .custom(type: "message", model: self.messageContentView, duration: Theme.animationDurationSlow)
        default:
            return fromVCDismissalType
        }
    }
    
    func prepareForPresentation() {
        self.collectionView.top = self.view.height
        self.topGradientView.match(.top, to: .top, of: self.collectionView)
        self.loadInitialData()
    }
    
    func handlePresentationCompleted() {}
    
    func handleFinalPresentation() {
        self.collectionView.pin(.bottom)
        self.topGradientView.match(.top, to: .top, of: self.collectionView)
        self.view.setNeedsLayout()
    }
    func handleInitialDismissal() {}
    
    func handleDismissal() {
        self.pullView.match(.bottom, to: .top, of: self.messageContentView)
        self.collectionView.top = self.view.height
        self.topGradientView.match(.top, to: .top, of: self.collectionView)
    }
}
