//
//  MomentDetailViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentViewController: ViewController {
    
    private let moment: Moment
    
    let expressionView = MomentExpressiontVideoView()
    let momentView = MomentVideoView()
    let cornerRadius: CGFloat = 30
    
    init(with moment: Moment) {
        self.moment = moment
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.preferredCornerRadius = self.cornerRadius
        }
        
        self.view.set(backgroundColor: .B0)
        
        self.view.addSubview(self.momentView)
        self.view.addSubview(self.expressionView)
        
        Task {
            guard let expression = self.moment.expression else { return }
            self.expressionView.expression = expression
            self.expressionView.shouldPlay = true
            
            self.momentView.moment = self.moment
            self.momentView.shouldPlay = true
        }
        
        //Load moment
        //Check if user has recorded
        //Show blur/button OR moment if recorded
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.momentView.expandToSuperviewSize()
        
        self.expressionView.squaredSize = self.view.width * 0.25
        self.expressionView.pinToSafeAreaTop()
        self.expressionView.pinToSafeAreaLeft()
    }
}
