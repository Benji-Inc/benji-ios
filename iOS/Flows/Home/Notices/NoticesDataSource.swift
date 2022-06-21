//
//  NoticesDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticesDataSource: CollectionViewDataSource<NoticesDataSource.SectionType, NoticesDataSource.ItemType> {
    
    enum SectionType: Int, CaseIterable {
        case notices
    }
    
    enum ItemType: Hashable {
        case notice(SystemNotice)
    }
    
    private let noticeCell = ManageableCellRegistration<NoticeCell>().provider
    
    var didSelectRightOption: ((SystemNotice) -> Void)? = nil
    var didSelectLeftOption: ((SystemNotice) -> Void)? = nil
    var didSelectRemoveOption: ((SystemNotice) -> Void)? = nil
    
    weak var messageContentDelegate: MessageContentDelegate?
    
    // MARK: - Cell Dequeueing
    
    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        switch item {
        case .notice(let notice):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.noticeCell,
                                                                    for: indexPath,
                                                                    item: notice)
            if notice.type == .timeSensitiveMessage {
                cell.urgentMessageContentView.messageConentView.delegate = self.messageContentDelegate
            }
            cell.didSelectSecondaryOption = { [unowned self] in
                self.didSelectLeftOption?(notice)
            }
            cell.didSelectPrimaryOption = { [unowned self] in
                self.didSelectRightOption?(notice)
            }
            cell.didSelectRemove = { [unowned self] in
                self.didSelectRemoveOption?(notice)
            }
            return cell
        }
    }
}
