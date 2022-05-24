//
//  NoticeCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class NoticeCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = SystemNotice
    
    var currentItem: SystemNotice?
    
    lazy var connectionConfirmedConentView = ConnectionConfirmedContentView()
    lazy var connectionRequestContentView = ConnectionRequestContentView()
    lazy var invitePromptContentView = InvitePromptContentView()
    lazy var introContentView = JibberIntroContentView()
    lazy var tipContentView = TipContentView()
    lazy var urgentMessageContentView = UrgentMessageContentView() 
    
    var didSelectPrimaryOption: CompletionOptional = nil
    var didSelectSecondaryOption: CompletionOptional = nil

    func configure(with item: SystemNotice) {
        Task {
            await self.handle(notice: item)
        }
    }
    
    @MainActor
    private func handle(notice: SystemNotice) async {
        self.contentView.removeAllSubviews()
        
        let content: NoticeContentView
        
        switch notice.type {
        case .timeSensitiveMessage:
            content = self.urgentMessageContentView
        case .connectionRequest:
            content = self.connectionRequestContentView
        case .connectionConfirmed:
            content = self.connectionConfirmedConentView
        case .tip:
            content = self.tipContentView
        case .invitePrompt:
            content = self.invitePromptContentView
        case .jibberIntro:
            content = self.invitePromptContentView
        case .system, .unreadMessages:
            content = NoticeContentView()
        }
        
        await content.configure(for: notice)
        self.contentView.addSubview(content)
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let first = self.contentView.subviews.first(where: { view in
            return view is NoticeContentView
        }) {
            first.expandToSuperviewSize()
        }
    }
}
