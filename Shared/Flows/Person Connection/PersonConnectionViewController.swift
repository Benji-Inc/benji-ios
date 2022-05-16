//
//  PersonConnectionViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/16/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PersonConnectionViewController: ViewController {
    private var person: PersonType
    
    lazy var header = ProfileHeaderView()
    
    init(with person: PersonType) {
        self.person = person
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
        
        PeopleStore.shared
            .$personUpdated
            .filter { [unowned self] updatedPerson in
                // Only handle person updates related to the currently assigned person.
                self.person.personId ==  updatedPerson?.personId
            }.mainSink { [unowned self] person in
                guard let user = person as? User else { return }
                self.header.configure(with: user)
            }.store(in: &self.cancellables)
        
        Task { [unowned self] in
            guard let updatedPerson = await PeopleStore.shared.getPerson(withPersonId: self.person.personId) else {
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
    }
}
        
