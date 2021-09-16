//
//  ArchiveViewController.swift
//  ArchiveViewController
//
//  Created by Benji Dodgson on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchiveViewController: ViewController {

    // MARK: - UI

    private var collectionView = CollectionView(layout: ArchiveCollectionViewLayout())
    private lazy var dataSource = ArchiveCollectionViewDataSource(collectionView: self.collectionView)

}

extension ArchiveViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }

        //self.delegate?.homeViewControllerDidSelect(item: identifier)
    }

//    func collectionView(_ collectionView: UICollectionView,
//                        contextMenuConfigurationForItemAt indexPath: IndexPath,
//                        point: CGPoint) -> UIContextMenuConfiguration? {
//
//        return nil
////        let conversation = chatClient.channelListController(query: )
////        guard let conversation = ConversationSupplier.shared.allConversationsSorted[safe: indexPath.row],
////              let cell = collectionView.cellForItem(at: indexPath) as? ConversationCell else { return nil }
////
////        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
////            return ConversationPreviewViewController(with: conversation, size: cell.size)
////        }, actionProvider: { suggestedActions in
////            if conversation.isFromCurrentUser {
////                return self.makeCurrentUserMenu(for: conversation, at: indexPath)
////            } else {
////                return self.makeNonCurrentUserMenu(for: conversation, at: indexPath)
////            }
////        })
//    }
//
//    func makeCurrentUserMenu(for conversation: DisplayableConversation, at indexPath: IndexPath) -> UIMenu {
//        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }
//
//        let confirm = UIAction(title: "Confirm",
//                               image: UIImage(systemName: "trash"),
//                               attributes: .destructive) { action in
//
//            switch conversation.conversationType {
//            case .system(_):
//                break
//            case .conversation(let conversation):
//                Task {
//                    do {
//                        try await ChatClient.shared.deleteChannel(conversation)
//                    } catch {
//                        logDebug(error)
//                    }
//                }
//            }
//        }
//
//        let deleteMenu = UIMenu(title: "Delete",
//                                image: UIImage(systemName: "trash"),
//                                options: .destructive,
//                                children: [confirm, neverMind])
//
//        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [unowned self] _ in
//            guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }
//            self.delegate?.homeViewControllerDidSelect(item: identifier)
//        }
//
//        // Create and return a UIMenu with the share action
//        return UIMenu(title: "Options", children: [open, deleteMenu])
//    }
//
//    func makeNonCurrentUserMenu(for conversation: DisplayableConversation, at indexPath: IndexPath) -> UIMenu {
//
//        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }
//
//        let confirm = UIAction(title: "Confirm",
//                               image: UIImage(systemName: "clear"),
//                               attributes: .destructive) { action in
//
//            switch conversation.conversationType {
//            case .system(_):
//                break
//            case .conversation(let conversation):
//                Task {
//                    do {
//                        try await ChatClient.shared.deleteChannel(conversation)
//                    } catch {
//                        logDebug(error)
//                    }
//                }
//            }
//        }
//
//        let deleteMenu = UIMenu(title: "Leave",
//                                image: UIImage(systemName: "clear"),
//                                options: .destructive,
//                                children: [confirm, neverMind])
//
//        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [unowned self] _ in
//            guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return }
//            self.delegate?.homeViewControllerDidSelect(item: item)
//        }
//
//        // Create and return a UIMenu with the share action
//        return UIMenu(title: "Options", children: [open, deleteMenu])
//    }
}
