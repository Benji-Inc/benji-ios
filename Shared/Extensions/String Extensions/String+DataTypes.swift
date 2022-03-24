//
//  String+DataTypes.swift
//  Jibber
//
//  Created by Martin Young on 3/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension String {

    /// Returns all of the data in the string that is matches one of the passed in checking types.
    /// If no type is specified then all types are checked.
    func getDataTypes(with checkingTypes: NSTextCheckingTypes = NSTextCheckingAllTypes) -> [NSTextCheckingResult] {
        guard let detector = try? NSDataDetector(types: checkingTypes) else { return [] }

        let range = NSRange(self.startIndex..<self.endIndex, in: self)

        var results: [NSTextCheckingResult] = []
        detector.enumerateMatches(in: self,
                                  options: [],
                                  range: range) { (match, flags, _) in
            guard let match = match else { return }

            results.append(match)
        }

        return results
    }

    /// Returns all the URLs found in the string.
    func getURLs() -> [URL] {
        let results = self.getDataTypes(with: NSTextCheckingResult.CheckingType.link.rawValue)
        let urls = results.compactMap { textCheckingResult in
            return textCheckingResult.url
        }

        return urls
    }
}
