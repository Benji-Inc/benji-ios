//
//  WaitlistCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator
import UIKit

class WaitlistCoordinator: PresentableCoordinator<Void> {
    
    lazy var waitlistVC = WaitlistViewController()
    
    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.waitlistVC
    }
    
    override func start() {
        super.start()
        
        self.waitlistVC.button.didSelect { [unowned self] in
            guard let user = User.current() else { return }
            switch user.status {
            case .active:
                self.finishFlow(with: ())
            case .waitlist:
                self.presentShareSheet()
            default:
                break
            }
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
    
    private func presentShareSheet() {
        Task {
            await self.waitlistVC.button.handleEvent(status: .loading)
            guard let pass = try? await Pass.fetchPass() else { return }
            await pass.prepareMetadata()

            let ac = ActivityViewController(with: self, activityItems: [pass])
            
            Task.onMainActor {
                self.router.topmostViewController.present(ac, animated: true) {
                    Task {
                        await self.waitlistVC.button.handleEvent(status: .complete)
                    }
                }
            }
        }
    }
}

extension WaitlistCoordinator: ActivityViewControllerDelegate {
    
    func activityView(_ controller: ActivityViewController, didCompleteWith result: ActivityViewController.Result) {
        if result.didShare {
            Task {
                await upgradeUser()
            }
        }
    }
    
    private func upgradeUser() async {
        Task {
            await self.waitlistVC.button.handleEvent(status: .loading)

            do {
                try await FinalizeOnboarding(reservationId: "",
                                             passId: "",
                                             forceUpgrade: true)
                .makeRequest(andUpdate: [], viewsToIgnore: [self.waitlistVC.view])
            } catch {
                await ToastScheduler.shared.schedule(toastType: .error(error))
            }
            
            await self.waitlistVC.button.handleEvent(status: .loading)
            
            self.finishFlow(with: ())
        }
    }
}
