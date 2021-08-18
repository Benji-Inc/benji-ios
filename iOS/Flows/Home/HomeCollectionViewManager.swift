//
//  HomeCollectionViewManager.swift
//  Ours
//
//  Created by Benji Dodgson on 6/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class HomeCollectionViewManager: CollectionViewManager<HomeCollectionViewManager.SectionType> {

    enum SectionType: Int, ManagerSectionType, CaseIterable {
        case notices
        case channels
    }

    private let noticeConfig = ManageableCellRegistration<NoticeCell>().provider
    private let connectionConfig = ManageableCellRegistration<ConnectionRequestCell>().provider
    private let alertConfig = ManageableCellRegistration<AlertCell>().provider
    private let channelConfig = ManageableCellRegistration<ChannelCell>().provider
    private let footerConfig = ManageableFooterRegistration<ReservationsFooterView>().provider
    private let headerConfig = ManageableHeaderRegistration<UserHeaderView>().provider

    private var unclaimedCount: Int = 0

    var didSelectReservations: CompletionOptional = nil 

    override func initializeManager() {
        super.initializeManager()

    }

    func load() async {
        self.collectionView.animationView.play()

        async let unclaimedReservationCount = Reservation.getUnclaimedReservationCount(for: User.current()!)
        async let initialSyncFinished: Void = ChannelSupplier.shared.waitForInitialSync()
        async let noticesLoaded: Void = NoticeSupplier.shared.loadNotices()

        let _ = await (initialSyncFinished, noticesLoaded)

        self.unclaimedCount = await unclaimedReservationCount
        let cycle = AnimationCycle(inFromPosition: .inward, outToPosition: .inward, shouldConcatenate: true, scrollToEnd: false)

        self.loadSnapshot(animationCycle: cycle).mainSink { _ in
            // Begin auto scroll
            self.collectionView.animationView.stop()
        }.store(in: &self.cancellables)
    }

    override func getSections() -> [SectionType] {
        return HomeCollectionViewManager.SectionType.allCases
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        switch section {
        case .notices:
            return NoticeSupplier.shared.notices
        case .channels:
            return ChannelSupplier.shared.allChannelsSorted
        }
    }

    override func getSupplementaryView(for section: SectionType, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard section == .notices else { return nil }
            let header = self.collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            return header
        case UICollectionView.elementKindSectionFooter:
            guard section == .channels else { return nil }

            let footer = self.collectionView.dequeueConfiguredReusableSupplementary(using: self.footerConfig, for: indexPath)
            footer.configure(with: self.unclaimedCount)
            footer.button.didSelect { [unowned self] in
                self.didSelectReservations?()
            }
            return footer
        default:
            return nil
        }
        

    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        switch section {
        case .notices:
            return self.getNoticeCell(for: indexPath, item: item)
        case .channels:
            return self.getUserCell(for: indexPath, item: item)
        }
    }

    private func getNoticeCell(for indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        guard let type = NoticeSupplier.shared.notices[safe: indexPath.row]?.type else { return nil }

        switch type {
        case .alert:
            return self.collectionView.dequeueManageableCell(using: self.alertConfig,
                                                             for: indexPath,
                                                             item: item as? SystemNotice)
        case .connectionRequest:
            let cell = self.collectionView.dequeueManageableCell(using: self.connectionConfig,
                                                                 for: indexPath,
                                                                 item: item as? SystemNotice)
//            cell?.content.didUpdateConnection = { [weak self] _ in
//                // Do something??
//            }
            return cell
        default:
            return self.collectionView.dequeueManageableCell(using: self.noticeConfig,
                                                             for: indexPath,
                                                             item: item as? SystemNotice)
        }
    }

    private func getUserCell(for indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        return self.collectionView.dequeueManageableCell(using: self.channelConfig,
                                                         for: indexPath,
                                                         item: item as? DisplayableChannel)
    }

    // MARK: Menu overrides

    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
                                 point: CGPoint) -> UIContextMenuConfiguration? {

        guard let channel = ChannelSupplier.shared.allChannelsSorted[safe: indexPath.row],
              let cell = collectionView.cellForItem(at: indexPath) as? ChannelCell else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            return ChannelPreviewViewController(with: channel, size: cell.size)
        }, actionProvider: { suggestedActions in
            if channel.isFromCurrentUser {
                return self.makeCurrentUsertMenu(for: channel, at: indexPath)
            } else {
                return self.makeNonCurrentUserMenu(for: channel, at: indexPath)
            }
        })
    }
}
