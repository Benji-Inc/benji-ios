//
//  ConversationHeaderViewController+Menu.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/11/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ConversationHeaderViewController {
    
    func updateMenu(with conversation: Conversation) {
        
        var children: [UIMenuElement] = []
        
        let updateProfile = UIAction.init(title: "Update profile picture",
                                image: UIImage(systemName: "person.crop.square")) { [unowned self] _ in
            self.didTapUpdateProfilePicture?()
        }
        
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
        
        let confirmHide = UIAction(title: "Hide Conversation",
                                     image: UIImage(systemName: "eye.slash"),
                                     attributes: .destructive) { [unowned self] action in
            Task {
                let controller = ChatClient.shared.channelController(for: self.activeConversation!.cid)
                do {
                    try await controller.hideChannel(clearHistory: true)
                } catch {
                    logError(error)
                }
            }.add(to: self.taskPool)
        }
        
        let hideMenu = UIMenu(title: "Hide Conversation",
                                image: UIImage(systemName: "eye.slash"),
                                options: .destructive,
                                children: [confirmHide, neverMind])

        if conversation.isOwnedByMe {
            if User.isOnWaitlist {
                children = [topic, add, updateProfile]
            } else {
                children = [topic, add, updateProfile, deleteMenu, hideMenu]
            }
        } else {
            children = [updateProfile, hideMenu]
        }
        
        self.button.menu = UIMenu(title: "Menu",
                                  options: [],
                                  children: children)
        self.button.showsMenuAsPrimaryAction = true 
    }
}
