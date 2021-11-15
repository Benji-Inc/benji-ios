//
//  InputTypeViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InputTypeViewController: DiffableCollectionViewController<InputTypeDataSource.SectionType,
                               InputType,
                               InputTypeDataSource> {

    init() {
        super.init(with: CollectionView(layout: InputTypeCollectionViewLayout()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadData() async {
        await super.loadData()

        self.selectedItems = [.keyboard]
    }

    override func retrieveDataForSnapshot() async -> [InputTypeDataSource.SectionType : [InputType]] {

        let items: [InputType] = [.photo, .video, .keyboard, .calendar, .jibs]
        return [.types: items]
    }

    override func getAllSections() -> [InputTypeDataSource.SectionType] {
        return [.types]
    }
}
