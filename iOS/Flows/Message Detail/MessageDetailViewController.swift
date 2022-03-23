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

class MessageDetailViewController: ViewController, MessageInteractableController {
    
    var blurView = BlurView()
    
    lazy var dismissInteractionController = PanDismissInteractionController(viewController: self)

    let message: Messageable
    unowned let delegate: MessageDetailViewControllerDelegate
    
    var messageContent: MessageContentView {
        return self.messageContentView
    }
    
    private let messageContentView = MessageContentView()
    private let backgroundView = BaseView()
    private let threadButton = ThemeButton()
    
    init(message: Messageable, delegate: MessageDetailViewControllerDelegate) {
        self.message = message
        self.delegate = delegate
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .overCurrentContext
        
        self.dismissInteractionController.handlePan(for: self.messageContentView)
        self.dismissInteractionController.handlePan(for: self.view)
        
        self.view.addSubview(self.blurView)
        
        self.view.addSubview(self.messageContentView)
        self.messageContentView.configure(with: self.message)
        
        
        self.view.addSubview(self.backgroundView)
        self.backgroundView.set(backgroundColor: .B0)
        self.backgroundView.layer.cornerRadius = Theme.cornerRadius
        self.backgroundView.clipsToBounds = true
        
        self.backgroundView.addSubview(self.threadButton)
        self.threadButton.set(style: .normal(color: .gray, text: "Open Thread"))
        self.threadButton.addAction(for: .touchUpInside) { [unowned self] in
            self.delegate.messageDetailViewController(self, didSelectThreadFor: self.message)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.blurView.expandToSuperviewSize()
        
        self.messageContentView.centerOnX()
        self.messageContentView.bottom = self.view.height * 0.6
        
        self.backgroundView.match(.top, to: .bottom, of: self.messageContentView, offset: .xtraLong)
        self.backgroundView.expandToSuperviewWidth()
        self.backgroundView.expand(.bottom)
        
        self.threadButton.width = 150
        self.threadButton.height = Theme.buttonHeight
        self.threadButton.centerOnXAndY()
    }
}

extension MessageDetailViewController: TransitionableViewController {
    var receivingPresentationType: TransitionType {
        return .message(self.messageContentView)
    }
    
    var sendingDismissalType: TransitionType {
        return .message(self.messageContentView)
    }
    
    func handleFinalTransition() {
        //self.detailVC.view.alpha = 1.0
    }
    
    func handleTransitionCompleted() {}
}
