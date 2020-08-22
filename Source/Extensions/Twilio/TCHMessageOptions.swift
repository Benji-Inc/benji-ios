//
//  TCHMessageOptions.swift
//  Benji
//
//  Created by Benji Dodgson on 8/22/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import TMROFutures

extension TCHMessageOptions {

    func with(body: String, attributes: TCHJsonAttributes) -> Future<TCHMessageOptions> {
        let promise = Promise<TCHMessageOptions>()

        self.withBody(body)
        self.withAttributes(attributes) { (result) in
            if result.isSuccessful() {
                promise.resolve(with: self)
            } else if let error = result.error {
                promise.reject(with: error)
            } else {
                promise.reject(with: ClientError.message(detail: "Failed to create options for message."))
            }
        }

        return promise
    }

    func with(mediaItem: MediaItem) -> Future<TCHMessageOptions> {

        let promise = Promise<TCHMessageOptions>()

        let inputStream = InputStream(data: mediaItem.data)
        let options = TCHMessageOptions()
        options.withMediaStream(inputStream,
                                contentType: mediaItem.type.rawValue,
                                defaultFilename: mediaItem.fileName,
                                onStarted: {
                                    // Handle started
        },
                                onProgress: { (progress) in
                                    // Handle progress
        }) { (completed) in
            // Handle completion
        }

        return promise

    }

    //    // The data for the image you would like to send
    //    let data = Data()
    //
    //    // Prepare the upload stream and parameters
    //
    //    let inputStream = InputStream(data: data)
    //    messageOptions.withMediaStream(inputStream,
    //                                   contentType: "image/jpeg",
    //                                   defaultFilename: "image.jpg",
    //                                   onStarted: {
    //                                    // Called when upload of media begins.
    //                                    print("Media upload started")
    //    },
    //                                   onProgress: { (bytes) in
    //                                    // Called as upload progresses, with the current byte count.
    //                                    print("Media upload progress: \(bytes)")
    //    }) { (mediaSid) in
    //        // Called when upload is completed, with the new mediaSid if successful.
    //        // Full failure details will be provided through sendMessage's completion.
    //        print("Media upload completed")
    //    }
}
