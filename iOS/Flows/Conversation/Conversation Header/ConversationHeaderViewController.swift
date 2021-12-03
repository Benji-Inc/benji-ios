//
//  ConversationHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine
import Lottie
import UIKit

class ConversationHeaderViewController: ViewController, ActiveConversationable {


    lazy var membersVC = MembersViewController()
    let label = Label(font: .regular, textColor: .textColor)
    let button = Button()

    private var state: ConversationUIState = .read

    var didTapAddPeople: CompletionOptional = nil
    var didTapUpdateTopic: CompletionOptional = nil

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.membersVC)

        self.view.addSubview(self.label)
        self.label.textAlignment = .left
        self.label.lineBreakMode = .byTruncatingTail

        if !isRelease {
            self.view.addSubview(self.button)
        }

        let add = UIAction.init(title: "Add people",
                                image: UIImage(systemName: "person.badge.plus")) { [unowned self] _ in
            self.didTapAddPeople?()
        }

        let topic = UIAction.init(title: "Update topic",
                                 image: UIImage(systemName: "pencil")) { [unowned self] _ in
             self.didTapUpdateTopic?()
        }

        let menu = UIMenu(title: "Menu",
                          image: UIImage(systemName: "ellipsis.circle"),
                          identifier: nil,
                          options: [],
                          children: [topic, add])

        self.button.showsMenuAsPrimaryAction = true
        self.button.menu = menu

        ConversationsManager.shared.$activeConversation
            .removeDuplicates()
            .mainSink { conversation in
            guard let convo = conversation else { return }
            self.label.setText(convo.title)
            self.button.isEnabled = convo.isOwnedByMe
            self.view.layoutNow()
        }.store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.membersVC.view.height = 43
        self.membersVC.view.expandToSuperviewWidth()
        self.membersVC.view.pin(.bottom)

        let maxWidth = Theme.getPaddedWidth(with: self.view.width)
        self.label.setSize(withWidth: maxWidth)
        self.label.match(.bottom, to: .top, of: self.membersVC.view, offset: .negative(.standard))
        self.label.centerOnX()

        self.button.frame = self.label.frame
    }

    func update(for state: ConversationUIState) {
        self.state = state

        UIView.animate(withDuration: Theme.animationDurationStandard) {
            switch state {
            case .read:
                self.label.alpha = 1.0
            case .write:
                self.label.alpha = 0.0
            }

            self.view.layoutNow()
        } completion: { completed in

        }
    }
}
