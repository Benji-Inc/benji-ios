//
//  MediaMoreButton.swift
//  Ours
//
//  Created by Benji Dodgson on 4/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MediaMoreButton: Button {

    var didConfirmDeletion: CompletionOptional = nil

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(style: .icon(image: UIImage(systemName: "ellipsis")!, color: .white))

        let cancel = UIAction(title: "Cancel", image: UIImage(systemName: "nosign")) { action in}

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in}

        let confirm = UIAction(title: "Confirm", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
            self.didConfirmDeletion?()
        }

        let deleteMenu = UIMenu(title: "Delete", image: UIImage(systemName: "trash"), options: .destructive, children: [neverMind, confirm])

        self.showsMenuAsPrimaryAction = true
        self.menu = UIMenu(title: "Options", children: [cancel, deleteMenu])
    }
}
