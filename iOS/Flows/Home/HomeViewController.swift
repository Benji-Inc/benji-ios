//
//  CenterViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

protocol HomeViewControllerDelegate: AnyObject {
    func homeViewControllerDidSelect(item: HomeCollectionViewDataSource.ItemType)
}

class HomeViewController: DiffableCollectionViewController<HomeCollectionViewDataSource.SectionType, HomeCollectionViewDataSource.ItemType, HomeCollectionViewDataSource> {

    weak var delegate: HomeViewControllerDelegate?

    // MARK: - UI

    let addButton = Button()
    let circlesButton = Button()
    let archiveButton = Button()

    var didTapAdd: CompletionOptional = nil
    var didTapCircles: CompletionOptional = nil
    var didTapArchive: CompletionOptional = nil

    init() {
        super.init(with: CollectionView(layout: HomeCollectionViewLayout()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.view.addSubview(self.addButton)
        self.addButton.set(style: .icon(image: UIImage(systemName: "plus")!, color: .lightPurple))
        self.addButton.addAction(for: .touchUpInside) { [unowned self] in
            self.didTapAdd?()
        }

        self.view.addSubview(self.circlesButton)
        self.circlesButton.set(style: .icon(image: UIImage(systemName: "circles.hexagongrid")!, color: .lightPurple))
        self.circlesButton.addAction(for: .touchUpInside) { [unowned self] in
            self.didTapCircles?()
        }

        self.view.addSubview(self.archiveButton)
        self.archiveButton.set(style: .icon(image: UIImage(systemName: "message")!, color: .lightPurple))
        self.archiveButton.addAction(for: .touchUpInside) { [unowned self] in
            self.didTapArchive?()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.addButton.squaredSize = 60
        self.addButton.makeRound()
        self.addButton.centerOnX()
        self.addButton.pinToSafeArea(.bottom, padding: Theme.contentOffset)

        self.circlesButton.squaredSize = 60
        self.circlesButton.makeRound()
        self.circlesButton.match(.right, to: .left, of: self.addButton, offset: -Theme.contentOffset.doubled)
        self.circlesButton.pinToSafeArea(.bottom, padding: Theme.contentOffset)

        self.archiveButton.squaredSize = 60
        self.archiveButton.makeRound()
        self.archiveButton.match(.left, to: .right, of: self.addButton, offset: Theme.contentOffset.doubled)
        self.archiveButton.pinToSafeArea(.bottom, padding: Theme.contentOffset)
    }

    // MARK: Data Loading

    override func getAllSections() -> [HomeCollectionViewDataSource.SectionType] {
        return HomeCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [HomeCollectionViewDataSource.SectionType : [HomeCollectionViewDataSource.ItemType]] {
        await NoticeSupplier.shared.loadNotices()

        var data: [HomeCollectionViewDataSource.SectionType : [HomeCollectionViewDataSource.ItemType]] = [:]
        data[.notices] = NoticeSupplier.shared.notices.map { notice in
            return .notice(notice)
        }
        return data
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }

        self.delegate?.homeViewControllerDidSelect(item: identifier)
    }
}

extension HomeViewController: TransitionableViewController {
    var receivingPresentationType: TransitionType {
        return .home
    }

    var transitionColor: Color {
        return .background1
    }
}
