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

    private var emotions: [Emotion]
    private let expression: Expression

    init(expression: Expression,
         startingEmotion: Emotion?,
         delegate: ExpressionDetailViewControllerDelegate) {

        self.expression = expression
        self.delegate = delegate

        var sortedEmotions = expression.emotions
        // Put the starting emotion at the front
        if let startingEmotion = startingEmotion {
            sortedEmotions.remove(object: startingEmotion)
            sortedEmotions.insert(startingEmotion, at: 0)
        }
        self.emotions = sortedEmotions

        let collectionView = CollectionView(layout: EmotionDetailCollectionViewLayout())

        super.init(with: collectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.modalPresentationStyle = .overFullScreen

        self.loadInitialData()
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.didSelect { [weak self] in
            guard let `self` = self else { return }
            self.delegate.emotionDetailViewControllerDidFinish(self)
        }
    }
    
    override func getAllSections() -> [EmotionDetailCollectionViewDataSource.SectionType] {
        return EmotionDetailCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async
    -> [EmotionDetailCollectionViewDataSource.SectionType : [EmotionDetailCollectionViewDataSource.ItemType]] {

        var data: [EmotionDetailSection : [EmotionDetailItem]] = [:]
        var items: [EmotionDetailItem] = [.expression(self.expression)]
        let emotionItems: [EmotionDetailItem] = self.emotions.compactMap({ emotion in
            return .emotion(emotion)
        })
        items.append(contentsOf: emotionItems)
        data[.info] = items
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
