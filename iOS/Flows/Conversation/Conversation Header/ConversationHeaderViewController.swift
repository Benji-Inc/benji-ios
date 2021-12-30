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
    let button = ThemeButton()
    let topicLabel = ThemeLabel(font: .small)
    let imageView = UIImageView(image: UIImage(systemName: "chevron.down"))
    
    private var state: ConversationUIState = .read
    
    var didTapAddPeople: CompletionOptional = nil
    var didTapUpdateTopic: CompletionOptional = nil
    
    override func initializeViews() {
        super.initializeViews()
        
        self.addChild(viewController: self.membersVC)
        
        if !isRelease {
            self.view.addSubview(self.button)
        }
        
        self.view.addSubview(self.topicLabel)
        self.view.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.tintColor = ThemeColor.textColor.color
        self.imageView.isVisible = false
        
        self.createMenu()
        
        ConversationsManager.shared.$activeConversation
            .removeDuplicates()
            .mainSink { conversation in
                guard let convo = conversation else {
                    self.topicLabel.isVisible = false
                    self.imageView.isVisible = false
                    return
                }
                self.button.isVisible = convo.isOwnedByMe
                self.topicLabel.setText(convo.cid.description)
                self.imageView.isVisible = true
                self.topicLabel.isVisible = true
                
                self.view.setNeedsLayout()
            }.store(in: &self.cancellables)
        
        self.membersVC.$selectedItems.mainSink { [unowned self] items in
            guard let first = items.first else { return }
            switch first {
            case .member(_):
                break
            case .add(_):
                self.didTapAddPeople?()
            }
        }.store(in: &self.cancellables)
    }
    
    private func createMenu() {
        let add = UIAction.init(title: "Add people",
                                image: UIImage(systemName: "person.badge.plus")) { [unowned self] _ in
            self.didTapAddPeople?()
        }
        
        let topic = UIAction.init(title: "Update topic",
                                  image: UIImage(systemName: "pencil")) { [unowned self] _ in
            self.didTapUpdateTopic?()
        }
        
        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in }
        
        let confirmDelete = UIAction(title: "Confirm",
                                     image: UIImage(systemName: "trash"),
                                     attributes: .destructive) { [unowned self] action in
            Task {
                let controller = ChatClient.shared.channelController(for: self.activeConversation!.cid)
                do {
                    try await controller.deleteChannel()
                } catch {
                    logError(error)
                }
            }.add(to: self.taskPool)
        }
        
        let deleteMenu = UIMenu(title: "Delete Conversation",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirmDelete, neverMind])
        
        let menu = UIMenu(title: "Menu",
                          image: UIImage(systemName: "ellipsis.circle"),
                          identifier: nil,
                          options: [],
                          children: [topic, add, deleteMenu])
        
        self.button.showsMenuAsPrimaryAction = true
        self.button.menu = menu
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.membersVC.view.height = 43
        self.membersVC.view.expandToSuperviewWidth()
        self.membersVC.view.pin(.bottom)
        
        self.imageView.squaredSize = 10

        self.topicLabel.setSize(withWidth: self.view.width)
        self.topicLabel.centerX = self.view.centerX - self.imageView.halfWidth - 1
        self.topicLabel.centerY = self.button.centerY
        
        self.imageView.match(.left, to: .right, of: self.topicLabel, offset: .custom(2))
        self.imageView.centerY = self.topicLabel.centerY
        
        self.button.frame = self.topicLabel.frame
    }
    
    func update(for state: ConversationUIState) {
        self.state = state
        
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.view.layoutNow()
        } completion: { completed in
            
        }
    }
}

