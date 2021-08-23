//  Copyright © 2019 Tomorrow Ideas Inc. All rights reserved.

import Foundation
import Combine

protocol ManagerSectionType: Hashable, RawRepresentable where Self.RawValue == Int {}

class CollectionViewManager<SectionType: ManagerSectionType>: NSObject, UICollectionViewDelegate,
                                                              UICollectionViewDelegateFlowLayout {

    lazy var dataSource: UICollectionViewDiffableDataSource<SectionType, AnyHashable> = {
        let dataSource = UICollectionViewDiffableDataSource<SectionType, AnyHashable>(collectionView: self.collectionView) { (cv, indexPath, item) -> UICollectionViewCell? in
            guard let type = SectionType.init(rawValue: indexPath.section),
                  let cell = self.getCell(for: type, indexPath: indexPath, item: self.getItem(for: indexPath)) else { return nil }

            self.managerDidConfigure(cell: cell, for: indexPath)
            cell.onLongPress = { [unowned self] in
                guard let item = self.getItem(for: indexPath) else { return }
                self.didLongPress?(item, indexPath)
            }

            return cell
        }

        dataSource.supplementaryViewProvider = { cv, kind, indexPath in
            guard let type = SectionType.init(rawValue: indexPath.section) else { return nil }
            return self.getSupplementaryView(for: type, kind: kind, indexPath: indexPath)
        }

        return dataSource
    }()

    var allowMultipleSelection: Bool = false

    private(set) var oldSelectedIndexPaths: Set<IndexPath> = []
    private(set) var selectedIndexPaths: Set<IndexPath> = [] {
        didSet {
            self.oldSelectedIndexPaths = oldValue
        }
    }

    var selectedItems: [AnyHashable] {
        var items: [AnyHashable] = []
        for indexPath in self.selectedIndexPaths {
            if let item = self.getItem(for: indexPath) {
                items.append(item)
            }
        }
        return items
    }

    @Published var onSelectedItem: (item: AnyHashable, section: SectionType)? = nil
    var didLongPress: ((AnyHashable, IndexPath) -> Void)? = nil
    var cancellables = Set<AnyCancellable>()

    unowned let collectionView: CollectionView

    required init(with collectionView: CollectionView) {
        self.collectionView = collectionView
        super.init()
        self.initializeManager()
    }

    func initializeManager() {
        self.collectionView.dataSource = self.dataSource
        self.collectionView.delegate = self
    }

    func loadSnapshot(animationCycle: AnimationCycle? = nil, animatingDifferences: Bool = false) async {
        return await withCheckedContinuation { continuation in
            let snapshot = self.createSnapshot()

            Task.onMainActor {
                if let cycle = animationCycle {
                    self.animateOut(position: cycle.outToPosition, concatenate: cycle.shouldConcatenate) {
                        self.dataSource.apply(snapshot, animatingDifferences: animatingDifferences) {
                            self.animateIn(position: cycle.inFromPosition,
                                           concatenate: cycle.shouldConcatenate,
                                           scrollToEnd: cycle.scrollToEnd) {

                                continuation.resume(returning: ())
                            }
                        }
                    }
                } else {
                    self.dataSource.apply(snapshot, animatingDifferences: false) {
                        continuation.resume(returning: ())
                    }
                }
            }
        }
    }

    func createSnapshot() -> NSDiffableDataSourceSnapshot<SectionType, AnyHashable> {
        var snapshot = NSDiffableDataSourceSnapshot<SectionType, AnyHashable>()

        let allCases = self.getSections()
        snapshot.appendSections(allCases)
        allCases.forEach { (section) in
            snapshot.appendItems(self.getItems(for: section), toSection: section)
        }

        return snapshot
    }

    func reset(animate: Bool = false) {
        self.selectedIndexPaths = []
        var snapshot = self.dataSource.snapshot()

        let all = self.getSections()
        snapshot.deleteSections(all)
        snapshot.deleteAllItems()

        self.dataSource.apply(snapshot, animatingDifferences: animate, completion: {
            self.collectionView.contentSize = .zero
        })
    }

    func unselectAllItems() {
        self.selectedIndexPaths = []
        self.updateSelected(indexPaths: self.selectedIndexPaths, and: self.oldSelectedIndexPaths)
    }

    // MARK: Item Overrides

    func getSections() -> [SectionType] {
        fatalError("getSections() not implemented")
    }

    func getItems(for section: SectionType) -> [AnyHashable] {
        fatalError("getItems() not implemented")
    }

    func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        fatalError("getCell() not implemented")
    }

    func getSupplementaryView(for section: SectionType, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        return nil
    }

    func getItem(for indexPath: IndexPath) -> AnyHashable? {
        guard let section = SectionType.init(rawValue: indexPath.section) else { return nil }
        return self.getItem(for: section, index: indexPath.row)
    }

    func getItem(for section: SectionType, index: Int) -> AnyHashable? {
        return self.getItems(for: section)[safe: index]
    }

    // MARK: Cell Selection

    func select(indexPath: IndexPath) {
        guard let item = self.getItem(for: indexPath) else { return }

        if self.selectedIndexPaths.contains(indexPath) {
            self.selectedIndexPaths.remove(indexPath)
        } else if self.allowMultipleSelection {
            self.selectedIndexPaths.insert(indexPath)
        } else {
            self.selectedIndexPaths = [indexPath]
        }

        self.willScrollToSelected(indexPath: indexPath)

        if let section = SectionType.init(rawValue: indexPath.section) {
            self.onSelectedItem = (item, section)
        }

        self.updateSelected(indexPaths: self.selectedIndexPaths, and: self.oldSelectedIndexPaths)
    }

    private func updateSelected(indexPaths: Set<IndexPath>, and oldIndexPaths: Set<IndexPath>) {
        // Reset all the old indexPaths if they are not also in the new array
        oldIndexPaths.forEach { (indexPath) in
            if let cell = self.collectionView.cellForItem(at: indexPath) as? CollectionViewManagerCell {
                if !indexPaths.contains(indexPath) {
                    cell.update(isSelected: false)
                } else {
                    cell.update(isSelected: true)
                }
            }
        }

        indexPaths.forEach { (indexPath) in
            if let cell = self.collectionView.cellForItem(at: indexPath) as? CollectionViewManagerCell {
                cell.update(isSelected: true)
            }
        }
    }

    func willScrollToSelected(indexPath: IndexPath) {}

    // Subclasses can override this to do more cell configuration
    func managerDidConfigure(cell: CollectionViewManagerCell?, for indexPath: IndexPath) {
        cell?.update(isSelected: self.selectedIndexPaths.contains(indexPath))
    }

    // MARK: CollectionView Delegate

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = .clear
        }
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = .clear
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.select(indexPath: indexPath)
    }

    // MARK: CollectionView Flow Layout Delegate

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        return layout.itemSize
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero 
    }

    // MARK: CollectionView Menu

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return nil 
    }

    // MARK: ScrollView Delegate (These are part of the collectionview delegate)

    func scrollViewDidScroll(_ scrollView: UIScrollView) { }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {}

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) { }
}

