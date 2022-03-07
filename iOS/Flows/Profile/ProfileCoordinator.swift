//
//  UserProfileCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class ProfileCoordinator: PresentableCoordinator<ConversationId> {
    
    lazy var profileVC = ProfileViewController(with: self.person)
    private let person: PersonType
    
    init(with person: PersonType,
         router: Router,
         deepLink: DeepLinkable?) {
        
        self.person = person
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.profileVC
    }
    
    override func start() {
        super.start()
                
        if let user = self.person as? User, user.isCurrentUser {
            self.profileVC.header.personView.didSelect { [unowned self] in
                self.presentProfilePicture()
            }
            
            self.profileVC.contextCuesVC.$selectedItems.mainSink { items in
                guard let first = items.first else { return }
                
                switch first {
                case .add(_):
                    self.presentContextCueCreator()
                case .contextCue(_):
                    break
                }
            }.store(in: &self.cancellables)
        }
        
        self.profileVC.$selectedItems.mainSink { [unowned self] items in
            guard let first = items.first else { return }
            switch first {
            case .conversation(let cid):
                self.finishFlow(with: cid)
            }
            
        }.store(in: &self.cancellables)
    }
    
    func presentProfilePicture() {
        let vc = ModalPhotoViewController()

        vc.onDidComplete = { [unowned vc = vc] _ in
            vc.dismiss(animated: true, completion: nil)
        }

        self.router.present(vc, source: self.profileVC)
    }
    
    func presentContextCueCreator() {
        self.removeChild()
        
        if let pop = self.profileVC.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.selectedDetentIdentifier = .large
            sheet.animateChanges { [unowned self] in
                self.profileVC.view.layoutNow()
            }
        }
        

        let coordinator = ContextCueCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { _ in
            coordinator.toPresentable().dismiss(animated: true, completion: nil)
        }

        self.router.present(coordinator, source: self.profileVC)
    }
}
