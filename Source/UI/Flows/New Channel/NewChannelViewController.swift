//
//  ChannelPurposeViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 9/8/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures
import TMROLocalization
import ReactiveSwift

protocol NewChannelViewControllerDelegate: class {
    func newChannelView(_ controller: NewChannelViewController,
                        didCreate channel: ChannelType)
}

enum NewChannelContent: Switchable {
    case purpose(PurposeViewController)
    case favorites(ConnectionsViewController)

    var viewController: UIViewController & Sizeable {
        switch self {
        case .purpose(let vc):
            return vc
        case .favorites(let vc):
            return vc
        }
    }

    var shouldShowBackButton: Bool {
        switch self {
        case .purpose(_):
            return false
        case .favorites(_):
            return true
        }
    }
}

class NewChannelViewController: SwitchableContentViewController<NewChannelContent> {

    lazy var purposeVC = PurposeViewController()
    lazy var favoritesVC = ConnectionsViewController()

    let button = NewChannelButton()

    unowned let delegate: NewChannelViewControllerDelegate

    init(delegate: NewChannelViewControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init?(withObject object: DeepLinkable) {
        fatalError("init(withObject:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.button.isEnabled = false 
        self.view.addSubview(self.button)
        self.button.didSelect = { [unowned self] in
            self.buttonTapped()
        }

        self.purposeVC.textFieldDidBegin = { [unowned self] in
            UIView.animate(withDuration: Theme.animationDuration) {
                self.titleLabel.alpha = 0.2
                self.descriptionLabel.alpha = 0.2
                self.lineView.alpha = 0.2
                self.purposeVC.contextVC.view.alpha = 0.2
            }
        }

        self.purposeVC.textFieldDidEnd = { [unowned self] in
            UIView.animate(withDuration: Theme.animationDuration) {
                self.titleLabel.alpha = 1
                self.descriptionLabel.alpha = 1
                self.lineView.alpha = 1
                self.purposeVC.contextVC.view.alpha = 1
            }
        }

        self.purposeVC.textFieldTextDidChange = { [unowned self] text in
            self.button.isEnabled = !text.isEmpty
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        self.button.bottom = self.view.height - self.view.safeAreaInsets.bottom - 10

        guard let handler = self.keyboardHandler, handler.currentKeyboardHeight > 0 else { return }

        let diff = self.view.height - handler.currentKeyboardHeight
        if diff < self.scrollView.contentSize.height {
            let offset = (self.view.height - self.scrollView.contentSize.height) * -1
            if offset > 0 {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
            }
        }
    }

    override func getInitialContent() -> NewChannelContent {
        return .purpose(self.purposeVC)
    }

    override func getTitle() -> Localized {
        switch self.currentContent.value {
        case .purpose(_):
            return "NEW CONVERSATION"
        case .favorites(_):
            return LocalizedString(id: "",
                                   arguments: [self.purposeVC.textField.text!],
                                   default: "ADD PEOPLE TO:\n@(foo)")
        }
    }

    override func getDescription() -> Localized {
        switch self.currentContent.value {
        case .purpose(_):
            return "Add a name and some context to help frame the conversation."
        case .favorites(_):
            return "Add people to the converstion."
        }
    }

    override func didSelectBackButton() {
        self.currentContent.value = .purpose(self.purposeVC)
    }

    override func willUpdateContent() {
        self.button.update(for: self.currentContent.value)
        self.view.bringSubviewToFront(self.button)
    }

    func buttonTapped() {

        switch self.currentContent.value {
        case .purpose(_):
            self.currentContent.value = .favorites(self.favoritesVC)
        case .favorites(_):
            guard let title = self.purposeVC.textField.text else { return }

            let users = self.favoritesVC.collectionViewManager.selectedItems.compactMap { (orbItem) -> User? in
                return orbItem.nonMeUser
            }

            // TODO: Add context to channel
            self.createChannel(with: users,
                               title: title,
                               description: "")
        }
    }

    private func createChannel(with users: [User],
                               title: String,
                               description: String) {

        self.button.isLoading = true

        ChannelSupplier.createChannel(channelName: title,
                                      channelDescription: description,
                                      type: .private)
            .joinIfNeeded()
            .invite(users: users)
            .ignoreUserInteractionEventsUntilDone(for: self.view)
            .observeValue(with: { (channel) in
                self.delegate.newChannelView(self, didCreate: .channel(channel))
            })
    }
}

