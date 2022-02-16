//
//  CenterDectorationView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import StreamChat
import ScrollCounter

class CenterDectorationView: UICollectionReusableView, ConversationUIStateSettable {
    static let kind = "decoration"
    let imageView = UIImageView()
    
    let leftLabel = ThemeLabel(font: .small, textColor: .D1)
    let rightLabel = NumberScrollCounter(value: 0,
                                         scrollDuration: Theme.animationDurationSlow,
                                         decimalPlaces: 0,
                                         prefix: "Unread: ",
                                         suffix: nil,
                                         seperator: "",
                                         seperatorSpacing: 0,
                                         font: FontType.small.font,
                                         textColor: ThemeColor.D1.color,
                                         animateInitialValue: true,
                                         gradientColor: nil,
                                         gradientStop: nil)
    
    private(set) var conversationController: ConversationController?
    var cancellables = Set<AnyCancellable>()
    var subscriptions = Set<AnyCancellable>()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initializeSubviews() {
        self.addSubview(self.leftLabel)
        self.leftLabel.textAlignment = .left
        self.addSubview(self.rightLabel)
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        
        ConversationsManager.shared.$activeConversation.mainSink { [unowned self] conversation in
            self.configure(for: conversation)
        }.store(in: &self.cancellables)
        
        ConversationsManager.shared.$topMostMessage
            .removeDuplicates()
            .mainSink { [unowned self] message in
            if let message = message, message.cid == self.conversationController?.cid {
                self.leftLabel.setText(message.createdAt.getDaysAgoString())
                self.leftLabel.setText(message.text)
                self.layoutNow()
            } else {
                self.leftLabel.text = nil
            }
        }.store(in: &self.cancellables)
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = 14
        self.imageView.centerOnXAndY()
        
        self.leftLabel.setSize(withWidth: 120)
        self.leftLabel.match(.right, to: .left, of: self.imageView, offset: .negative(.screenPadding))
        self.leftLabel.centerOnY()
        
        self.rightLabel.sizeToFit()
        self.rightLabel.match(.left, to: .right, of: self.imageView, offset: .screenPadding)
        self.rightLabel.centerOnY()
    }
    
    func configure(for conversation: Conversation?) {
        if let conversation = conversation {
            self.conversationController = ChatClient.shared.channelController(for: conversation.cid)
            if self.conversationController!.messages.isEmpty {
                self.conversationController!.synchronize()
            }
            
            // get the top most message?
            //self.leftLabel.text = nil
            self.rightLabel.setValue(Float(self.conversationController!.conversation.totalUnread), animated: true)
            self.subscribeToUpdates()
        } else {
            self.rightLabel.setValue(0, animated: true)
        }
    }
    
    private func subscribeToUpdates() {
        self.conversationController?
            .messagesChangesPublisher
            .mainSink { [unowned self] changes in
                guard let conversationController = self.conversationController else { return }
                self.configure(for: conversationController.conversation)
            }.store(in: &self.cancellables)
    }
    
    func set(state: ConversationUIState) {
        switch state {
        case .read:
            self.imageView.image = UIImage(named: "Collapse")
        case .write:
            self.imageView.image = UIImage(named: "Expand")
        }
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        if let attributes = layoutAttributes as? DecorationViewLayoutAttributes {
            self.set(state: attributes.state)
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
}
