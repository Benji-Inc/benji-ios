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
        case users
    }


    override func initializeManager() {
        super.initializeManager()

    
    }

    override func getSections() -> [SectionType] {
        return HomeCollectionViewManager.SectionType.allCases
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        return []
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        return nil
    }
}
