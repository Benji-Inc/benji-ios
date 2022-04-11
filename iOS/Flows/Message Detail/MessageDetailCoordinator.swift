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
                case .viewReplies:
                    self.finishFlow(with: .message(self.message))
                case .edit:
                    self.presentAlert(for: type)
                case .pin:
                    self.presentAlert(for: type)
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
            case .reply(let model):
                guard let reply = model.reply else { return }
                self.finishFlow(with: .reply(reply.id))
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
    
    private func handleDelete() {
        Task {
            let controller = ChatClient.shared.messageController(cid: self.message.streamCid, messageId: self.message.id)
            try? await controller.deleteMessage()
            
            await ToastScheduler.shared.schedule(toastType: .basic(identifier: UUID().uuidString,
                                                             displayable: User.current()!,
                                                             title: "Message Deleted",
                                                             description: "Your message has successfully been deleted",
                                                             deepLink: nil))
            
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
            guard let url = photo.url else { return }
            let text = "\(message.author.givenName): \(body)"
            self.presentImageFlow(for: [url], startingURL: url, body: text)
        case .text, .attributedText, .location, .emoji, .audio, .contact, .link, .video:
            break
        }
    }
    
    func messageContent(_ content: MessageContentView, didTapAddEmotionsForMessage messageInfo: (ConversationId, MessageId)) {
        guard let message = ChatClient.shared.messageController(cid: messageInfo.0, messageId: messageInfo.1).message else { return }
        self.presentEmotions(for: message)
    }
    
    func presentImageFlow(for imageURLs: [URL], startingURL: URL?, body: String) {
        self.removeChild()
        
        let coordinator = ImageViewCoordinator(imageURLs: imageURLs,
                                               startURL: startingURL,
                                               body: body,
                                               router: self.router,
                                               deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { _ in }
        self.router.present(coordinator, source: self.messageVC, cancelHandler: nil)
    }
    
    func presentEmotions(for message: Messageable) {
        let coordinator = EmotionsCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { [unowned self] emotions in
            emotions.forEach { emotion in
                logDebug(emotion.rawValue)
                AnalyticsManager.shared.trackEvent(type: .emotionSelected, properties: ["value": emotion.rawValue])
            }
            
            guard !emotions.isEmpty else { return }
            
            guard let controller = ChatClient.shared.messageController(for: message) else { return }
            
            Task {
                await emotions.asyncForEach { emotion in
                    await controller.addReaction(with: .emotion(emotion))
                }
            }
            
            self.messageVC.dismiss(animated: true)
        }
        self.router.present(coordinator, source: self.messageVC, cancelHandler: nil)
    }
}
