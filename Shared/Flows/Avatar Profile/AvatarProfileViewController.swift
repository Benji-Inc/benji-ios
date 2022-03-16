//
//  UserProfileViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class AvatarProfileViewController: ViewController {

    private let personView = BorderedPersonView()
    private let nameLabel = ThemeLabel(font: .mediumBold)
    private let focusLabel = ThemeLabel(font: .regular)
    private let vibrancyView = VibrancyView()

    private let person: PersonType

    init(with person: PersonType) {
        self.person = person
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .clear)
        self.view.addSubview(self.vibrancyView)
        self.view.addSubview(self.personView)
        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.focusLabel)

        let objectId = self.person.personId
        Task { [weak self] in
            guard let person = await PeopleStore.shared.getPerson(withPersonId: objectId) else { return }
            self?.nameLabel.setText(person.fullName)
            self?.focusLabel.setText(person.focusStatus?.rawValue)
            self?.view.setNeedsLayout()
        }

        self.personView.set(person: self.person)

        self.preferredContentSize = CGSize(width: 300, height: 300)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.vibrancyView.expandToSuperviewSize()

        self.personView.setSize(for: 120)
        self.personView.pinToSafeAreaTop()
        self.personView.centerOnX()

        let maxWidth = Theme.getPaddedWidth(with: self.view.width)

        self.nameLabel.setSize(withWidth: maxWidth)
        self.nameLabel.centerOnX()
        self.nameLabel.match(.top, to: .bottom, of: self.personView, offset: .standard)
        
        self.focusLabel.setSize(withWidth: maxWidth)
        self.focusLabel.centerOnX()
        self.focusLabel.match(.top, to: .bottom, of: self.nameLabel, offset: .standard)
    }
}
