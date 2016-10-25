//
//  InterfaceUpdatable.swift
//  Created by Christopher Fuller for Southern California Public Radio
//
//  Copyright (c) 2016 Southern California Public Radio
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit

struct UpdateInterfaceNotification: UserInfoTransformableNotification {

    private struct Key {
        static var animated = "animated"
    }

    private(set) var animated: Bool

    var userInfo: [NSObject : AnyObject]? {
        return [
            Key.animated: animated
        ]
    }

    init?(userInfo: [NSObject : AnyObject]?) {
        guard let animated = userInfo?[Key.animated] as? Bool else {
            return nil
        }
        self.animated = animated
    }

    init(animated: Bool) {
        self.animated = animated
    }

}

protocol UpdateInterfaceNotifiable: AnyObject {

    var notificationQueue: NSNotificationQueue { get }

}

extension UpdateInterfaceNotifiable {

    func updateInterface() {
        notificationQueue.enqueue(
            UpdateInterfaceNotification(animated: false).materialize(object: self),
            postingStyle: .PostNow
        )
    }

    func setNeedsUpdateInterface() {
        notificationQueue.enqueue(
            UpdateInterfaceNotification(animated: true).materialize(object: self),
            postingStyle: .PostASAP
        )
    }

}

protocol InterfaceUpdatable: UpdateInterfaceNotifiable, NotificationObservable {

    func updateInterface(notification: UpdateInterfaceNotification)

}

extension InterfaceUpdatable {

    func observeUpdateInterfaceNotification(ofObject object: AnyObject? = nil) {
        observeNotification(ofObject: (object ?? self)) {
            [ weak self ] (_, _, notification: UpdateInterfaceNotification?) in
            guard let _self = self else { return }
            if let notification = notification {
                let applicationState = UIApplication.sharedApplication().applicationState
                if !notification.animated || (applicationState != .Background) {
                    _self.updateInterface(notification)
                }
            }
        }
    }

    func updateInterfaceWhenApplicationWillEnterForeground() {
        observeNotification(name: UIApplicationWillEnterForegroundNotification) {
            [ weak self ] _, _ in
            guard let _self = self else { return }
            _self.updateInterface()
        }
    }

}
