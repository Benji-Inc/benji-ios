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

    private(set) var subscription: Subscription<PFObject>?

    override func initialize() {
        super.initialize()

        self.$comments.mainSink { comments in
            self.loadSnapshot()
        }.store(in: &self.cancellables)
    }

    func loadComments() {
        self.collectionView.collectionViewLayout = self.layout
        self.collectionView.animationView.play()

        guard let p = self.post else { return }

        let query = Comment.query()!.whereKey("post", equalTo: p)
        self.subscription = Client.shared.subscribe(query)

        self.subscription?.handleEvent { query, event in
            switch event {
            case .entered(_):
                break
            case .left(let obj), .deleted(let obj):
                guard let comment = obj as? Comment else { return }
                self.comments.remove(object: comment.systemComment)
                runMain {
                    self.loadSnapshot()
                }
            case .created(let obj):
                guard let comment = obj as? Comment else { return }
                var index: Int?
                for (indx, existing) in self.comments.enumerated() {
                    if existing.updateId == comment.updateId {
                        index = indx
                    }
                }

                if let indx = index {
                    self.comments[indx] = comment.systemComment
                } else {
                    self.comments.append(comment.systemComment)
                    self.comments.sort()
                }

                runMain {
                    self.loadSnapshot()
                }
            case .updated(let obj):
                if let comment = obj as? Comment, let index = self.comments.firstIndex(of: comment.systemComment) {
                    self.comments[index] = comment.systemComment
                    runMain {
                        self.loadSnapshot()
                    }
                }
            }
        }

        // Get initial set
        self.queryForComments()
    }

    private func queryForComments() {
        let query = self.post?.comments?.query()
        query?.order(byAscending: "createdAt")

        query?.findObjectsInBackground(block: { objects, error in
            self.comments = objects?.map({ comment in
                return comment.systemComment
            }) ?? []
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
                                                             item: item as? SystemComment)
        }
    }
}
