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
    
    let footerView = MomentFooterView()
    lazy var contentView = MomentContentView(with: self.moment)
                
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
            sheet.preferredCornerRadius = Theme.screenRadius
        }
        
        self.view.set(backgroundColor: .B0)
        
        self.view.addSubview(self.contentView)
        self.contentView.layer.cornerRadius = Theme.screenRadius
        self.contentView.layer.masksToBounds = true
        
        self.view.addSubview(self.footerView)
                
        // If the user has not been added to the comments convo, add them. This will represent views.
        let controller = ConversationController.controller(for: self.moment.commentsId)
        controller.addMembers(userIds: Set([User.current()!.objectId!])) { [unowned self] error in
            self.footerView.configure(for: self.moment)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.contentView.expandToSuperviewWidth()
        self.contentView.height = self.view.height - self.view.safeAreaInsets.bottom - self.view.height * 0.15
        self.contentView.pin(.top)
        
        self.footerView.expandToSuperviewWidth()
        self.footerView.height = self.view.height - self.contentView.height
        self.footerView.match(.top, to: .bottom, of: self.contentView)
    }
    
    func showMomentIfAvailable() {
        self.contentView.showMomentIfAvailable()
        self.footerView.isVisible = self.moment.isAvailable
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard self.shouldHandleTouch(for: touches, event: event) else { return }
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.contentView.shouldShowDetail(true)
            self.footerView.alpha = 0.0
        }

        self.contentView.pause()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.contentView.shouldShowDetail(false)
            self.footerView.alpha = 1.0
        }
        
        self.contentView.play()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
    
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.contentView.shouldShowDetail(false)
            self.footerView.alpha = 1.0
        }
        
        self.contentView.play()
    }
    
    func shouldHandleTouch(for touches: Set<UITouch>, event: UIEvent?) -> Bool {
        guard let firstTouch = touches.first else { return false }
        let location = firstTouch.location(in: self.view)
        return location.y <= self.contentView.bottom
    }
}
