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
    
    private let expressionView = MomentExpressiontVideoView()
    private let momentView = MomentVideoView()
    let blurView = MomentBlurView()
    
    let cornerRadius: CGFloat = 30
    
    enum State {
        case initial
        case loading
        case playback
    }
    
    @Published var state: State = .initial
    
    init(with moment: Moment) {
        self.moment = moment
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        // Show captions
        // Show profile pic
        // Date created 
        
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
        self.view.addSubview(self.blurView)
        self.view.addSubview(self.expressionView)
        
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.handle(state: state)
            }.store(in: &self.cancellables)
        
        self.state = .loading
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.momentView.expandToSuperviewSize()
        
        self.expressionView.squaredSize = self.view.width * 0.25
        self.expressionView.pinToSafeAreaTop()
        self.expressionView.pinToSafeAreaLeft()
        
        self.blurView.expandToSuperviewSize()
    }
    
    private func handle(state: State) {
        switch state {
        case .initial:
            break
        case .loading:
            
            self.blurView.configure(for: self.moment)
            self.expressionView.expression = self.moment.expression
            
            if MomentsStore.shared.hasRecordedToday || self.moment.isFromCurrentUser {
                self.blurView.animateBlur(shouldShow: false)
                self.momentView.loadFullMoment(for: self.moment)
                self.state = .playback
            } else {
                self.blurView.animateBlur(shouldShow: true)
                self.momentView.loadPreview(for: self.moment)
            }
        case .playback:
            break
        }
    }
}
