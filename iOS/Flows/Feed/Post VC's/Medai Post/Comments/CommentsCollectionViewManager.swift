//
//  CommentsCollectionViewManager.swift
//  Ours
//
//  Created by Benji Dodgson on 4/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import ParseLiveQuery

class CommentsCollectionViewManager: CollectionViewManager<CommentsCollectionViewManager.SectionType> {

    enum SectionType: Int, ManagerSectionType {
        case comments = 0
    }

    private let commentsConfig = ManageableCellRegistration<CommentCell>().provider

    lazy var layout = UICollectionViewCompositionalLayout() { sectionIndex, layoutEnvironment in

        var listConfig = UICollectionLayoutListConfiguration(appearance: .grouped)

        listConfig.backgroundColor = .clear
        listConfig.showsSeparators = false

        let section = NSCollectionLayoutSection.list(using: listConfig, layoutEnvironment: layoutEnvironment)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 30, leading: 0, bottom: 0, trailing: 0)

        return section
    }

    var post: Post?

    @Published var comments: [SystemComment] = []

    var sub: Subscription<PFObject>?

    // remove once live queries work.
    lazy var refreshControl: UIRefreshControl = {
        let action = UIAction { action in
            self.queryForComments()
        }

        let control = UIRefreshControl(frame: .zero, primaryAction: action)
        control.tintColor = Color.white.color
        return control
    }()

    override func initialize() {
        super.initialize()

        self.collectionView.refreshControl = self.refreshControl

        self.$comments.mainSink { comments in
            self.loadSnapshot()
        }.store(in: &self.cancellables)
    }

    func loadComments() {
        self.collectionView.collectionViewLayout = self.layout
        self.collectionView.animationView.play()

        // Get initial set
        self.queryForComments()
    }

    private func queryForComments() {
        let query = self.post?.comments?.query()
        query?.order(byAscending: "createdAt")

        self.refreshControl.beginRefreshing()
        query?.findObjectsInBackground(block: { objects, error in
            self.comments = objects?.map({ comment in
                return comment.systemComment
            }) ?? []
            self.collectionView.animationView.stop()
            self.refreshControl.endRefreshing()
        })
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        switch section {
        case .comments:
            return self.comments
        }
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        switch section {
        case .comments:
            return self.collectionView.dequeueManageableCell(using: self.commentsConfig,
                                                             for: indexPath,
                                                             item: item as? SystemComment)
        }
    }
}
