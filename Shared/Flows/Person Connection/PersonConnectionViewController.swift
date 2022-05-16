//
//  PersonConnectionViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/16/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PersonConnectionViewController: ViewController {
    
    private var person: PersonType?
    
    lazy var header = ProfileHeaderView()
    let button = ThemeButton()
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        
        self.view.set(backgroundColor: .B0)
                
        self.view.addSubview(self.header)
        self.header.menuButton.isEnabled = false
        self.header.menuImageView.isVisible = false
        
        self.view.addSubview(self.button)
        self.button.set(style: .custom(color: .white, textColor: .B0, text: "Connect"))
        
        PeopleStore.shared
            .$personUpdated
            .filter { [unowned self] updatedPerson in
                // Only handle person updates related to the currently assigned person.
                self.person?.personId ==  updatedPerson?.personId
            }.mainSink { [unowned self] person in
                guard let user = person as? User else { return }
                self.header.configure(with: user)
            }.store(in: &self.cancellables)
    }
    
    func configure(for person: PersonType) {
        Task { [unowned self] in
            guard let updatedPerson = await PeopleStore.shared.getPerson(withPersonId: person.personId) else {
                return
            }

            guard !Task.isCancelled else { return }

            self.person = updatedPerson

            self.header.configure(with: updatedPerson)
            self.view.setNeedsLayout()
        }.add(to: self.autocancelTaskPool)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.header.expandToSuperviewWidth()
        self.header.height = ProfileHeaderView.height
        self.header.pinToSafeArea(.top, offset: .xtraLong)
        
        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        self.button.pinToSafeAreaBottom()
    }
}
        
