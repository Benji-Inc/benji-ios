//
//  ConversationDetailCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class ConversationDetailCoordinator: PresentableCoordinator<Void> {
    
    lazy var detailVC = ConversationDetailViewController()

    override func toPresentable() -> DismissableVC {
        return self.detailVC
    }
    
    override func start() {
        super.start()
        
//        self.conversationListVC.headerVC.membersVC.$selectedItems.mainSink { items in
//            guard let first = items.first else { return }
//            switch first {
//            case .member(let member):
//                guard let person = PeopleStore.shared.people.first(where: { person in
//                    return person.personId == member.personId
//                }) else { return }
//
//                self.presentProfile(for: person)
//            default:
//                break
//            }
//        }.store(in: &self.cancellables)
                
    }
}
