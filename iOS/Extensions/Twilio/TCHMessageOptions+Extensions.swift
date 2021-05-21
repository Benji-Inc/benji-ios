//
//  TCHMessageOptions.swift
//  Benji
//
//  Created by Benji Dodgson on 8/22/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Combine

extension TCHMessageOptions {

    func with(body: String, mediaItem: MediaItem? = nil, attributes: TCHJsonAttributes) -> Future<TCHMessageOptions, Error> {
        return Future { promise in
            if mediaItem.isNil {
                self.withBody(body)
            }

            // Twilio fails to call completion for this function.
            self.withAttributes(attributes, completion: nil)

            if let item = mediaItem {
                self.with(mediaItem: item)
            }
            promise(.success(self))
        }
    }

    private func with(mediaItem: MediaItem) {
        guard let data = mediaItem.data else { return }

        let inputStream = InputStream(data: data)
        self.withMediaStream(inputStream,
                             contentType: mediaItem.type.rawValue,
                             defaultFilename: mediaItem.fileName,
                             onStarted: {
                                // Handle started
                                print("Media upload started")
        },
                             onProgress: { (bytes) in
                                // Handle progress
                                print("Media upload progress: \(bytes)")
        }) { (mediaSid) in
            // Handle completion
            print("Media upload completed: \(mediaSid)")
        }
    }
}
