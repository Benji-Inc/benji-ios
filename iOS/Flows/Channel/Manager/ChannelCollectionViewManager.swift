//
//  ChannelCollectionViewManager.swift
//  Benji
//
//  Created by Benji Dodgson on 11/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Combine

@MainActor
class ChannelCollectionViewManager: NSObject, UITextViewDelegate, ChannelDataSource,
UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching, ActiveChannelAccessor {

    enum ScrollDirection {
        case up
        case down
        case noMovement
    }

    private var lastContentOffset: CGFloat = 0
    private var lastScrollDirection: ScrollDirection = .noMovement

    var numberOfMembers: Int = 0 {
        didSet {
            if self.numberOfMembers != oldValue {
                self.collectionView.reloadDataAndKeepOffset()
            }
        }
    }

    var sections: [ChannelSectionable] = [] {
        didSet {
            self.updateLayoutDataSource()
        }
    }

    var collectionView: ChannelCollectionView
    var didSelectURL: ((URL) -> Void)?
    var didTapShare: ((Messageable) -> Void)?
    var didTapResend: ((Messageable) -> Void)?
    var didTapEdit: ((Messageable, IndexPath) -> Void)?
    var willDisplayCell: ((Messageable, IndexPath) -> Void)?
    var userTyping: User?
    private var footerView: ReadAllFooterView?
    private var isSettingReadAll = false
    var cancellables = Set<AnyCancellable>()

    init(with collectionView: ChannelCollectionView) {
        self.collectionView = collectionView
        super.init()
        self.updateLayoutDataSource()

        ChannelSupplier.shared.$activeChannel.mainSink { [weak self] (channel) in
            guard let `self` = self, let activeChannel = channel else { return }
            switch activeChannel.channelType {
            case .channel(let channel):
                channel.getMembersCount { (result, count) in
                    self.numberOfMembers = Int(count)
                }
            default:
                break
            }
        }.store(in: &self.cancellables)

        self.collectionView.panGestureRecognizer.addTarget(self, action: #selector(handle(_:)))
    }

    private func updateLayoutDataSource() {
        self.collectionView.prefetchDataSource = self 
        self.collectionView.channelLayout.dataSource = self
    }

    // MARK: DATA SOURCE

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let channelCollectionView = collectionView as? ChannelCollectionView else { return 0 }
        var numberOfSections = self.numberOfSections()

        if !channelCollectionView.isTypingIndicatorHidden {
            numberOfSections += 1
        }

        return numberOfSections
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        if self.isSectionReservedForTypingIndicator(section) {
            return 1
        }

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

        guard let channelCollectionView = collectionView as? ChannelCollectionView else { fatalError() }

        if self.isSectionReservedForTypingIndicator(indexPath.section) {
            let cell = channelCollectionView.dequeueReusableCell(TypingIndicatorCell.self, for: indexPath)
            if let user = self.userTyping {
                cell.configure(with: user)
            }
            return cell
        }

        guard let message = self.item(at: indexPath) else { return UICollectionViewCell() }

        let cell: BaseMessageCell
        switch message.kind {
        case .text(_):
            cell = channelCollectionView.dequeueReusableCell(MessageCell.self, for: indexPath)
            if let msgCell = cell as? MessageCell {
                msgCell.textView.delegate = self
                let interaction = UIContextMenuInteraction(delegate: self)
                msgCell.bubbleView.addInteraction(interaction)
            }
        case .attributedText(_):
            cell = channelCollectionView.dequeueReusableCell(AttributedMessageCell.self, for: indexPath)
        case .photo(_, _):
            cell = channelCollectionView.dequeueReusableCell(PhotoMessageCell.self, for: indexPath)
            if let photoCell = cell as? PhotoMessageCell {
                photoCell.textView.delegate = self
                let interaction = UIContextMenuInteraction(delegate: self)
                photoCell.imageView.addInteraction(interaction)
            }
        case .video(_, _):
            cell = channelCollectionView.dequeueReusableCell(VideoMessageCell.self, for: indexPath)
        case .location(_):
            cell = channelCollectionView.dequeueReusableCell(LocationMessageCell.self, for: indexPath)
        case .emoji(_):
            cell = channelCollectionView.dequeueReusableCell(EmojiMessageCell.self, for: indexPath)
        case .audio(_):
            cell = channelCollectionView.dequeueReusableCell(AudioMessageCell.self, for: indexPath)
        case .contact(_):
            cell = channelCollectionView.dequeueReusableCell(ContactMessageCell.self, for: indexPath)
        case .link(_):
            cell = channelCollectionView.dequeueReusableCell(LinkCell.self, for: indexPath)
            if let msgCell = cell as? LinkCell {
                let interaction = UIContextMenuInteraction(delegate: self)
                msgCell.imageView.addInteraction(interaction)
            }
        }

        cell.configure(with: message)
        cell.didTapMessage = { [weak self] in
            guard let `self` = self else { return }
            self.updateConsumers(for: message)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            return self.header(for: collectionView, at: indexPath)
        case UICollectionView.elementKindSectionFooter:
            return self.footer(for: collectionView, at: indexPath)
        default:
            fatalError("UNRECOGNIZED SECTION KIND")
        }
    }

    private func header(for collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let channelCollectionView = collectionView as? ChannelCollectionView else { fatalError() }

        if self.isSectionReservedForTypingIndicator(indexPath.section) {
            return channelCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "EmptyHeader", for: indexPath)
        }

        guard let section = self.sections[safe: indexPath.section] else { fatalError() }

        if indexPath.section == 0 {
           if let topHeader = self.getTopHeader(for: section, at: indexPath, in: channelCollectionView) {
                return topHeader
            }
        }

        let header = channelCollectionView.dequeueReusableHeaderView(ChannelSectionHeader.self, for: indexPath)
        header.configure(with: section.date)
        
        return header
    }

    private func getTopHeader(for section: ChannelSectionable,
                              at indexPath: IndexPath,
                              in collectionView: ChannelCollectionView) -> UICollectionReusableView? {

        guard let index = section.firstMessageIndex, index > 0 else { return nil }

        let moreHeader = collectionView.dequeueReusableHeaderView(LoadMoreSectionHeader.self, for: indexPath)

        moreHeader.button.didSelect { [weak self] in
            guard let `self` = self else { return }
            moreHeader.button.handleEvent(status: .loading)
            self.didSelectLoadMore(for: index)
        }

        return moreHeader
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        if let cell = cell as? TypingIndicatorCell {
            if let _ = self.userTyping {
                cell.startAnimating()
            }
        } else if let message = self.item(at: indexPath){
            self.willDisplayCell?(message, indexPath)
        }
    }

    private func footer(for collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let channelCollectionView = collectionView as? ChannelCollectionView else { fatalError() }

        guard indexPath.section == self.numberOfSections(in: collectionView) - 1 else {
            return channelCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "EmptyFooter", for: indexPath)
        }

        let footer = channelCollectionView.dequeueReusableFooterView(ReadAllFooterView.self, for: indexPath)
        footer.configure(hasUnreadMessages: MessageSupplier.shared.hasUnreadMessage) 
        self.footerView = footer
        footer.didCompleteAnimation = { [unowned self] in
            self.setAllMessagesToRead(for: footer)
        }
        return footer
    }

    // MARK: FLOW LAYOUT

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let channelLayout = collectionViewLayout as? ChannelCollectionViewFlowLayout else { return .zero }

        /// May not have a message because of the typing indicator
        let message = self.item(at: indexPath)
        return channelLayout.sizeForItem(at: indexPath, with: message)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {

        guard let channelLayout = collectionViewLayout as? ChannelCollectionViewFlowLayout else {
            return .zero
        }

        return channelLayout.sizeForHeader(at: section, with: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let channelLayout = collectionViewLayout as? ChannelCollectionViewFlowLayout,
            section == self.numberOfSections(in: collectionView) - 1,
            !self.isSettingReadAll else { return .zero }

        return CGSize(width: collectionView.width, height: channelLayout.readFooterHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplaySupplementaryView view: UICollectionReusableView,
                        forElementKind elementKind: String,
                        at indexPath: IndexPath) {
        guard let footerView = self.footerView else { return }

        if elementKind == UICollectionView.elementKindSectionFooter {
            if footerView.animator.isNil {
                footerView.createAnimator()
            }
        }
    }

    // MARK: TEXT VIEW DELEGATE

    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        return true
    }

    func didSelectLoadMore(for messageIndex: Int) {
        guard let channelDisplayable = ChannelSupplier.shared.activeChannel else { return }

        switch channelDisplayable.channelType {
        case .system(_):
            break
        case .pending(_):
            break 
        case .channel(let channel):
            MessageSupplier.shared.getMessages(before: UInt(messageIndex - 1), for: channel)
                .mainSink(receiveValue: { (sections) in
                    self.set(newSections: sections,
                             keepOffset: true,
                             completion: nil)
                }).store(in: &self.cancellables)
        }
    }

    @objc func handle(_ recognizer: UIPanGestureRecognizer) {
        guard let footer = self.footerView else { return }

        if footer.animator.isNil {
            footer.createAnimator()
        }

        guard let animator = footer.animator else { return }
        switch recognizer.state {
        case .began:
            animator.isReversed = false
            animator.pauseAnimation()
        case .changed:
            animator.pauseAnimation()
            animator.fractionComplete = self.getProgress(for: footer)
        case .ended:
            animator.startAnimation()
            if animator.fractionComplete < 0.99 || self.lastScrollDirection == .down {
                if animator.fractionComplete > 0.1, self.lastScrollDirection == .up {
                    self.collectionView.scrollToLastItem()
                }
                animator.isReversed = true
                let provider = UICubicTimingParameters(animationCurve: .linear)
                animator.continueAnimation(withTimingParameters: provider, durationFactor: 0.25)
            } else if self.lastScrollDirection == .up {
                animator.isReversed = false
                let provider = UICubicTimingParameters(animationCurve: .linear)
                animator.continueAnimation(withTimingParameters: provider, durationFactor: 0.25)
            }
        default:
            break
        }
    }

    private func getProgress(for footer: ReadAllFooterView) -> CGFloat {
        let threshold: CGFloat = 80
        let contentOffset = self.collectionView.contentOffset.y
        let contentHeight = self.collectionView.contentSize.height
        let diffHeight = contentHeight - contentOffset
        let frameHeight = self.collectionView.bounds.size.height - self.collectionView.adjustedContentInset.bottom - 10 //Additional bottom inset
        var triggerThreshold = (diffHeight - frameHeight)/threshold
        triggerThreshold = min(triggerThreshold, 0.0)
        let pullRatio = min(abs(triggerThreshold), 1.0)
        return pullRatio
    }

    private func setAllMessagesToRead(for footer: ReadAllFooterView) {
        if !self.isSettingReadAll,
           MessageSupplier.shared.unreadMessages.count > 0,
           self.lastScrollDirection == .up {
            self.isSettingReadAll = true
            footer.animationView.play()
            self.setAllMessagesToRead()
                .mainSink(receiveValue: { (_) in
                    footer.stop()
                    self.isSettingReadAll = false
                    self.collectionView.scrollToLastItem()
                }).store(in: &self.cancellables)
        } else if self.lastScrollDirection == .up {
            footer.stop()
            self.collectionView.scrollToLastItem()
        }
    }

    // this delegate is called when the scrollView (i.e your UITableView) will start scrolling
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }

    // while scrolling this delegate is being called so you may now check which direction your scrollView is being scrolled to
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.lastContentOffset < scrollView.contentOffset.y {
            self.lastScrollDirection = .up
        } else if self.lastContentOffset > scrollView.contentOffset.y {
            self.lastScrollDirection = .down
        } else {
            self.lastScrollDirection = .noMovement
        }
    }
}


