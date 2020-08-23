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

    func with(mediaItem: MediaItem, attributes: TCHJsonAttributes) -> Future<TCHMessageOptions> {

        let promise = Promise<TCHMessageOptions>()

        self.withAttributes(attributes) { (result) in
            if result.isSuccessful() {
                self.with(mediaItem: mediaItem)
                    .observeValue { (options) in
                        promise.resolve(with: options)
                }
            } else if let error = result.error {
                promise.reject(with: error)
            } else {
                promise.reject(with: ClientError.message(detail: "Failed to create options for message."))
            }
        }

        return promise
    }

    private func with(mediaItem: MediaItem) -> Future<TCHMessageOptions> {
        let promise = Promise<TCHMessageOptions>()

        let inputStream = InputStream(data: mediaItem.data)
        self.withMediaStream(inputStream,
                             contentType: mediaItem.type.rawValue,
                             defaultFilename: mediaItem.fileName,
                             onStarted: {
                                // Handle started
                                print("Media upload started")
                                promise.resolve(with: self)
        },
                             onProgress: { (progress) in
                                // Handle progress
                                print("Media upload progress: \(progress)")
                                promise.resolve(with: self)
        }) { (mediaSid) in
            // Handle completion
            print("Media upload completed: \(mediaSid)")
            promise.resolve(with: self)
        }

        return promise
    }
}
