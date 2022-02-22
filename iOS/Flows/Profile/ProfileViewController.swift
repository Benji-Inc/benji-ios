//
//  UserProfileViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ProfileViewController: ViewController {
    
    private let avatar: Avatar
    
    private let backgroundGradient = BackgroundGradientView()
    private let header = ProfileHeaderView()
    
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
        self.header.configure(with: self.avatar)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.backgroundGradient.expandToSuperviewSize()
        
        self.header.expandToSuperviewWidth()
        self.header.height = 200
        self.header.pin(.top)
    }
}
