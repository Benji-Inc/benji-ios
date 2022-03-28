//
//  MessageDetailViewController.swift
//  Jibber
//
//  Created by Martin Young on 2/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

@MainActor
protocol MessageDetailViewControllerDelegate: AnyObject {
    func messageDetailViewController(_ controller: MessageDetailViewController,
                                     didSelectThreadFor message: Messageable)
}

class MessageDetailViewController: DiffableCollectionViewController<MessageDetailDataSource.SectionType,
                                   MessageDetailDataSource.ItemType,
                                   MessageDetailDataSource>,
                                   MessageInteractableController {
    var blurView = BlurView()
    
    lazy var dismissInteractionController = PanDismissInteractionController(viewController: self)

    let message: Messageable
    unowned let delegate: MessageDetailViewControllerDelegate
    
    var messageContent: MessageContentView {
        return self.messageContentView
    }
    
    private let bottomGradientView = GradientView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .bottomCenter,
                                                  endPoint: .topCenter)
    
    private let messageContentView = MessageContentView()
    
    init(message: Messageable, delegate: MessageDetailViewControllerDelegate) {
        self.message = message
        self.delegate = delegate
        
        super.init(with: MessageDetailCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .overCurrentContext
        
        self.dismissInteractionController.handlePan(for: self.messageContentView)
        self.dismissInteractionController.handleCollectionViewPan(for: self.collectionView)
        
        self.view.addSubview(self.blurView)
        
        self.view.addSubview(self.messageContentView)
        self.messageContentView.configure(with: self.message)
    
        self.view.addSubview(self.bottomGradientView)
        
        self.collectionView.allowsMultipleSelection = false
        
        self.view.bringSubviewToFront(self.collectionView)
    }
    
    override func viewDidLayoutSubviews() {
        
        self.blurView.expandToSuperviewSize()
        
        self.messageContentView.centerOnX()
        self.messageContentView.bottom = self.view.height * 0.5
        
        super.viewDidLayoutSubviews()
    
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
    }
    
    override func layoutCollectionView(_ collectionView: UICollectionView) {
        self.collectionView.expandToSuperviewWidth()
        self.collectionView.height = self.view.height - self.messageContent.bottom - Theme.ContentOffset.xtraLong.value
       // self.collectionView.pin(.bottom)
    }
    
    override func getAllSections() -> [MessageDetailDataSource.SectionType] {
        return MessageDetailDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [MessageDetailDataSource.SectionType : [MessageDetailDataSource.ItemType]] {
        return [:]
    }
}

extension MessageDetailViewController: TransitionableViewController {
    var receivingPresentationType: TransitionType {
        return .message(self.messageContentView)
    }
    
    var sendingDismissalType: TransitionType {
        return .message(self.messageContentView)
    }
    
    func prepareForPresentation() {
        self.collectionView.top = self.view.height
    }
    
    func handlePresentationCompleted() {}
    
    func handleFinalPresentation() {
        self.collectionView.pin(.bottom)
        self.view.setNeedsLayout()
    }
    func handleInitialDismissal() {}
    
    func handleDismissal() {
        self.collectionView.top = self.view.height
    }
}
