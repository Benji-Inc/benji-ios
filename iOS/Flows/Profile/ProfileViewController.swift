//
//  UserProfileViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ProfileViewController: ViewController {
    
    private var avatar: Avatar
    
    private let header = ProfileHeaderView()
    private lazy var contextCuesVC = ContextCuesViewController()
    private lazy var conversationsVC = UserConversationsViewController()
    
    private let bottomGradientView = GradientView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .bottomCenter,
                                                  endPoint: .topCenter)
        
    init(with avatar: Avatar) {
        self.avatar = avatar
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
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        
        self.view.set(backgroundColor: .B0)
                
        self.view.addSubview(self.header)
        self.addChild(viewController: self.contextCuesVC, toView: self.view)
        self.addChild(viewController: self.conversationsVC, toView: self.view)
        
        self.view.addSubview(self.bottomGradientView)
        
        Task {
            if let user = self.avatar as? User,
               let updated = try? await user.retrieveDataIfNeeded() {
                self.avatar = updated
            }
            
            self.header.configure(with: self.avatar)
        }.add(to: self.autocancelTaskPool)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.header.expandToSuperviewWidth()
        self.header.height = 220
        self.header.pinToSafeAreaTop()
        
        self.contextCuesVC.view.expandToSuperviewWidth()
        self.contextCuesVC.view.height = 130
        self.contextCuesVC.view.match(.top, to: .bottom, of: self.header)
        
        self.conversationsVC.view.width = self.view.width - Theme.ContentOffset.xtraLong.value.doubled
        self.conversationsVC.view.match(.top, to: .bottom, of: self.contextCuesVC.view)
        self.conversationsVC.view.height = self.view.height - self.contextCuesVC.view.bottom
        self.conversationsVC.view.centerOnX()
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
    }
}
