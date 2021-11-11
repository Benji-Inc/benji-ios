//
//  InputTypeViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InputTypeViewController: DiffableCollectionViewController<InputTypeDataSource.SectionType, InputType, InputTypeDataSource> {

    init() {
        super.init(with: CollectionView(layout: InputTypeCollectionViewLayout()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func retrieveDataForSnapshot() async -> [InputTypeDataSource.SectionType : [InputType]] {

        let photoInput = InputType(image: UIImage(systemName: "photo")!, text: "")
        let videoInput = InputType(image: UIImage(systemName: "video")!, text: "")
        let textInput = InputType(image: UIImage(systemName: "textformat.abc")!, text: "")
        let calendarInput = InputType(image: UIImage(systemName: "calendar")!, text: "")
        let jibInput = InputType(image: UIImage(systemName: "bitcoinsign.circle")!, text: "")

        let items = [photoInput, videoInput, textInput, calendarInput, jibInput]
        return [.types: items]
    }

    override func getAllSections() -> [InputTypeDataSource.SectionType] {
        return [.types]
    }
}
