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

    func with(body: String, mediaItem: MediaItem? = nil, attributes: TCHJsonAttributes) async -> TCHMessageOptions {
        if mediaItem.isNil {
            self.withBody(body)
        }

        // Twilio fails to call completion for this function.
        self.withAttributes(attributes)

        if let item = mediaItem {
            await self.with(mediaItem: item)
        }

        return self
    }

    private func with(mediaItem: MediaItem) async {
        guard let data = mediaItem.data else { return }

        let inputStream = InputStream(data: data)
        return await withCheckedContinuation { continuation in
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
                continuation.resume(returning: ())
            }
        }
    }
}
