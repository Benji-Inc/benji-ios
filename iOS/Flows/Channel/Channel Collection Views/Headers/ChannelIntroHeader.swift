//
//  MessageIntroCell.swift
//  Benji
//
//  Created by Benji Dodgson on 5/25/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import TMROLocalization
import Combine

class ChannelIntroHeader: UICollectionReusableView {

    let avatarView = AvatarView()
    let textView = TextView()
    let label = Label(font: .displayUnderlined, textColor: .background4)

    private(set) var channel: DisplayableChannel?
    private var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.addSubview(self.avatarView)
        self.addSubview(self.label)
        self.addSubview(self.textView)
        self.textView.isScrollEnabled = false 
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let maxWidth = self.width - (Theme.contentOffset * 2)
        self.textView.setSize(withWidth: maxWidth)
        self.textView.left = Theme.contentOffset
        self.textView.pin(.bottom, padding: Theme.contentOffset * 2)

        self.label.setSize(withWidth: maxWidth)
        self.label.match(.left, to: .left, of: self.textView)
        self.label.match(.bottom, to: .top, of: self.textView, offset: (Theme.contentOffset * 2) * -1)

        self.avatarView.setSize(for: maxWidth * 0.4)
        self.avatarView.match(.left, to: .left, of: self.textView)
        self.avatarView.match(.bottom, to: .top, of: self.label, offset: -4)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.textView.text = nil
    }

    func configure(with channel: DisplayableChannel) {
        self.channel = channel

        if case .channel(let tchChannel) = channel.channelType {
            tchChannel.getNonMeMembers()
                .mainSink(receiveResult: { (members, error) in
                    if let first = members?.first, let date = tchChannel.dateCreatedAsDate {
                        self.avatarView.set(avatar: first)
                        self.label.setText(first.givenName)
                        let message = self.getMessage(name: first.givenName, date: date)
                        let attributed = AttributedString(message,
                                                          fontType: .small,
                                                          color: .background4)
                        self.textView.set(attributed: attributed, linkColor: .purple)
                    }

                    self.layoutNow()
                }).store(in: &self.cancellables)
        }
    }

    private func getMessage(name: String, date: Date) -> LocalizedString {
        return LocalizedString(id: "", arguments: [name, Date.monthDayYear.string(from: date)], default: "This is the very beginning of your direct message history with [@(name)](userid). You created this conversation on @(date)")
    }
}
