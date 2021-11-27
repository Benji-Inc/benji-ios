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

    let imageView = DisplayableImageView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.imageView)
        self.imageView.displayable = UIImage(systemName: "face.smiling")
        self.imageView.imageView.tintColor = Color.gray.color
        self.imageView.imageView.contentMode = .scaleAspectFit
    }

#if IOS
    func configure(with reactions: Set<ChatMessageReaction>) {

    }
#endif

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.expandToSuperviewSize()
    }
}
