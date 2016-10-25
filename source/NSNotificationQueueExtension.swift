//
//  NSNotificationQueueExtension.swift
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

import Foundation

extension NSNotificationQueue: ClosureExecutable {

    func enqueue(notification: NSNotification, postingStyle: NSPostingStyle, coalesceMask: NSNotificationCoalescing? = nil) {
        execute(main: true) {
            $0.enqueueNotification(
                notification,
                postingStyle: postingStyle,
                coalesceMask: (coalesceMask ?? [ .CoalescingOnName, .CoalescingOnSender ]),
                forModes: nil
            )
        }
    }

    func dequeue(notification: NSNotification, coalesceMask: NSNotificationCoalescing? = nil) {
        execute(main: true) {
            $0.dequeueNotificationsMatching(
                notification,
                coalesceMask: Int((coalesceMask ?? [ .CoalescingOnName, .CoalescingOnSender ]).rawValue)
            )
        }
    }

}
