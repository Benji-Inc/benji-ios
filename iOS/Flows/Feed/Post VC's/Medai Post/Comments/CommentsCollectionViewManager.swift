//
//  CommentsCollectionViewManager.swift
//  Ours
//
//  Created by Benji Dodgson on 4/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CommentsCollectionViewManager: CollectionViewManager<CommentsCollectionViewManager.SectionType> {

    enum SectionType: Int, ManagerSectionType {
        case comments = 0
    }

    private let commentsConfig = ManageableCellRegistration<CommentCell>().cellProvider

    lazy var layout = UICollectionViewCompositionalLayout() { sectionIndex, layoutEnvironment in

        var listConfig = UICollectionLayoutListConfiguration(appearance: .grouped)

        listConfig.backgroundColor = .clear
        listConfig.showsSeparators = false

        let section = NSCollectionLayoutSection.list(using: listConfig, layoutEnvironment: layoutEnvironment)
        section.interGroupSpacing = 10

        return section
    }

    var post: Post?

    @Published var comments: [Comment] = []

    override func initialize() {
        super.initialize()

        self.$comments.mainSink { comments in
            self.loadSnapshot()
        }.store(in: &self.cancellables)
    }

    func loadComments() {
        self.collectionView.collectionViewLayout = self.layout
        self.collectionView.animationView.play()

        // Get initial set
        self.queryForComments()

        // Subsribe to get updates in real time
        self.post?.subscribe()
            .mainSink { (result) in
                switch result {
                case .success(let event):
                    switch event {
                    case .entered(let post), .left(let post), .created(let post), .updated(let post), .deleted(let post):
                        self.post = post

                        self.queryForComments()
                    }
                case .error(_):
                    break
                }
            }.store(in: &self.cancellables)
    }

    private func queryForComments() {
        let query = self.post?.comments?.query()
        query?.order(byAscending: "createdAt")
        query?.findObjectsInBackground(block: { objects, error in
            self.comments = objects ?? []
            self.collectionView.animationView.stop()
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
                                                             item: item as? Comment)
        }
    }
}
