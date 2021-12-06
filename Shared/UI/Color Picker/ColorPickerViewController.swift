//
//  ColorPickerViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ColorPickerViewController: DiffableCollectionViewController<ColorPickerCollectionViewDataSource.SectionType, ColorPickerCollectionViewDataSource.ItemType, ColorPickerCollectionViewDataSource> {

    init() {
        let cv = CollectionView(layout: ColorPickerCollectionViewLayout())
        cv.showsHorizontalScrollIndicator = false 
        super.init(with: cv)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.collectionView.isUserInteractionEnabled = true
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.animationView.isHidden = true
    }

    override func getAnimationCycle() -> AnimationCycle? {
        return AnimationCycle(inFromPosition: .inward,
                              outToPosition: .inward,
                              shouldConcatenate: true,
                              scrollToIndexPath: IndexPath(row: 0, section: 0))
    }

    // MARK: Data Loading

    override func getAllSections() -> [ColorPickerCollectionViewDataSource.SectionType] {
        return ColorPickerCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [ColorPickerCollectionViewDataSource.SectionType: [ColorPickerCollectionViewDataSource.ItemType]] {

        var data: [ColorPickerCollectionViewDataSource.SectionType: [ColorPickerCollectionViewDataSource.ItemType]] = [:]

        let color1 = CIColor(hex: "#ECCA45")!
        let color2 = CIColor(hex: "#75D7D1")!
        let color3 = CIColor(hex: "#CBE430")!
        let color4 = CIColor(hex: "#B256C1")!
        let color5 = CIColor(hex: "#E79494")!

        data[.colors] = [.color(color1), .color(color2), .color(color3), .color(color4), .color(color5)]

        return data
    }
}
