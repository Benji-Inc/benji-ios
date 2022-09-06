//
//  CalendarCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator

class CalendarCoordinator: PresentableCoordinator<Void> {
    
    lazy var calendarVC = CalendarViewController(with: self.person)
    private let person: PersonType
    
    init(with person: PersonType,
         router: CoordinatorRouter,
         deepLink: DeepLinkable?) {
        
        self.person = person
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.calendarVC
    }
}
