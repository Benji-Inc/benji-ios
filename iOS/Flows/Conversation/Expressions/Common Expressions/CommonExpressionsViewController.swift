//
//  CommonExpressionsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CommonExpressionsViewController: DiffableCollectionViewController<CommonExpressionsDataSource.SectionType,
                                       CommonExpressionsDataSource.ItemType,
                                       CommonExpressionsDataSource> {

    init() {
        super.init(with: CommonExpressionsCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.allowsMultipleSelection = false 
    }
    
    override func getAllSections() -> [CommonExpressionsDataSource.SectionType] {
        return CommonExpressionsDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [CommonExpressionsDataSource.SectionType : [CommonExpressionsDataSource.ItemType]] {
        
        // Grab expressions
        // Filter by emotion
        // Add to section
        
        let model1 = ExpressionModel(existingExpression: nil, defaultEmotion: .happy)
        let model2 = ExpressionModel(existingExpression: nil, defaultEmotion: .sad)
        let model3 = ExpressionModel(existingExpression: nil, defaultEmotion: .afraid)
        let model4 = ExpressionModel(existingExpression: nil, defaultEmotion: .angry)
        let model5 = ExpressionModel(existingExpression: nil, defaultEmotion: .surprised)
        let model6 = ExpressionModel(existingExpression: nil, defaultEmotion: .disgust)
        
        return [.expressions: [.expression(model1), .expression(model2), .expression(model4), .expression(model5), .expression(model6)]]
    }
}
