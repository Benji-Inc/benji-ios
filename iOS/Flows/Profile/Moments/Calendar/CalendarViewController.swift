//
//  CalendarViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CalendarViewController: DiffableCollectionViewController<CalendarDataSource.SectionType,
                              CalendarDataSource.ItemType,
                              CalendarDataSource> {
    
    private let darkBlurView = DarkBlurView()
    let daysOfTheWeekView = MomentsHeaderView.init(frame: .zero)
    
    let person: PersonType
    
    init(with person: PersonType) {
        self.person = person
        super.init(with: CalendarCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.preferredCornerRadius = Theme.screenRadius
        }
        
        self.view.insertSubview(self.darkBlurView, at: 0)
        self.view.insertSubview(self.daysOfTheWeekView, aboveSubview: self.collectionView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.daysOfTheWeekView.expandToSuperviewWidth()
        self.daysOfTheWeekView.height = 40
        self.daysOfTheWeekView.pin(.top)
    }
    
    override func getAllSections() -> [CalendarDataSource.SectionType] {
        return []
    }
    
    override func retrieveDataForSnapshot() async -> [CalendarDataSource.SectionType : [CalendarDataSource.ItemType]] {
        return [:]
    }
}
