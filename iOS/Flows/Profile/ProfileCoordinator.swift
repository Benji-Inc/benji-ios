//
//  UserProfileCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import StreamChat
import Coordinator

enum ProfileResult {
    case conversation(String)
    case openReplies(Messageable)
}

class ProfileCoordinator: PresentableCoordinator<ProfileResult> {
    
    lazy var profileVC = ProfileViewController(with: self.person)
    private let person: PersonType
    
    init(with person: PersonType,
         router: CoordinatorRouter,
         deepLink: DeepLinkable?) {
        
        self.person = person
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.profileVC
    }
    
    override func start() {
        super.start()
        
        self.profileVC.dataSource.messageContentDelegate = self 
                
        if let user = self.person as? User, user.isCurrentUser {
            
            self.profileVC.header.didSelectUpdateProfilePicture = { [unowned self] in
                self.presentProfilePicture()
            }
        
            self.profileVC.contextCuesVC.addButton.didSelect { [unowned self] in
                self.presentContextCueCreator()
            }
        }
        
        self.profileVC.$selectedItems.mainSink { [unowned self] items in
            guard let first = items.first else { return }
            switch first {
            case .conversation(let cid):
                self.finishFlow(with: .conversation(cid.description))
            case .unreadMessages(let model):
                self.finishFlow(with: .conversation(model.conversationId))
            default:
                break 
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

extension ProfileCoordinator: MessageContentDelegate {
    
    func messageContent(_ content: MessageContentView, didTapViewReplies message: Messageable) {
        self.finishFlow(with: .openReplies(message))
    }
    
    func messageContent(_ content: MessageContentView, didTapAttachmentForMessage message: Messageable) {

        switch message.kind {
        case .photo(photo: let photo, _):
            self.presentMediaFlow(for: [photo], startingItem: nil, message: message)
        case .video(video: let video, _):
            self.presentMediaFlow(for: [video], startingItem: nil, message: message)
        case .media(items: let media, _):
            self.presentMediaFlow(for: media, startingItem: nil, message: message)
        case .text, .attributedText, .location, .emoji, .audio, .contact, .link:
            break
        }
    }
    
    func presentMediaFlow(for mediaItems: [MediaItem],
                          startingItem: MediaItem?, 
                          message: Messageable) {
        self.removeChild()
        let coordinator = MediaCoordinator(items: mediaItems,
                                           startingItem: startingItem,
                                           message: message,
                                           router: self.router,
                                           deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { _ in }
        self.router.present(coordinator, source: self.profileVC, cancelHandler: nil)
    }
}
