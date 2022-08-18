//
//  String+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import PhoneNumberKit
import UIKit

extension String {

    init(optional value: String?) {
        if let strongValue = value {
            self.init(stringLiteral: strongValue)
        } else {
            self.init()
        }
    }
    
    func height(withConstrainedWidth width: CGFloat, fontType: FontType) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font : fontType.font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, fontType: FontType) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font : fontType.font], context: nil)

        return ceil(boundingBox.width)
    }

    // Gets an NSAttributedString compatible ranges for all the emojis in a string
    // NSAttributedStrings are encoded using UTF16, and emojis may consist of multiple code units
    // https://developer.apple.com/swift/blog/?id=30
    func getEmojiRanges() -> [NSRange] {

        var ranges: [NSRange] = []

        for (index, character) in self.enumerated() {
            guard character.isEmoji else { continue }
            let characterIndex = self.index(self.startIndex, offsetBy: index)
            let nsRange = NSRange(characterIndex...characterIndex, in: self)
            ranges.append(nsRange)
        }

        return ranges
    }

    func substring(with nsrange: NSRange) -> Substring? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return self[range]
    }

    func extraWhitespaceRemoved() -> String {
        return components(separatedBy: CharacterSet.whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimWhitespace()
    }

    func trimWhitespace() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isValidGivenName: Bool {
        let components: [String] = self.extraWhitespaceRemoved()
            .components(separatedBy: CharacterSet.whitespaces)

        if components.all(test: { (element: String) -> Bool in return !element.isEmpty }) {
            return components.first?.count ?? 0 > 1
        }

        return false
    }

    var isValidFullName: Bool {
        let components: [String] = self.extraWhitespaceRemoved()
            .components(separatedBy: CharacterSet.whitespaces)

        if components.count > 1 && components.all(test: { (element: String) -> Bool in return !element.isEmpty }) {
            return components.first?.count ?? 0 > 1
                && components.last?.count ?? 0 > 1
        }

        return false
    }

    var wordCount: Int {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        let words = components.filter { word in !word.isEmpty }
        return words.count
    }
}

extension StringProtocol {
    func nsRange(from range: Range<Index>) -> NSRange {
        return .init(range, in: self)
    }
}

extension Range where Bound == String.Index {
    func nsRange(_ string: String) -> NSRange {
        return NSRange(location: self.lowerBound.utf16Offset(in: string),
                       length: self.upperBound.utf16Offset(in: string) - self.lowerBound.utf16Offset(in: string))
    }
}

extension NSString {

    func getRangesOfSubstringsSeparatedBySpaces() -> [NSRange] {
        var substringRanges: [NSRange] = []

        let fullRange = NSRange(location: 0, length: self.length)
        var location: Int?
        self.enumerateSubstrings(in: fullRange, options: .byComposedCharacterSequences)
        { (substring, substringRange, _, _) in

            if substring == " " {
                if let location = location {
                    substringRanges.append(NSRange(location: location,
                                                   length: substringRange.location - location))
                }

                location = nil
            } else {
                if location.isNil {
                    location = substringRange.location
                }
            }
        }

        if let location = location {
            substringRanges.append(NSRange(location: location, length: self.length - location))
        }

        return substringRanges
    }
}
