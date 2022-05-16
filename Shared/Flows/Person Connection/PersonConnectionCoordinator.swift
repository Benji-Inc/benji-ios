//
//  PersonConnectionCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/16/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PersonConnectionCoordinator: PresentableCoordinator<Void> {
    
    lazy var vc = PersonConnectionViewController()
    private let person: PersonType?
    private let launchActivity: LaunchActivity? 
    
    init(with person: PersonType? = nil ,
         launchActivity: LaunchActivity? = nil,
         router: Router,
         deepLink: DeepLinkable?) {
        
        self.person = person
        self.launchActivity = launchActivity
        
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.vc
    }
    
    override func start() {
        super.start()
        
        if let person = self.person {
            self.vc.configure(for: person)
        } else if let launchActivity = launchActivity {
            switch launchActivity {
            case .onboarding(_):
                break
            case .reservation(let reservationId):
                Task {
                    guard let reservation = try? await Reservation.getObject(with: reservationId).retrieveDataIfNeeded(), let owner = try? await reservation.createdBy?.retrieveDataIfNeeded() else { return }
                    
                    self.vc.configure(for: owner)
                }
            case .pass(let passId):
                Task {
                    guard let pass = try? await Pass.getObject(with: passId).retrieveDataIfNeeded(), let owner = try? await pass.owner?.retrieveDataIfNeeded() else { return }
                    
                    self.vc.configure(for: owner)
                }
            case .deepLink(_):
                self.finishFlow(with: ())
            }
        } else {
            self.finishFlow(with: ())
        }
    }
}
