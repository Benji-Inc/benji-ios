//
//  CNContact+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/2/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts

extension CNContact {

    var fullName: String? {
        return self.givenName + " " + self.familyName
    }

    /// Returns the best phone number for this contact as a string with only numberic characters.
    func findBestPhoneNumberString() -> String? {
        guard let phoneNumber = self.findBestPhoneNumber().phone else { return nil }

        let stringPhoneNumber = phoneNumber.stringValue.removeAllNonNumbers()
        return stringPhoneNumber
    }

    func findBestPhoneNumber() -> (phone: CNPhoneNumber?, label: String?) {
        var bestPair: (CNPhoneNumber?, String?) = (nil, nil)
        let prioritizedLabels = ["iPhone",
                                 "_$!<Mobile>!$_",
                                 "_$!<Main>!$_",
                                 "_$!<Home>!$_",
                                 "_$!<Work>!$_"]

        // Look for a number with a priority label first
        for label in prioritizedLabels {
            for entry: CNLabeledValue in self.phoneNumbers {
                if entry.label == label {
                    let readableLabel = self.readable(label)
                    bestPair = (entry.value, readableLabel)
                    break
                }
            }
        }

        // Then look to see if there are any numbers with custom labels if we
        // didn't find a priority label
        if bestPair.0 == nil || bestPair.1 == nil {
            let lowPriority = self.phoneNumbers.filter { entry in
                if let label = entry.label {
                    return !prioritizedLabels.contains(label)
                } else {
                    return false
                }
            }

            if let entry = lowPriority.first, let label = entry.label {
                let readableLabel = self.readable(label)
                bestPair = (entry.value, readableLabel)
            }
        }

        if bestPair.0.isNil {
            bestPair = (self.phoneNumbers.first?.value, nil)
        }

        return bestPair
    }

    func readable(_ label: String) -> String {
        let cleanLabel: String

        switch label {
        case _ where label == "iPhone":         cleanLabel = "iPhone"
        case _ where label == "_$!<Mobile>!$_": cleanLabel = "Mobile"
        case _ where label == "_$!<Main>!$_":   cleanLabel = "Main"
        case _ where label == "_$!<Home>!$_":   cleanLabel = "Home"
        case _ where label == "_$!<Work>!$_":   cleanLabel = "Work"
        default:                                cleanLabel = label
        }

        return cleanLabel
    }
}

extension CNContact: PersonType {

    var personId: String {
        return self.identifier
    }

    var handle: String {
        return ""
    }

    var focusStatus: FocusStatus? {
        return nil
    }

    var image: UIImage? {
        return self.imageWith(text: self.initials)
    }

    /// Returns an image with the provided text baked into it.
    private func imageWith(text: String) -> UIImage? {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        label.text = text

        // Set the font size to something large so it will assured to be shrunk down to fit the label.
        label.font = FontType.regularBold.font.withSize(100)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center

        // Make the image small, but make sure the resolution is high enough so it doens't look bad
        // in a thumbnail.
        let contextSize = CGSize(width: 50, height: 50)
        UIGraphicsBeginImageContext(contextSize)
        defer { UIGraphicsEndImageContext() }

        let currentContext = UIGraphicsGetCurrentContext()!
        // Center the text and render it.
        currentContext.translateBy(x: (contextSize.width - label.width)/2 ,
                                   y: (contextSize.height - label.height)/2);
        label.layer.render(in: currentContext)

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
