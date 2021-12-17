//
//  WaitlistViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/17/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import StoreKit
import ParseLiveQuery
import Combine
import Localization

class WaitlistViewController: ViewController, Sizeable {

    enum State {
        case initial
        case onWaitlist(QuePositions)
        case upgrade
    }

    private let positionLabel = ThemeLabel(font: .small)
    private let remainingLabel = ThemeLabel(font: .display)

    private let queQuery = QuePositions.query()

    @Published var state: State = .initial

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

        self.$state.mainSink { [unowned self] state in
            self.update(for: state)
        }.store(in: &self.cancellables)

        Task {
            let user = try? await User.getObject(with: User.current()?.objectId ?? "")

            if let status = user?.status {
                switch status {
                case .active, .inactive:
                    self.state = .upgrade
                case .waitlist:
                    if let que = try? await QuePositions.getFirstObject() {
                        self.state = .onWaitlist(que)
                    }
                    self.subscribeToUpdates()
                case .needsVerification:
                    break
                }
            }
        }.add(to: self.taskPool)
    }

    private func subscribeToUpdates() {
        UserStore.shared.$userUpdated
            .filter({ user in
                return user?.isCurrentUser ?? false
            }).mainSink { [unowned self] user in
                guard let u = user else { return }
                if u.status == .inactive || u.status == .active {
                    self.state = .upgrade
                }
        }.store(in: &self.cancellables)

        if let query = self.queQuery {
            let subscription = Client.shared.subscribe(query)

            subscription.handleEvent { [unowned self] query, event in
                switch event {
                case .entered(let u), .updated(let u):
                    guard let que = u as? QuePositions else { return }
                    self.state = .onWaitlist(que)
                default:
                    break
                }
            }
        }
    }

    private func update(for state: State) {
        switch state {
        case .initial:
            break
        case .onWaitlist(let que):
            self.loadWaitlist(for: que)
        case .upgrade:
            self.loadUpgrade()
        }
    }

    private func loadWaitlist(for que: QuePositions) {
        guard let current = User.current(), current.status != .active else { return }

        if let position = current.quePosition {

            let positionString = LocalizedString(id: "", arguments: [String(position)], default: "Currently on #@(position)")
            self.positionLabel.setText(positionString)

            let remaining = (position + que.claimed) - que.max

            self.remainingLabel.setText("#\(String(remaining))")
            self.view.layoutNow()
        }
    }

    private func loadUpgrade() {
        self.remainingLabel.setText("")
#if !NOTIFICATION
        self.displayAppUpdateOverlay()
#endif
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.remainingLabel.setSize(withWidth: self.view.width * 0.8)
        self.remainingLabel.centerOnX()
        self.remainingLabel.centerY = self.view.halfHeight

        self.positionLabel.setSize(withWidth: self.view.width)
        self.positionLabel.match(.top, to: .bottom, of: self.remainingLabel, offset: .xtraLong)
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
