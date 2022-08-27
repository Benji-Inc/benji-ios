//
//  EmotionDetailViewController.swift
//  Jibber
//
//  Created by Martin Young on 4/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Transitions

protocol ExpressionDetailViewControllerDelegate: AnyObject {
    func emotionDetailViewControllerDidFinish(_ controller: ExpressionDetailViewController)
}

class ExpressionDetailViewController: DiffableCollectionViewController<EmotionDetailSection,
                                   EmotionDetailItem,
                                   EmotionDetailCollectionViewDataSource> {

    unowned let delegate: ExpressionDetailViewControllerDelegate

    private var emotions: [Emotion] = []
    private let startingExpression: ExpressionInfo?
    private let expressions: [ExpressionInfo]
    
    let pageIndicator = PagingIndicatorView(with: .onExpressionIndexChanged)

    init(startingExpression: ExpressionInfo,
         expressions: [ExpressionInfo],
         delegate: ExpressionDetailViewControllerDelegate) {

        self.startingExpression = startingExpression
        self.expressions = expressions
        
        self.delegate = delegate

        let collectionView = CollectionView(layout: EmotionDetailCollectionViewLayout())

        super.init(with: collectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()

        self.view.didSelect { [weak self] in
            guard let `self` = self else { return }
            self.delegate.emotionDetailViewControllerDidFinish(self)
        }
        
        self.view.insertSubview(self.pageIndicator, aboveSubview: self.collectionView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.modalPresentationStyle = .overFullScreen

        self.loadInitialData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.pageIndicator.height = 20
        self.pageIndicator.expandToSuperviewWidth()
        self.pageIndicator.pinToSafeAreaBottom()
    }
    
    override func getAllSections() -> [EmotionDetailCollectionViewDataSource.SectionType] {
        return EmotionDetailCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async
    -> [EmotionDetailCollectionViewDataSource.SectionType : [EmotionDetailCollectionViewDataSource.ItemType]] {

        var data: [EmotionDetailSection : [EmotionDetailItem]] = [:]
        let items: [EmotionDetailItem] = self.expressions.compactMap({ info in
            return .expression(info)
        })
        
        data[.info] = items
        
        self.pageIndicator.pageIndicator.numberOfPages = items.count
        self.pageIndicator.layoutNow()

        return data
    }
}

extension ExpressionDetailViewController: TransitionableViewController {

    var dismissalType: TransitionType {
        return .custom(type: "blur", model: nil, duration: Theme.animationDurationSlow)
    }

    var presentationType: TransitionType {
        return .custom(type: "blur", model: nil, duration: Theme.animationDurationSlow)
    }
}
