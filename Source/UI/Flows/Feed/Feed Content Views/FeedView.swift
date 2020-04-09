//
//  FeedCell.swift
//  Benji
//
//  Created by Benji Dodgson on 7/28/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Koloda

class FeedView: View {

    private let container = View()

    lazy var introView = FeedIntroView()
    lazy var routineView = FeedRoutineView()
    lazy var inviteView = FeedChannelInviteView()
    lazy var unreadView = FeedUnreadView()
    lazy var needInvitesView = FeedInviteView()
    lazy var notificationsView = FeedNotificationPermissionsView()
    lazy var connectionView = FeedConnectionView()

    var didComplete: CompletionOptional = nil

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.container)
        self.set(backgroundColor: .background2)
        self.roundCorners()
        self.addShadow(withOffset: 20)
    }

    func configure(with item: FeedType?) {
        guard let feedItem = item else { return }

        switch feedItem {
        case .timeSaved(let count):
            self.container.addSubview(self.introView)
            self.introView.set(count: 10)
        case .system(_):
            break
        case .unreadMessages(let channel, let count):
            self.container.addSubview(self.unreadView)
            self.unreadView.configure(with: channel, count: count)
            self.unreadView.didSelect = { [unowned self] in
                self.didComplete?()
            }
        case .channelInvite(let channel):
            self.container.addSubview(self.inviteView)
            self.inviteView.configure(with: channel)
            self.inviteView.didComplete = { [unowned self] in
                self.didComplete?()
            }
        case .inviteAsk:
            self.container.addSubview(self.needInvitesView)
            self.needInvitesView.button.didSelect = { [unowned self] in
                self.didComplete?()
            }
        case .rountine:
            self.container.addSubview(self.routineView)
            self.routineView.button.didSelect = { [unowned self] in
                self.didComplete?()
            }
        case .notificationPermissions:
            self.container.addSubview(self.notificationsView)
            self.notificationsView.didGivePermission = { [unowned self] in
                self.didComplete?()
            }
        case .connectionRequest(let connection):
            self.container.addSubview(self.connectionView)
            self.connectionView.configure(connection: connection)
            self.connectionView.didComplete = { [unowned self] in
                self.didComplete?()
            }
        }

        self.container.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let margin = Theme.contentOffset * 2
        self.container.size = CGSize(width: self.width - margin, height: self.height - margin)
        self.container.centerOnXAndY()

        if let first = self.container.subviews.first {
            first.frame = self.container.bounds
        }
    }
}
