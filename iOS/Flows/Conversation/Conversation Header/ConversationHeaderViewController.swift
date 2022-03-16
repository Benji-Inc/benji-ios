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

    let menuImageView = UIImageView()
    let button = ThemeButton()
    let topicLabel = ThemeLabel(font: .regular)
    let jibImageView = UIImageView(image: UIImage(named: "jiblogo"))
    
    private var state: ConversationUIState = .read
    
    var didTapAddPeople: CompletionOptional = nil
    var didTapUpdateTopic: CompletionOptional = nil
        
    override func initializeViews() {
        super.initializeViews()

        self.view.clipsToBounds = false
        
        self.view.addSubview(self.menuImageView)
        self.menuImageView.image = UIImage(systemName: "ellipsis")
        self.menuImageView.contentMode = .scaleAspectFit
        self.menuImageView.tintColor = ThemeColor.B2.color
        self.view.addSubview(self.button)
        
        self.view.addSubview(self.jibImageView)
        self.jibImageView.contentMode = .scaleAspectFit
        self.jibImageView.isUserInteractionEnabled = true 
        
        self.view.addSubview(self.topicLabel)
        
        self.button.showsMenuAsPrimaryAction = true
                
        ConversationsManager.shared.$activeConversation
            .removeDuplicates()
            .mainSink { conversation in
                guard let convo = conversation else {
                    self.topicLabel.isVisible = false
                    self.menuImageView.isVisible = false
                    return
                }
                
                self.setTopic(for: convo)
                self.menuImageView.isVisible = true
                self.topicLabel.isVisible = true
                self.updateMenu(with: convo)
                self.view.setNeedsLayout()
            }.store(in: &self.cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.menuImageView.height = 16
        self.menuImageView.width = 20
        self.menuImageView.pinToSafeAreaRight()
        self.menuImageView.pin(.top, offset: .custom(16))
        
        self.topicLabel.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.topicLabel.centerOnX()
        self.topicLabel.centerY = self.menuImageView.centerY
        
        self.button.size = CGSize(width: 44, height: 44)
        self.button.center = self.menuImageView.center
        
        self.jibImageView.squaredSize = 44
        self.jibImageView.pin(.left, offset: .custom(6))
        self.jibImageView.centerY = self.menuImageView.centerY
    }
    
    private func setTopic(for conversation: Conversation) {
        if let title = conversation.title {
            self.topicLabel.setText(title)
        } else {
            // If there is no title, then list the members of the conversation.
            let members = conversation.lastActiveMembers.filter { member in
                return !member.isCurrentUser
            }

            var membersString = ""
            members.forEach { member in
                if membersString.isEmpty {
                    membersString = member.givenName
                } else {
                    membersString.append(", \(member.givenName)")
                }
            }
            self.topicLabel.setText(membersString)
        }
    }
    
    func update(for state: ConversationUIState) {
        self.state = state
        
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.view.layoutNow()
        } completion: { completed in
            
        }
    }
}
