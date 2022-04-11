//
//  PeopleNavigationController.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PeopleNavigationController: NavigationController {
    
    lazy var peopleVC = PeopleViewController(shouldShowConnections: self.showConnections)
    let showConnections: Bool
    
    init(showConnections: Bool) {
        self.showConnections = showConnections
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
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        let textAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: ThemeColor.T1.color,
                                                             .font : FontType.regularBold.font]
        self.navigationBar.titleTextAttributes = textAttributes
                
        self.setViewControllers([self.peopleVC], animated: false)
    }
    
    func prepareForInvitations() {
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
        }
        
        self.setNavigationBarHidden(true, animated: true)
    }
}
