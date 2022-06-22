//
//  WaitlistCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator

class WaitlistCoordinator: PresentableCoordinator<Void> {
    
    lazy var waitlistVC = WaitlistViewController()
    
    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.waitlistVC
    }
    
    override func start() {
        super.start()
        
        self.waitlistVC.button.didSelect { [unowned self] in
            self.finishFlow(with: () )
        }
        
        guard let deepLink = self.deepLink else { return }
        
        Task {
            if let reservationId = deepLink.reservationId,
                let reservation = try? await Reservation.getObject(with: reservationId),
               let createById = reservation.createdBy?.objectId,
               let person = await PeopleStore.shared.getPerson(withPersonId: createById) {
                
                self.waitlistVC.personView.set(person: person)
                self.waitlistVC.personView.isVisible = true
                self.waitlistVC.descriptionLabel.setText("You now have access to join \(person.givenName) on Jibber!")
                self.waitlistVC.view.setNeedsLayout()
                
            } else if let passId = deepLink.passId,
                        let pass = try? await Pass.getObject(with: passId),
                      let ownerId = pass.owner?.objectId,
                      let person = await PeopleStore.shared.getPerson(withPersonId: ownerId) {
                
                self.waitlistVC.personView.set(person: person)
                self.waitlistVC.personView.isVisible = true
                self.waitlistVC.descriptionLabel.setText("\(person.givenName) has granted you access to Jibber! Join below.")
                self.waitlistVC.descriptionLabel.setText("")
                self.waitlistVC.view.setNeedsLayout()
            }
        }
    }
}
