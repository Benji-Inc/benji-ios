//
//  FileManager+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension FileManager {
    static func clearTmpDirectory() {
        do {
            let tmpDirURL = FileManager.default.temporaryDirectory
            let tmpDirectory = try FileManager.default.contentsOfDirectory(atPath: tmpDirURL.path)
            try tmpDirectory.forEach { file in
                let fileUrl = tmpDirURL.appendingPathComponent(file)
                try FileManager.default.removeItem(atPath: fileUrl.path)
            }
        } catch {
           //catch the error somehow
        }
    }
}

