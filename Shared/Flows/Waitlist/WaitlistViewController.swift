//
//  WaitlistViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import ParseLiveQuery

class WaitlistViewController: ViewController {
    
    override var analyticsIdentifier: String? {
        return "SCREEN_WAITLIST"
    }
    
    let personView = BorderedPersonView()
    let titleLabel = ThemeLabel(font: .display)
    let descriptionLabel = ThemeLabel(font: .regular)
    
    override func initializeViews() {
        super.initializeViews()
                
        self.view.set(backgroundColor: .B0)
        
        self.view.addSubview(self.personView)
        self.personView.isVisible = false
        self.view.addSubview(self.titleLabel)
        self.titleLabel.textAlignment = .center
        self.view.addSubview(self.descriptionLabel)
        self.descriptionLabel.textAlignment = .center
        
        PeopleStore.shared.$personUpdated.filter({ type in
            return type?.isCurrentUser ?? false
        }).mainSink { type in
            self.updateUI()
        }.store(in: &self.cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateUI()
    }
    
    /// The currently running task that is loading conversations.
    private var loadTask: Task<Void, Never>?
    
    private func updateUI() {
        self.loadTask?.cancel()
        
        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            guard let user = try? await User.current()?.retrieveDataIfNeeded() else { return }
            
            switch user.status {
            case .active:
                self.titleLabel.setText("Congrats! 🥳")
                self.descriptionLabel.setText("You now have access to join Jibber!")
                self.displayOverlay()
            case .waitlist:
                if let position = user.quePosition {
                    self.titleLabel.setText("You're #\(position) on the list!")
                    self.descriptionLabel.setText("We will notify you when you are available to join.")
                }
                
            default:
                break
            }
            
            self.view.setNeedsLayout()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.titleLabel.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.titleLabel.centerY = self.view.height * 0.45
        self.titleLabel.centerOnX()
        
        self.descriptionLabel.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.descriptionLabel.match(.top, to: .bottom, of: self.titleLabel, offset: .long)
        self.descriptionLabel.centerOnX()
        
        self.personView.squaredSize = 100
        self.personView.centerOnX()
        self.personView.match(.bottom, to: .top, of: self.titleLabel, offset: .negative(.screenPadding))
    }
    
    func displayOverlay() {
        guard let scene = view.window?.windowScene else { return }

        let config = SKOverlay.AppClipConfiguration(position: .bottom)
        let overlay = SKOverlay(configuration: config)
        overlay.present(in: scene)
    }
}

extension WaitlistViewController: TransitionableViewController {

    var presentationType: TransitionType {
        return .fadeOutIn
    }

    var dismissalType: TransitionType {
        return self.presentationType
    }

    func getFromVCPresentationType(for toVCPresentationType: TransitionType) -> TransitionType {
        return toVCPresentationType
    }

    func getToVCDismissalType(for fromVCDismissalType: TransitionType) -> TransitionType {
        return fromVCDismissalType
    }
}
