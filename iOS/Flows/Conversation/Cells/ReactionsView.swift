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

    let button = Button()
    let imageView = DisplayableImageView()
    #if IOS
    var didSelectReaction: ((ReactionType) -> Void)? = nil
    #endif
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.imageView)
        self.imageView.displayable = UIImage(systemName: "face.smiling")
        self.imageView.imageView.tintColor = Color.gray.color
        self.imageView.imageView.contentMode = .scaleAspectFit

        self.addSubview(self.button)

        self.button.showsMenuAsPrimaryAction = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.button.expandToSuperviewSize()
        self.imageView.expandToSuperviewSize()
    }

#if IOS
    func configure(with reactions: Set<ChatMessageReaction>) {
        self.button.menu = self.createMenu()
    }

    private func createMenu() -> UIMenu {

        var childern: [UIMenuElement] = []

        ReactionType.allCases.forEach { type in

            let action = UIAction(title: type.rawValue,
                                  subtitle: "",
                                  image: nil,
                                  identifier: nil,
                                  discoverabilityTitle: nil,
                                  attributes: [],
                                  state: .on) { [unowned self] _ in
                self.didSelectReaction?(type)
            }

            childern.append(action)
        }

        let menu = UIMenu.init(title: "",
                               image: nil,
                               identifier: nil,
                               options: [.singleSelection],
                               children: childern)
        return menu
    }
    #endif
}



