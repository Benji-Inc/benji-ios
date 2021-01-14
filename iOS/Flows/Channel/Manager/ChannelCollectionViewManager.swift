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

class ChannelCollectionViewManager: NSObject, UITextViewDelegate, ChannelDataSource,
UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ActiveChannelAccessor {

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
    private let selectionFeedback = UIImpactFeedbackGenerator(style: .heavy)
    var userTyping: User?
    private var footerView: ReadAllFooterView?
    private var isSettingReadAll = false
    private var cancellables = Set<AnyCancellable>()

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
        case .photo(_):
            cell = channelCollectionView.dequeueReusableCell(PhotoMessageCell.self, for: indexPath)
        case .video(_):
            cell = channelCollectionView.dequeueReusableCell(VideoMessageCell.self, for: indexPath)
        case .location(_):
            cell = channelCollectionView.dequeueReusableCell(LocationMessageCell.self, for: indexPath)
        case .emoji(_):
            cell = channelCollectionView.dequeueReusableCell(EmojiMessageCell.self, for: indexPath)
        case .audio(_):
            cell = channelCollectionView.dequeueReusableCell(AudioMessageCell.self, for: indexPath)
        case .contact(_):
            cell = channelCollectionView.dequeueReusableCell(ContactMessageCell.self, for: indexPath)
        }

        cell.configure(with: message)
        cell.didTapMessage = { [weak self] in
            guard let `self` = self, let current = User.current(), !message.isFromCurrentUser, message.canBeConsumed  else { return }

            self.updateConsumers(with: current, for: message)
            self.selectionFeedback.impactOccurred()
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
            return UICollectionReusableView()
        }

        guard let section = self.sections[safe: indexPath.section] else { fatalError() }

        if indexPath.section == 0 {
            if let messageIndex = self.item(at: IndexPath(item: 0, section: 0))?.messageIndex,
                messageIndex == 0,
                let header = self.getIntroHeader(for: section, at: indexPath, in: channelCollectionView) {
                return header
            } else if let topHeader = self.getTopHeader(for: section, at: indexPath, in: channelCollectionView) {
                return topHeader
            }
        }

        let header = channelCollectionView.dequeueReusableHeaderView(ChannelSectionHeader.self, for: indexPath)
        header.configure(with: section.date)
        
        return header
    }

    private func getIntroHeader(for section: ChannelSectionable,
                                at indexPath: IndexPath,
                                in collectionView: ChannelCollectionView) -> UICollectionReusableView? {
        guard let channel = self.activeChannel else { return nil }
        let header = collectionView.dequeueReusableHeaderView(ChannelIntroHeader.self, for: indexPath)
        header.configure(with: channel)
        return header
    }

    private func getTopHeader(for section: ChannelSectionable,
                              at indexPath: IndexPath,
                              in collectionView: ChannelCollectionView) -> UICollectionReusableView? {

        guard let index = section.firstMessageIndex, index > 0 else { return nil }

        let moreHeader = collectionView.dequeueReusableHeaderView(LoadMoreSectionHeader.self, for: indexPath)
        //Reset all gestures
        moreHeader.gestureRecognizers?.forEach({ (recognizer) in
            moreHeader.removeGestureRecognizer(recognizer)
        })

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

        guard indexPath.section == self.numberOfSections(in: collectionView) - 1 else { return UICollectionReusableView() }

        let footer = channelCollectionView.dequeueReusableFooterView(ReadAllFooterView.self, for: indexPath)
        let hasUnreadMessages = MessageSupplier.shared.unreadMessages.count > 0
        footer.configure(hasUnreadMessages: hasUnreadMessages, section: indexPath.section)
        self.footerView = footer
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
            footerView.prepareInitialAnimation()
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        didEndDisplayingSupplementaryView view: UICollectionReusableView,
                        forElementOfKind elementKind: String,
                        at indexPath: IndexPath) {
        guard let footerView = self.footerView else { return }

        if elementKind == UICollectionView.elementKindSectionFooter {
            footerView.stop()
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
            animator.pauseAnimation()
            //self.fractionCompletedStart = animator.fractionComplete
            //self.dragStartPosition = recognizer.location(in: view)
        case .changed:
            animator.pauseAnimation()
            //let delta = recognizer.location(in: view).x - self.dragStartPosition.x
            //animator.fractionComplete = max(0.0, min(1.0, fractionCompletedStart + delta / 300.0))
            animator.fractionComplete = self.getProgress(for: footer)
        case .ended:
            animator.startAnimation()
        default:
            break
        }
    }

    private func getProgress(for footer: ReadAllFooterView) -> CGFloat {
        let threshold = 60
        let contentOffset = self.collectionView.contentOffset.y
        let contentHeight = self.collectionView.contentSize.height + self.collectionView.contentInset.top + footer.height - self.collectionView.contentInset.bottom
        let diffHeight = contentHeight - contentOffset
        let frameHeight = self.collectionView.bounds.size.height
        var triggerThreshold = Float((diffHeight - frameHeight))/Float(threshold)
        triggerThreshold = min(triggerThreshold, 0.0)
        let pullRatio = min(abs(triggerThreshold), 1.0)
        print(pullRatio)
        return CGFloat(pullRatio)
    }

    //compute the scroll value and play witht the threshold to get desired effect
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard let footerView = self.footerView, let channelCollectionView = scrollView as? ChannelCollectionView else { return }
//
//        let threshold = 60
//        let contentOffset = channelCollectionView.contentOffset.y
//        let contentHeight = channelCollectionView.contentSize.height + channelCollectionView.contentInset.top + footerView.height - channelCollectionView.contentInset.bottom
//        let diffHeight = contentHeight - contentOffset
//        let frameHeight = channelCollectionView.bounds.size.height
//        var triggerThreshold = Float((diffHeight - frameHeight))/Float(threshold)
//        triggerThreshold = min(triggerThreshold, 0.0)
//        let pullRatio = min(abs(triggerThreshold), 1.0)
//        print(pullRatio)
        //footerView.animator.fractionComplete = CGFloat(pullRatio)
        //footerView.setTransform(inTransform: .identity, scaleFactor: CGFloat(pullRatio))
//        if pullRatio >= 1 {
//            footerView.animateFinal()
//        }
    }

    //compute the offset and call the load method
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        guard let footerView = self.footerView, let channelCollectionView = scrollView as? ChannelCollectionView else { return }
//
//        let contentOffset = channelCollectionView.contentOffset.y
//        let contentHeight = channelCollectionView.contentSize.height + channelCollectionView.contentInset.top + footerView.height
//        let diffHeight = contentHeight - contentOffset
//        let frameHeight = channelCollectionView.bounds.size.height
//        let pullHeight  = abs(diffHeight - frameHeight)
//        let minOffsetRequired = channelCollectionView.contentInset.bottom + channelCollectionView.channelLayout.readFooterHeight
//        if pullHeight <  minOffsetRequired {
//            if footerView.isAnimatingFinal, MessageSupplier.shared.unreadMessages.count > 0 {
//                self.isSettingReadAll = true
//                footerView.start(showLoading: true)
//                self.setAllMessagesToRead()
//                    .mainSink(receiveValue: { (_) in
//                        footerView.stop()
//                        self.isSettingReadAll = false
//                    }).store(in: &self.cancellables)
//            } else {
//                footerView.start(showLoading: false)
//                delay(1.0) {
//                    footerView.stop()
//                    channelCollectionView.scrollToLastItem()
//                }
//            }
//        }
    }
}


