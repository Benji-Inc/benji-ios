//
//  CommonExpressionsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CommonExpressionsViewController: DiffableCollectionViewController<CommonExpressionsDataSource.SectionType,
                                       CommonExpressionsDataSource.ItemType,
                                       CommonExpressionsDataSource> {

    init() {
        super.init(with: CommonExpressionsCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getAllSections() -> [CommonExpressionsDataSource.SectionType] {
        return CommonExpressionsDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [CommonExpressionsDataSource.SectionType : [CommonExpressionsDataSource.ItemType]] {
        
        // Grab expressions
        // Filter by emotion
        // Add to section 
        return [:]
    }
}
