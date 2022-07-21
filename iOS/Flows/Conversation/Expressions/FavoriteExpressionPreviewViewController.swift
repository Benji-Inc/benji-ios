//
//  FavoriteExpressionPreviewViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FavoriteExpressionPreviewViewController: ViewController {
    
    let type: FavoriteType
    
    lazy var content = FavoriteExpressionView(with: type)
        
    init(with type: FavoriteType) {
        self.type = type
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.addSubview(self.content)
        self.content.personView.expressionVideoView.shouldPlay = true
        
        Task {
            await self.content.loadExpression()
        }
        
        guard let window = UIWindow.topWindow() else { return }
                
        self.preferredContentSize = CGSize(width: window.width * 0.5, height: window.width * 0.5)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.content.expandToSuperviewSize()
        self.content.personView.layer.cornerRadius = 5
    }
}
