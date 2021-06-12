//
//  HomeCollectionViewManager.swift
//  Ours
//
//  Created by Benji Dodgson on 6/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class HomeCollectionViewManager: CollectionViewManager<HomeCollectionViewManager.SectionType> {

    enum SectionType: Int, ManagerSectionType, CaseIterable {
        case notices
        case channels
    }

    private let noticeConfig = ManageableCellRegistration<NoticeCell>().provider
    private let connectionConfig = ManageableCellRegistration<ConnectionRequestCell>().provider
    private let alertConfig = ManageableCellRegistration<AlertCell>().provider

    override func initializeManager() {
        super.initializeManager()

    }

    func load() {
        self.collectionView.animationView.play()
        NoticeSupplier.shared.$notices.mainSink { _ in
            let cycle = AnimationCycle(inFromPosition: .inward, outToPosition: .inward, shouldConcatenate: true, scrollToEnd: false)
            self.loadSnapshot(animationCycle: cycle).mainSink { _ in
                // Begin auto scroll
                self.collectionView.animationView.stop()
            }.store(in: &self.cancellables)
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
            return []
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
        return nil
    }
}
