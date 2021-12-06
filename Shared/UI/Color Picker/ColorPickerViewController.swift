//
//  ColorPickerViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ColorPickerViewController: DiffableCollectionViewController<ColorPickerCollectionViewDataSource.SectionType, ColorPickerCollectionViewDataSource.ItemType, ColorPickerCollectionViewDataSource> {

    private lazy var colorWheelVC: ColorWheelViewController = {
        let vc = ColorWheelViewController()
        vc.delegate = self
        return vc
    }()

    lazy var colors: [ColorPickerCollectionViewDataSource.ItemType] = {
        let color1 = CIColor(hex: "#75D7D1")!
        let color2 = CIColor(hex: "#CBE430")!
        let color3 = CIColor(hex: "#B256C1")!
        let color4 = CIColor(hex: "#E79494")!
        let color5 = CIColor(hex: "#EFB661")!
        let color6 = CIColor.clear
        return [.color(color1), .color(color2), .color(color3), .color(color4), .color(color5), .wheel(color6)]
    }()

    @Published var selectedColor: CIColor? = nil

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

        self.$selectedItems.mainSink { [unowned self] items in
            guard let first = items.first else { return }
            switch first {
            case .color(let color):
                self.dataSource.reconfigureItem(atIndex: 5, in: .colors)
                self.selectedColor = color
            case .wheel(_):
                self.present(self.colorWheelVC, animated: true, completion: nil)
            }
        }.store(in: &self.cancellables)
    }

    override func getAnimationCycle() -> AnimationCycle? {
        return AnimationCycle(inFromPosition: .inward,
                              outToPosition: .inward,
                              shouldConcatenate: true,
                              scrollToIndexPath: IndexPath(row: 0, section: 0))
    }

    override func handleDataBeingLoaded() {
        super.handleDataBeingLoaded()

        let ip = IndexPath(item: 0, section: 0)
        self.collectionView.selectItem(at: ip, animated: true, scrollPosition: .left)
        self.collectionView.delegate?.collectionView?(self.collectionView, didSelectItemAt: ip)
    }

    // MARK: Data Loading

    override func getAllSections() -> [ColorPickerCollectionViewDataSource.SectionType] {
        return ColorPickerCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [ColorPickerCollectionViewDataSource.SectionType: [ColorPickerCollectionViewDataSource.ItemType]] {

        var data: [ColorPickerCollectionViewDataSource.SectionType: [ColorPickerCollectionViewDataSource.ItemType]] = [:]

        data[.colors] = self.colors
        return data
    }
}

extension ColorPickerViewController: UIColorPickerViewControllerDelegate {

    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        self.dismiss(animated: true, completion: nil)
    }

    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {

        let color = CIColor(color: viewController.selectedColor)
        self.selectedColor = color
    }

    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {

    }
}

private class ColorWheelViewController: UIColorPickerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.supportsAlpha = false

        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
    }
}
