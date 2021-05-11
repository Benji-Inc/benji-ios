//
//  ArchivesCollectionViewManager+Extensions.swift
//  Ours
//
//  Created by Benji Dodgson on 5/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension ArchivesCollectionViewManager {

    func makeCurrentUsertMenu(for post: Post, at indexPath: IndexPath) -> UIMenu {

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }

        let confirm = UIAction(title: "Confirm", image: UIImage(systemName: "trash"), attributes: .destructive) { action in

            post.deleteInBackground { completed, error in
                ToastScheduler.shared.schedule(toastType: .basic(displayable: UIImage(systemName: "trash")!,
                                                                 title: "Post Deleted", description: "You have successfully deleted your post"))
                self.reloadForExistingUser()
            }
        }

        let deleteMenu = UIMenu(title: "Delete", image: UIImage(systemName: "trash"), options: .destructive, children: [confirm, neverMind])

        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { _ in
            self.select(indexPath: indexPath)
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "Options", children: [open, deleteMenu])
    }

    func makeNonCurrentUserMenu(for post: Post, at indexPath: IndexPath) -> UIMenu {

        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { _ in
            self.select(indexPath: indexPath)
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "Options", children: [open])
    }
}
