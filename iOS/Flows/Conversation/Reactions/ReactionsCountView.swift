//
//  ReactionsCountView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ReactionsCountView: UICollectionReusableView {

    let label = Label(font: .small)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeSubviews() {
        self.addSubview(self.label)
    }

    func configure(with reactions: Set<ChatMessageReaction>) {

        let nonReadReactions = reactions.filter { reaction in
            guard let type = ReactionType(rawValue: reaction.type.rawValue) else { return false }
            return type != .read
        }

        let reaction = nonReadReactions.first { reaction in
            return reaction.author.id == User.current()!.objectId
        }

        guard let r = reaction, let type = ReactionType(rawValue: r.type.rawValue) else {
            return
        }
        
        var text = type.emoji
        if reactions.count > 1 {
            text += " +\(reactions.count - 1)"
        }
        self.label.setText(text)
        self.label.isVisible = true
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }
}
