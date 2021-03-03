//
//  ProfileViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 7/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TwilioChatClient
import TMROLocalization

protocol ProfileViewControllerDelegate: AnyObject {
    func profileView(_ controller: ProfileViewController, didSelect item: ProfileItem, for user: User)
}

class ProfileViewController: ViewController, TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .fade
    }

    var transitionColor: Color {
        return .background1
    }

    private let user: User
    weak var delegate: ProfileViewControllerDelegate?

    private let scrollView = UIScrollView()
    private(set) var avatarView = AvatarView()
    private let nameView = ProfileDetailView()
    private let handleView = ProfileDetailView()
    private let localTimeView = ProfileDetailView()
    private let ritualView = ProfileDetailView()
    let versionLabel = Label(frame: .zero, font: .small, textColor: .background2)

    init(with user: User) {
        self.user = user
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.scrollView)

        self.view.addSubview(self.avatarView)
        self.avatarView.set(avatar: self.user)
        self.avatarView.didSelect { [unowned self] in
            self.delegate?.profileView(self, didSelect: .picture, for: self.user)
        }

        self.view.addSubview(self.nameView)
        self.view.addSubview(self.handleView)
        self.view.addSubview(self.localTimeView)
        self.view.addSubview(self.ritualView)
        self.ritualView.button.isVisible = true 
        self.ritualView.button.didSelect { [unowned self] in
            self.delegate?.profileView(self, didSelect: .ritual, for: self.user)
        }

        self.user.subscribe()
            .mainSink(receiveValue: { event in
                switch event {
                case .entered(let u), .left(let u), .created(let u), .updated(let u), .deleted(let u):
                    self.avatarView.set(avatar: u)
                    self.updateItems(with: u)
                }
            }).store(in: &self.cancellables)

        let version = Config.shared.environment.displayName.capitalized + " " + Config.shared.appVersion
        self.versionLabel.setText(version)
        self.view.addSubview(versionLabel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateItems(with: self.user)
    }

    func updateItems(with user: User) {
        self.nameView.configure(with: .name, for: user)
        self.handleView.configure(with: .handle, for: user)
        self.localTimeView.configure(with: .localTime, for: user)
        self.ritualView.configure(with: .ritual, for: user)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.scrollView.expandToSuperviewSize()

        self.avatarView.setSize(for: self.view.width * 0.4)
        self.avatarView.pin(.top, padding: 20)
        self.avatarView.pin(.left, padding: Theme.contentOffset)

        let itemSize = CGSize(width: self.view.width - (Theme.contentOffset * 2), height: 60)

        self.nameView.size = itemSize
        self.nameView.match(.top, to: .bottom, of: self.avatarView, offset: Theme.contentOffset)
        self.nameView.pin(.left, padding: Theme.contentOffset)

        self.handleView.size = itemSize
        self.handleView.match(.top, to: .bottom, of: self.nameView, offset: Theme.contentOffset)
        self.handleView.pin(.left, padding: Theme.contentOffset)

        self.localTimeView.size = itemSize
        self.localTimeView.match(.top, to: .bottom, of: self.handleView, offset: Theme.contentOffset)
        self.localTimeView.pin(.left, padding: Theme.contentOffset)

        self.ritualView.size = itemSize
        self.ritualView.match(.top, to: .bottom, of: self.localTimeView, offset: Theme.contentOffset)
        self.ritualView.pin(.left, padding: Theme.contentOffset)

        self.versionLabel.setSize(withWidth: self.view.width)
        self.versionLabel.pin(.left, padding: Theme.contentOffset)
        self.versionLabel.pinToSafeArea(.bottom, padding: 0)

        self.scrollView.contentSize = CGSize(width: self.view.width, height: self.ritualView.bottom)
    }
}
