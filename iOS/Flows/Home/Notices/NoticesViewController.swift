//
//  NoticesViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticesViewController: DiffableCollectionViewController<NoticesDataSource.SectionType,
                             NoticesDataSource.ItemType,
                                NoticesDataSource> {
    
    init() {
        super.init(with: NoticesCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getAllSections() -> [NoticesDataSource.SectionType] {
        return NoticesDataSource.SectionType.allCases
    }
    
    override func retrieveDataForSnapshot() async -> [NoticesDataSource.SectionType : [NoticesDataSource.ItemType]] {
        var data: [NoticesDataSource.SectionType: [NoticesDataSource.ItemType]] = [:]
        
        try? await NoticeStore.shared.initializeIfNeeded()
        var notices = NoticeStore.shared.getAllNotices().filter({ notice in
            return notice.type != .unreadMessages
        })
        
        if notices.isEmpty {
            let empty = SystemNotice(createdAt: Date(),
                                     notice: nil,
                                     type: .system,
                                     priority: 0,
                                     attributes: [:])
            notices = [empty]
        }
        
        data[.notices] = notices.compactMap({ notice in
            return .notice(notice)
        })
        
        return data
    }
}
