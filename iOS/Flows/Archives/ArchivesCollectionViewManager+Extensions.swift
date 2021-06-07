//
//  ArchivesCollectionViewManager+Extensions.swift
//  Ours
//
//  Created by Benji Dodgson on 5/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseLiveQuery

extension ArchivesCollectionViewManager {

    func makeCurrentUsertMenu(for post: Post, at indexPath: IndexPath) -> UIMenu {

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }

        let confirm = UIAction(title: "Confirm", image: UIImage(systemName: "trash"), attributes: .destructive) { action in

            post.deleteInBackground()
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

    func subscribeToUpdates(for user: User) {
        if let query = self.liveQuery {
            Client.shared.unsubscribe(query)
        }

        guard let query = Post.query() else { return }
        self.liveQuery = query

        query.whereKey("author", equalTo: user)
        let subscription = Client.shared.subscribe(query)

        subscription.handleEvent { query, event in
            runMain {
                switch event {
                case .entered(_):
                    break 
                case .left(_):
                    print("LEFT")
                case .created(_):
                    self.loadPosts(for: user)
                case .updated(let object):
                    guard let post = object as? Post, post.type == .media else { return }
                    // Add back in once Comments are isolated.
                
//                    ToastScheduler.shared.schedule(toastType: .basic(identifier: post.objectId!,
//                                                    displayable: post.file!,
//                                                                     title: "Post Updated",
//                                                                     description: "Post was successfully updated.",
//                                                                     deepLink: nil))

                case .deleted(let object):
                    guard let post = object as? Post, post.type == .media else { return }
                    ToastScheduler.shared.schedule(toastType: .basic(identifier: post.objectId!,
                                                    displayable: UIImage(systemName: "trash")!,
                                                                     title: "Post Deleted",
                                                                     description: "Post was successfully deleted from your archive.",
                                                                     deepLink: nil))

                    self.reloadForExistingUser()
                }
            }
        }
    }
}
