//
//  ReactionsView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
#if IOS
import StreamChat
#endif

class ReactionsView: View {

    let label = Label(font: .small)
    let imageView = DisplayableImageView()
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.imageView)
        self.imageView.displayable = UIImage(systemName: "face.smiling")
        self.imageView.imageView.tintColor = Color.gray.color
        self.imageView.imageView.contentMode = .scaleAspectFit
        self.imageView.isVisible = false

        self.addSubview(self.label)
        self.label.isVisible = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.expandToSuperviewSize()
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }

    #if IOS
    func configure(with reactions: Set<ChatMessageReaction>) {

        let nonReadReactions = reactions.filter { reaction in
            guard let type = ReactionType(rawValue: reaction.type.rawValue) else { return false }
            return type != .read
        }

        let reaction = nonReadReactions.first { reaction in
            return reaction.author.id == User.current()!.objectId
        }

        guard let r = reaction, let type = ReactionType(rawValue: r.type.rawValue) else {
            self.imageView.isVisible = true
            return
        }
        var text = type.emoji
        if reactions.count > 1 {
            text += " +\(reactions.count - 1)"
        }
        self.label.setText(text)
        self.label.isVisible = true 
        self.imageView.isVisible = false
        self.layoutNow()
    }
    #endif
}



