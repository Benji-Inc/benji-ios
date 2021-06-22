//
//  WaitlistViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/17/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROLocalization
import StoreKit
import ParseLiveQuery
import Combine

class WaitlistViewController: ViewController, Sizeable {

    let positionLabel = Label(font: .small)
    let remainingLabel = Label(font: .display)

    @Published var didShowUpgrade: Bool = false

#if APPCLIP
    private let userQuery = User.query()
#endif

    private let queQuery = QuePostions.query()

    lazy var skOverlay: SKOverlay = {
        let config = SKOverlay.AppClipConfiguration(position: .bottom)
        let overlay = SKOverlay(configuration: config)
        overlay.delegate = self
        return overlay
    }()

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.positionLabel)
        self.view.addSubview(self.remainingLabel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        #if APPCLIP
        if let query = self.userQuery, let objectId = User.current()?.objectId {

            query.whereKey("objectId", equalTo: objectId)

            let subscription = Client.shared.subscribe(query)

            subscription.handleEvent { query, event in
                switch event {
                case .entered(let u), .left(let u), .created(let u), .updated(let u), .deleted(let u):
                    guard let user = u as? User else { return }
                    if user.status == .inactive || user.status == .active {
                        self.loadUpgrade()
                    }
                }
            }
        }

        #endif

        if let query = self.queQuery {
            let subscription = Client.shared.subscribe(query)

            subscription.handleEvent { query, event in
                switch event {
                case .entered(let u):
                    guard let que = u as? QuePostions else { return }
                    self.loadWaitlist(for: que)
                case .updated(let u):
                    guard let que = u as? QuePostions else { return }
                    self.loadWaitlist(for: que)
                default: 
                    break
                }
            }
        }
    }

    private func loadWaitlist(for que: QuePostions) {
        guard let current = User.current(), current.status != .active else { return }

        if let position = current.quePosition {
            let positionString = LocalizedString(id: "", arguments: [String(position)], default: "Your positon is: @(position)")
            self.positionLabel.setText(positionString)

            let remaining = (position + que.claimed) - que.max

            self.remainingLabel.setText(String(remaining))
            self.view.layoutNow()
        }
    }

    private func loadUpgrade() {
        self.remainingLabel.setText("You're in!")
        #if !NOTIFICATION
        self.displayAppUpdateOverlay()
        #endif
        self.didShowUpgrade = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.remainingLabel.setSize(withWidth: self.view.width * 0.8)
        self.remainingLabel.centerOnX()
        self.remainingLabel.bottom = self.view.halfHeight * 0.8

        self.positionLabel.setSize(withWidth: self.view.width)
        self.positionLabel.match(.top, to: .bottom, of: self.remainingLabel, offset: 20)
        self.positionLabel.centerOnX()
    }
}

extension WaitlistViewController: SKOverlayDelegate {

    #if !NOTIFICATION
    func displayAppUpdateOverlay() {
        guard let window = UIWindow.topWindow(), let scene = window.windowScene else { return }

        self.skOverlay.present(in: scene)
    }
    #endif

    func storeOverlayWillStartPresentation(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
    }

    func storeOverlayWillStartDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
    }
}
