//
//  InviteCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 2/1/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts
import MessageUI
import Branch
import TMROLocalization
import TMROFutures

// Creating a delegate object for the message composer because MFMessageComposeViewControllerDelegate
// must conform to NSObjectProtocol and I don't want to force coordinators to be NSObjects.
private class MessageComposerDelegate: NSObject, MFMessageComposeViewControllerDelegate {

    var onComposerDidFinish: (MessageComposeResult, MFMessageComposeViewController) -> Void

    init(onComposerDidFinish: @escaping (MessageComposeResult, MFMessageComposeViewController) -> Void) {
        self.onComposerDidFinish = onComposerDidFinish
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        self.onComposerDidFinish(result, controller)
    }
}

class InviteComposerCoordinator: Coordinator<Void> {

    let source: ViewController
    let contacts: [CNContact]
    private var currentIndex: Int = 0

    private lazy var composerDelegate = MessageComposerDelegate { [unowned self] (result, controller) in
        self.handleMessageComposer(result: result, controller: controller)
    }

    init(router: Router,
         deeplink: DeepLinkable?,
         contacts: [CNContact],
         source: ViewController) {

        self.contacts = contacts
        self.source = source

        super.init(router: router, deepLink: deeplink)
    }

    override func start() {
        super.start()

        if let contact = self.contacts.first {
            self.presentMessageComposer(with: contact)
        }
    }

    private func presentMessageComposer(with contact: CNContact) {
        // The message composer won't initialize properly if texts aren't enabled on the device
        guard MessageComposerViewController.canSendText(), let phoneNumber = contact.primaryPhoneNumber else { return }

        let vc = MessageComposerViewController()

        self.createInvite(with: phoneNumber)
            .ignoreUserInteractionEventsUntilDone(for: self.source.view)
            .observe(with: { (result) in
                switch result {
                case .success(let message):
                    runMain {
                        vc.body = message
                        vc.recipients = [phoneNumber]
                        vc.messageComposeDelegate = self.composerDelegate
                        self.router.present(vc, source: self.source)
                    }
                case .failure(_):
                    self.finishFlow(with: ())
                }
            })
    }

    private func createInvite(with phoneNumber: String) -> Future<String> {
        self.createLink(with: phoneNumber).then { (link) in
            let promise = Promise<String>()
            let message = LocalizedString(id: "",
                                          arguments: [link],
                                          default: "Because you mean a lot to me, I saved you a spot on this app that will help us communicate better. Claim it here: @(link)")
            promise.resolve(with: localized(message))
            return promise
        }
    }

    private func createLink(with phoneNumber: String) -> Future<String> {
        CreateConnection(phoneNumber: phoneNumber).makeRequest()
            .transform { (connection) -> String in
                let canonicalIdentifier = UUID().uuidString
                let buo = BranchUniversalObject(canonicalIdentifier: canonicalIdentifier)
                buo.title = localized(LocalizedString(id: "", default: "Benji"))
                buo.contentDescription = localized(LocalizedString(id: "", default: "Private message"))
                buo.contentMetadata.customMetadata["connection_id"] = connection.objectId
                let properties = BranchLinkProperties()
                properties.channel = "iOS"
                return buo.getShortUrl(with: properties)!
        } 
    }

    func handleMessageComposer(result: MessageComposeResult, controller: MFMessageComposeViewController) {

         switch result {
         case .cancelled:
             break
         case .failed:
             break
         case .sent:
            break 
         @unknown default:
             break
         }

         self.router.dismiss(source: controller, animated: true) {

            self.currentIndex += 1
            if let contact = self.contacts[safe: self.currentIndex] {
                self.presentMessageComposer(with: contact)
            } else {
                self.finishFlow(with: ())
            }
         }
     }
}
