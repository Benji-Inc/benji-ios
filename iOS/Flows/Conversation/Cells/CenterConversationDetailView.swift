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

class CenterConversationDetailView: UICollectionReusableView, ConversationUIStateSettable, ElementKind {
    static var kind: String = "centerdetailview"
    
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
    
    private var conversationController: ConversationController?
    private var currentMessage: Message?
    
    var subscriptions = Set<AnyCancellable>()
    let taskPool = TaskPool()
        
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
        
        self.leftLabel.setText("No messages")
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
    
    func configure(for message: Message) {
        
        self.taskPool.cancelAndRemoveAll()
        
        Task {
            guard let cid = message.cid else { return }
            
            if self.conversationController?.cid != cid {
                self.conversationController = ChatClient.shared.channelController(for: cid)
                if self.conversationController!.messages.isEmpty {
                    try? await self.conversationController?.synchronize()
                }
                
                self.setNumberOfUnread(value: self.conversationController!.conversation.totalUnread)
                self.subscribeToUpdates()
            }
            
            guard !Task.isCancelled else { return }
            
            self.update(for: message)
        }.add(to: self.taskPool)
    }
    
    private func setNumberOfUnread(value: Int) {
        let new = Float(value)
        guard new != self.rightLabel.currentValue else { return }
        self.rightLabel.setValue(new, animated: true)
    }
 
    private func update(for message: Message) {
        self.leftLabel.setText(message.createdAt.getDaysAgoString())
        self.setNeedsLayout()
    }
    
    private func subscribeToUpdates() {
        
        self.subscriptions.forEach { cancellable in
            cancellable.cancel()
        }
        self.conversationController?
            .messagesChangesPublisher
            .mainSink { [unowned self] changes in
                guard let conversationController = self.conversationController else { return }
                self.setNumberOfUnread(value: conversationController.conversation.totalUnread)
            }.store(in: &self.subscriptions)
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
    
    override func prepareForReuse() {
        super.prepareForReuse() 
        
        self.subscriptions.forEach { cancellable in
            cancellable.cancel()
        }
        
        self.taskPool.cancelAndRemoveAll()
    }
}
