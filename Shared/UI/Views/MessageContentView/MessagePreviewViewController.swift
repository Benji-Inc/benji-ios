//
//  MessagePreviewViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/7/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessagePreviewViewController: ViewController {

    let message: Messageable

    private let content = MessageContentView()
    
    let redview = BaseView()

    init(with message: Messageable) {
        self.message = message
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        guard let window = UIWindow.topWindow() else { return }
        
        window.addSubview(self.redview)
        self.redview.set(backgroundColor: .red)
        self.redview.didSelect { [unowned self] in
            logDebug("Did tap")
        }
        
        self.content.layoutState = .expanded
        self.view.addSubview(self.content)
        self.content.configureBackground(color: ThemeColor.B6.color,
                                         textColor: ThemeColor.white.color,
                                         brightness: 1.0,
                                         showBubbleTail: false,
                                         tailOrientation: .up)
        self.content.configure(with: self.message)

        let maxWidth = window.width - Theme.ContentOffset.xtraLong.value.doubled
        var size = self.content.getSize(with: maxWidth)
        size.width = maxWidth
        
        if size.height < MessageContentView.bubbleHeight {
            size.height = MessageContentView.bubbleHeight
        }

        self.preferredContentSize = size
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.layoutNow()
        
        guard let window = UIWindow.topWindow() else { return }
        window.bringSubviewToFront(self.redview)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.content.expandToSuperviewSize()
        
        if let superview = self.content.superview?.superview {
            logDebug("SUPERVIEW: \(superview.bounds.debugDescription)")
            logDebug("CONTENT: \(self.content.bounds.debugDescription)")

        }
        
        self.redview.squaredSize = 100
        self.redview.match(.bottom, to: .top, of: self.content)
        self.redview.centerOnX()
    }
}
