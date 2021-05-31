//
//  NoticeViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 5/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticesCollectionViewController: CollectionViewController<NoticeCollectionViewManager.SectionType, NoticeCollectionViewManager> {

    static let height: CGFloat = 140

    private lazy var noticeCollectionView = NoticeCollectionView()

    override func getCollectionView() -> CollectionView {
        return self.noticeCollectionView
    }
}
