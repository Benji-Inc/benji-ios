//
//  PeopleNavigationController.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PeopleNavigationController: NavigationController {
    
    lazy var peopleVC = PeopleViewController()
    
    override func initializeViews() {
        super.initializeViews()
                
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.medium(), .large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
                
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
