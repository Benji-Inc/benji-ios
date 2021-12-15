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

extension CNContact: Avatar {

    var handle: String {
        return ""
    }

    var userObjectId: String? {
        return nil
    }

    var image: UIImage? {
        if let data = self.thumbnailImageData {
            return UIImage(data: data)
        }

        return nil 
    }
}

