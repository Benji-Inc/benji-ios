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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NoticeStore.shared.$notices
            .mainSink { [unowned self] notices in
                self.reloadNotices()
            }.store(in: &self.cancellables)
        
        self.collectionView.allowsMultipleSelection = false 
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        once(caller: self, token: "loadNotices") {
            self.loadInitialData()
        }
    }
    
    override func getAllSections() -> [NoticesDataSource.SectionType] {
        return NoticesDataSource.SectionType.allCases
    }
    
    override func retrieveDataForSnapshot() async -> [NoticesDataSource.SectionType : [NoticesDataSource.ItemType]] {
        var data: [NoticesDataSource.SectionType: [NoticesDataSource.ItemType]] = [:]
        
        try? await NoticeStore.shared.initializeIfNeeded()
        var notices = NoticeStore.shared.notices.filter({ notice in
            return notice.type != .unreadMessages
        }).sorted()
        
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
    
    private var loadNoticeTask: Task<Void, Never>?
    
    func reloadNotices() {
        
        self.loadNoticeTask?.cancel()
        
        self.loadNoticeTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            try? await NoticeStore.shared.initializeIfNeeded()
            var notices = NoticeStore.shared.notices.filter({ notice in
                return notice.type != .unreadMessages
            }).sorted()
            
            if notices.isEmpty {
                let empty = SystemNotice(createdAt: Date(),
                                         notice: nil,
                                         type: .system,
                                         priority: 0,
                                         attributes: [:])
                notices = [empty]
            }
            
            let items: [NoticesDataSource.ItemType] = notices.compactMap({ notice in
                return .notice(notice)
            })
            
            var snapshot = self.dataSource.snapshot()
            snapshot.setItems(items, in: .notices)
            
            await self.dataSource.apply(snapshot)
        }
    }
    
}
