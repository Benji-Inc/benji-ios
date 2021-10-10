//
//  ConversationCollectionViewManager.swift
//  Benji
//
//  Created by Benji Dodgson on 11/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class ConversationCollectionViewManager: NSObject, UITextViewDelegate, ConversationDataSource,
                                         UICollectionViewDelegate, UICollectionViewDataSource,
                                         UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {

    var sections: [ConversationSectionable] = [] {
        didSet {
            self.updateLayoutDataSource()
        }
    }

    var collectionView: ConversationThreadCollectionView
    var didSelectURL: ((URL) -> Void)?
    var didTapShare: ((Messageable) -> Void)?
    var didTapResend: ((Messageable) -> Void)?
    var didTapEdit: ((Messageable, IndexPath) -> Void)?
    var willDisplayCell: ((Messageable, IndexPath) -> Void)?
    var cancellables = Set<AnyCancellable>()

    init(with collectionView: ConversationThreadCollectionView) {
        self.collectionView = collectionView
        super.init()
        self.updateLayoutDataSource()
    }

    private func updateLayoutDataSource() {
        self.collectionView.prefetchDataSource = self
        self.collectionView.conversationLayout.dataSource = self
    }

    // MARK: DATA SOURCE

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.numberOfSections()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.numberOfItems(inSection: section)
    }

    // MARK: PREFETCH

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        print("PRE-FETCH: \(indexPaths)")
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {

    }

    // MARK: DELEGATE

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let conversationCollectionView = collectionView as? ConversationThreadCollectionView else { fatalError() }

        guard let message = self.item(at: indexPath) else { return UICollectionViewCell() }

        let cell: BaseMessageCell
        switch message.kind {
        case .text(_):
            cell = conversationCollectionView.dequeueReusableCell(old_MessageCell.self, for: indexPath)
            if let msgCell = cell as? old_MessageCell {
                msgCell.textView.delegate = self
                let interaction = UIContextMenuInteraction(delegate: self)
                msgCell.bubbleView.addInteraction(interaction)
            }
        case .attributedText(_):
            cell = conversationCollectionView.dequeueReusableCell(AttributedMessageCell.self, for: indexPath)
        case .photo(_, _):
            fatalError()
//            cell = conversationCollectionView.dequeueReusableCell(PhotoMessageCell.self, for: indexPath)
//            if let photoCell = cell as? PhotoMessageCell {
//                photoCell.textView.delegate = self
//                let interaction = UIContextMenuInteraction(delegate: self)
//                photoCell.imageView.addInteraction(interaction)
//            }
        case .video(_, _):
            cell = conversationCollectionView.dequeueReusableCell(VideoMessageCell.self, for: indexPath)
        case .location(_):
            cell = conversationCollectionView.dequeueReusableCell(LocationMessageCell.self, for: indexPath)
        case .emoji(_):
            cell = conversationCollectionView.dequeueReusableCell(EmojiMessageCell.self, for: indexPath)
        case .audio(_):
            cell = conversationCollectionView.dequeueReusableCell(AudioMessageCell.self, for: indexPath)
        case .contact(_):
            cell = conversationCollectionView.dequeueReusableCell(ContactMessageCell.self, for: indexPath)
        case .link(_):
            cell = conversationCollectionView.dequeueReusableCell(LinkCell.self, for: indexPath)
            if let msgCell = cell as? LinkCell {
                let interaction = UIContextMenuInteraction(delegate: self)
                msgCell.imageView.addInteraction(interaction)
            }
        }

        cell.configure(with: message)
        cell.didTapMessage = { [weak self] in
            guard let `self` = self else { return }
            Task {
                do {
                    try await self.updateConsumers(for: message)
                } catch {
                    logDebug(error)
                }
            }
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        
        if let message = self.item(at: indexPath){
            self.willDisplayCell?(message, indexPath)
        }
    }

    // MARK: FLOW LAYOUT

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let conversationLayout = collectionViewLayout as? ConversationThreadCollectionViewFlowLayout else { return .zero }

        /// May not have a message because of the typing indicator
        let message = self.item(at: indexPath)
        return conversationLayout.sizeForItem(at: indexPath, with: message)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {

        guard let conversationLayout = collectionViewLayout as? ConversationThreadCollectionViewFlowLayout else {
            return .zero
        }

        return conversationLayout.sizeForHeader(at: section, with: collectionView)
    }

    // MARK: TEXT VIEW DELEGATE

    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        return true
    }

    func didSelectLoadMore(for messageIndex: Int) {

    }
}
