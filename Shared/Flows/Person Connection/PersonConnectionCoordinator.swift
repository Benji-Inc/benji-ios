//
//  PersonConnectionCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/16/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PersonConnectionCoordinator: PresentableCoordinator<Void> {
    
    lazy var vc = PersonConnectionViewController(with: self.person)
    private let person: PersonType
    
    init(with person: PersonType,
         router: Router,
         deepLink: DeepLinkable?) {
        
        self.person = person
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.vc
    }
    
    override func start() {
        super.start()
        
        
    }
}
