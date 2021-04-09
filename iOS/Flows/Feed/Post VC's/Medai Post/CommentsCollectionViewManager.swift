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
        return section
    }

    private(set) var post: Post
    @Published var comments: [Comment] = []

    init(with post: Post, collectionView: CollectionView) {
        self.post = post
        super.init(with: collectionView)
    }

    required init(with collectionView: CollectionView) {
        fatalError("init(with:) has not been implemented")
    }

    override func initialize() {
        super.initialize()

        self.collectionView.collectionViewLayout = self.layout
        self.collectionView.animationView.play()

        self.post.subscribe(andInclude: PostKey.comments.rawValue)
            .mainSink { (result) in
                switch result {
                case .success(let event):
                    switch event {
                    case .entered(let post), .left(let post), .created(let post), .updated(let post), .deleted(let post):
                        self.post = post

                        let query = self.post.comments?.query()
                        query?.findObjectsInBackground(block: { objects, error in
                            self.comments = objects ?? []
                        })
                    }
                case .error(_):
                    break
                }
            }.store(in: &self.cancellables)

        self.$comments.mainSink { comments in
            self.loadSnapshot()
        }.store(in: &self.cancellables)
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
