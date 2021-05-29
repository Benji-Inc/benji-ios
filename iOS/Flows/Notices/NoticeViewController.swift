//
//  NoticeViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 5/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticeViewController: CollectionViewController<NoticeCollectionViewManager.SectionType, NoticeCollectionViewManager> {

    private lazy var noticeCollectionView = NoticeCollectionView()


    override func getCollectionView() -> CollectionView {
        return self.noticeCollectionView
    }

}
