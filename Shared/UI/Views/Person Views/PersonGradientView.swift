//
//  PersonGradientView.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PersonGradientView: DisplayableImageView {
    
    private let emotionGradientView = EmotionGradientView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.insertSubview(self.emotionGradientView, at: 0)

        self.set(emotionCounts: [:])
        self.subscribeToUpdates()
    }
    
    func getSize(forHeight height: CGFloat) -> CGSize {
        return CGSize(width: height, height: height)
    }

    func setSize(forHeight height: CGFloat) {
        self.size = self.getSize(forHeight: height)
    }
    
    // MARK: - Open setters
    
    func set(expression: Expression?, defaultColors: [ThemeColor] = [.B0, .B6]) {
        
        if let expression = expression, let expressionURL = expression.imageURL {
            self.set(displayable: expressionURL)
            self.set(emotionCounts: expression.emotionCounts)
        } else {
            self.set(displayable: User.current()!)
            self.set(emotionCounts: expression?.emotionCounts ?? [:])
        }
    }

    func set(displayable: ImageDisplayable?) {
        self.displayable = displayable
    }
    
    func set(emotionCounts: [Emotion: Int], defaultColors: [ThemeColor] = [.B0, .B6]) {
        self.emotionGradientView.defaultColors = defaultColors
        let last = self.emotionGradientView.set(emotionCounts: emotionCounts).last
                
        self.layer.borderWidth = 2
        self.layer.borderColor = last?.withAlphaComponent(0.9).cgColor
        self.layer.masksToBounds = true
        
        self.setNeedsLayout()
    }
    
    // MARK: - Subscriptions

    /// Called when the currently assigned person receives an update to their state.
    func didRecieveUpdateFor(person: PersonType) {
        self.displayable = person
    }

    private func subscribeToUpdates() {
        PeopleStore.shared.$personUpdated
            .filter { [unowned self] updatedPerson in
                // Only handle person updates related to the currently assigned person.
                if let person = self.displayable as? PersonType {
                    return person.personId == updatedPerson?.personId
                } else {
                    return false
                }
            }.mainSink { [unowned self] updatedPerson in
                guard let updatedPerson = updatedPerson else { return }
                self.didRecieveUpdateFor(person: updatedPerson)
            }.store(in: &self.cancellables)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.emotionGradientView.expandToSuperviewSize()
        
        self.makeRound()
    }
}
