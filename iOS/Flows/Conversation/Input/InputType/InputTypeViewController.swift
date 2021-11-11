//
//  InputTypeViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InputTypeViewController: DiffableCollectionViewController<InputTypeDataSource.SectionType, InputType, InputTypeDataSource> {

    override func retrieveDataForSnapshot() async -> [InputTypeDataSource.SectionType : [InputType]] {
        return [:]
    }

    override func getAllSections() -> [InputTypeDataSource.SectionType] {
        return [.types]
    }
}
