//
//  MessageDetailCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 2/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

enum MessageDetailResult {
    case message(Messageable)
    case reply(MessageId)
    case conversation(ConversationId)
    case none
}

class MessageDetailCoordinator: PresentableCoordinator<MessageDetailResult> {

    private lazy var messageVC = MessageDetailViewController(message: self.message)

    private let message: Messageable

    init(with message: Messageable,
         router: Router,
         deepLink: DeepLinkable?) {

        self.message = message

        super.init(router: router, deepLink: deepLink)
    }
    
    override func start() {
        super.start()
        
        self.messageVC.messageContent.delegate = self
        
        self.messageVC.$selectedItems
            .removeDuplicates()
            .mainSink { items in
            guard let first = items.first else { return }
            switch first {
            case .option(let type):
                switch type {
                case .viewThread:
                    self.finishFlow(with: .message(self.message))
                case .edit:
                    self.presentAlert(for: type)
                case .pin:
                    self.updatePin(shouldPin: true)
                case .unpin:
                    self.updatePin(shouldPin: false)
                case .quote:
                    self.presentAlert(for: type)
                case .more:
                    break
                }
            case .read(let reaction):
                guard let author = reaction.readReaction?.author else { return }
                self.presentProfile(for: author)
            case .info(_):
                break
            case .more(_):
                break
            }
        }.store(in: &self.cancellables)
        
        self.messageVC.blurView.didSelect { [unowned self] in
            self.finishFlow(with: .none)
        }
        
        self.messageVC.dataSource.didTapDelete = { [unowned self] in
            self.handleDelete()
        }
        
        self.messageVC.dataSource.didTapEdit = { [unowned self] in
            self.handleEdit()
        }
    }

    override func toPresentable() -> PresentableCoordinator<Messageable?>.DismissableVC {
        return self.messageVC
    }
    
    private func handleEdit() {
        self.presentAlert(for: .edit)
    }
    
    private func updatePin(shouldPin: Bool) {
        guard let controller = self.messageVC.messageController else { return }
        
        Task {
            if shouldPin {
                try? await controller.pinMessage()
            } else {
                try? await controller.unpinMessage()
            }
        }
    }
    
    private func handleDelete() {
        Task {
            guard let cid = self.message.streamCid else { return }
            let controller = ChatClient.shared.messageController(cid: cid, messageId: self.message.id)
            try? await controller.deleteMessage()
            
            await ToastScheduler.shared.schedule(toastType: .success(UIImage(systemName: "trash")!, "Message Deleted"))
            
            self.finishFlow(with: .none)
        }
    }
    
    private func presentAlert(for option: MessageDetailDataSource.OptionType) {
        
        let alertController = UIAlertController(title: option.title,
                                                message: "(Coming Soon)",
                                                preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Got it", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
        })

        alertController.addAction(cancelAction)
        self.messageVC.present(alertController, animated: true, completion: nil)
    }
    
    func presentProfile(for person: PersonType) {
        self.removeChild()

        let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                switch result {
                case .conversation(let cid):
                    self.finishFlow(with: .conversation(cid))
                case .openReplies(_, _):
                    break 
                }
            }
        }
        
        self.router.present(coordinator, source: self.messageVC, cancelHandler: nil)
    }
}

extension MessageDetailCoordinator: MessageContentDelegate {
    
    func messageContent(_ content: MessageContentView, didTapViewReplies messageInfo: (ConversationId, MessageId)) {
        self.finishFlow(with: .reply(messageInfo.1))
    }
    
    func messageContent(_ content: MessageContentView, didTapMessage messageInfo: (ConversationId, MessageId)) {
        self.finishFlow(with: .message(self.message))
    }
    
    func messageContent(_ content: MessageContentView, didTapEditMessage messageInfo: (ConversationId, MessageId)) {
        
    }
    
    func messageContent(_ content: MessageContentView, didTapAttachmentForMessage messageInfo: (ConversationId, MessageId)) {
        let message = Message.message(with: messageInfo.0, messageId: messageInfo.1)

        switch message.kind {
        case .photo(photo: let photo, let body):
            let text = "\(message.author.givenName): \(body)"
            self.presentMediaFlow(for: [photo], startingItem: nil, body: text)
        case .video(video: let video, body: let body):
            let text = "\(message.author.givenName): \(body)"
            self.presentMediaFlow(for: [video], startingItem: nil, body: text)
        case .media(items: let media, body: let body):
            let text = "\(message.author.givenName): \(body)"
            self.presentMediaFlow(for: media, startingItem: nil, body: text)
        case .text, .attributedText, .location, .emoji, .audio, .contact, .link:
            break
        }
    }
    
    func messageContent(_ content: MessageContentView, didTapAddExpressionForMessage messageInfo: (ConversationId, MessageId)) {
        guard let message = ChatClient.shared.messageController(cid: messageInfo.0, messageId: messageInfo.1).message else { return }
        self.presentExpressionCreation(for: message)
    }
    
    func presentMediaFlow(for mediaItems: [MediaItem], startingItem: MediaItem?, body: String) {
        self.removeChild()
        let coordinator = MediaViewerCoordinator(items: mediaItems,
                                                 startingItem: startingItem,
                                                 body: body,
                                                 router: self.router,
                                                 deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { _ in }
        self.router.present(coordinator, source: self.messageVC, cancelHandler: nil)
    }
    
    func presentExpressionCreation(for message: Messageable) {
        let coordinator = ExpressionCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { [unowned self] result in
            guard let expression = result else { return }
            
            expression.emotions.forEach { emotion in
                AnalyticsManager.shared.trackEvent(type: .emotionSelected,
                                                   properties: ["value": emotion.rawValue])
            }
            
            guard let controller = ChatClient.shared.messageController(for: message) else { return }

            Task {
                try await controller.add(expression: expression)
            }
            self.messageVC.dismiss(animated: true)
        }
        self.router.present(coordinator, source: self.messageVC, cancelHandler: nil)
    }
}
