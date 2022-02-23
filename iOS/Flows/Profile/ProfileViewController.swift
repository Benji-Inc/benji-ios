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
    
    private let backgroundGradient = BackgroundGradientView()
    private let header = ProfileHeaderView()
    private let contextCuesVC = ContextCuesViewController()
    
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
        
        self.view.addSubview(self.backgroundGradient)
        
        self.view.addSubview(self.header)
        self.addChild(viewController: self.contextCuesVC, toView: self.view)
        
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
        
        self.backgroundGradient.expandToSuperviewWidth()
        self.backgroundGradient.height = self.view.height + 100
        self.backgroundGradient.pin(.top)
        
        self.header.expandToSuperviewWidth()
        self.header.height = 200
        self.header.pinToSafeAreaTop()
        
        self.contextCuesVC.view.expandToSuperviewWidth()
        self.contextCuesVC.view.height = 150
        self.contextCuesVC.view.match(.top, to: .bottom, of: self.header)
    }
}
