//
//  NotificationObservable.swift
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

extension NSObject: NotificationObservable {}

protocol Notification {
    init?()
}

extension Notification {

    static func materialize(object object: AnyObject? = nil) -> NSNotification {
        return NSNotification(self, object: object)
    }

    func materialize(object object: AnyObject? = nil) -> NSNotification {
        return NSNotification(self, object: object)
    }

}

protocol UserInfoTransformableNotification: Notification {

    var userInfo: [NSObject : AnyObject]? { get }
    init?(userInfo: [NSObject : AnyObject]?)

}

extension UserInfoTransformableNotification {

    init?() {
        return nil
    }

    static func materialize(object object: AnyObject? = nil) -> NSNotification {
        return NSNotification(self, object: object)
    }

    func materialize(object object: AnyObject? = nil) -> NSNotification {
        return NSNotification(self, object: object)
    }

}

private extension NSNotification {

    convenience init<T: Any where T: Notification>(_ notification: T.Type, object: AnyObject? = nil) {
        self.init(name: String(notification), object: object)
    }

    convenience init<T: Any where T: Notification>(_ notification: T, object: AnyObject? = nil) {
        self.init(name: String(notification.dynamicType), object: object)
    }

}

private extension NSNotification {

    convenience init<T: Any where T: UserInfoTransformableNotification>(_ notification: T.Type, object: AnyObject? = nil) {
        self.init(name: String(notification), object: object)
    }

    convenience init<T: Any where T: UserInfoTransformableNotification>(_ notification: T, object: AnyObject? = nil) {
        self.init(name: String(notification.dynamicType), object: object, userInfo: notification.userInfo)
    }

}

extension NSNotificationCenter {

    func postNotification<T: Any where T: Notification>(notification: T, object: AnyObject? = nil) {
        postNotificationName(String(notification.dynamicType), object: object)
    }

    func postNotification<T: Any where T: UserInfoTransformableNotification>(notification: T, object: AnyObject? = nil) {
        postNotificationName(String(notification.dynamicType), object: object, userInfo: notification.userInfo)
    }

}

typealias NotificationPosted = (observer: NotificationObserver, notification: NSNotification) -> Void

private struct Key {
    static var observers = 0
}

protocol NotificationObservable: AnyObject, ObjectAssociable {}

extension NotificationObservable {

    private var observers: NotificationObservers? {
        get {
            return getAssociatedObject(key: &Key.observers)
        }
        set {
            setAssociatedObject(key: &Key.observers, value: newValue)
        }
    }

    func observeNotification<T: Any where T: Notification>(ofObject object: AnyObject? = nil, closure: (observer: NotificationObserver, object: AnyObject?, notification: T?) -> Void) -> NotificationObserver {
        if observers == nil {
            observers = NotificationObservers(observable: self)
        }
        return observers!.addObserver(name: String(T), ofObject: object, closure: closure)
    }

    func observeNotification<T: Any where T: UserInfoTransformableNotification>(ofObject object: AnyObject? = nil, closure: (observer: NotificationObserver, object: AnyObject?, notification: T?) -> Void) -> NotificationObserver {
        if observers == nil {
            observers = NotificationObservers(observable: self)
        }
        return observers!.addObserver(name: String(T), ofObject: object, closure: closure)
    }

    func observeNotification(name name: String?, ofObject object: AnyObject? = nil, closure: NotificationPosted) -> NotificationObserver {
        if observers == nil {
            observers = NotificationObservers(observable: self)
        }
        return observers!.addObserver(name: name, ofObject: object, closure: closure)
    }

    func stopObservingNotifications(ofObject object: AnyObject) {
        observers?.removeObservers(ofObject: object)
    }

    func stopObservingNotifications() {
        observers = nil
    }

}

class NotificationObserver {

    private weak var observers: NotificationObservers!

    private init(observers: NotificationObservers) {
        self.observers = observers
    }

    func remove() {
        observers.removeObserver(self)
    }

}

private class NotificationObservers {

    class Observer: NotificationObserver {

        private weak var object: AnyObject?
        private let closure: NotificationPosted

        init(observers: NotificationObservers, object: AnyObject?, closure: NotificationPosted) {
            self.object = object
            self.closure = closure
            super.init(observers: observers)
        }

        @objc func observe(notification: NSNotification) {
            closure(observer: self, notification: notification)
        }

    }

    private weak var observable: NotificationObservable!

    private var observers = [Observer]()

    private lazy var notificationCenter = NSNotificationCenter.defaultCenter()

    init(observable: NotificationObservable) {
        self.observable = observable
    }

    deinit {
        observers.forEach { removeObserver($0) }
    }

    func addObserver<T: Any where T: Notification>(name name: String?, ofObject object: AnyObject?, closure: (observer: NotificationObserver, object: AnyObject?, notification: T?) -> Void) -> NotificationObserver {
        return addObserver(name: name, ofObject: object) {
            observer, notification in
            closure(observer: observer, object: notification.object, notification: T())
        }
    }

    func addObserver<T: Any where T: UserInfoTransformableNotification>(name name: String?, ofObject object: AnyObject?, closure: (observer: NotificationObserver, object: AnyObject?, notification: T?) -> Void) -> NotificationObserver {
        return addObserver(name: name, ofObject: object) {
            observer, notification in
            closure(observer: observer, object: notification.object, notification: T(userInfo: notification.userInfo))
        }
    }

    func addObserver(name name: String?, ofObject object: AnyObject?, closure: NotificationPosted) -> NotificationObserver {
        let observer = Observer(observers: self, object: object, closure: closure)
        observers.append(observer)
        let selector = #selector(Observer.observe)
        notificationCenter.addObserver(observer, selector: selector, name: name, object: object)
        return observer
    }

    func removeObserver(observer: NotificationObserver) {
        if let index = observers.indexOf({ $0 === observer }) {
            let observer = observers.removeAtIndex(index)
            notificationCenter.removeObserver(observer)
            if let observable = observable where observers.isEmpty {
                observable.observers = nil
            }
        }
    }

    func removeObservers(ofObject object: AnyObject) {
        observers.filter({ $0.object === object }).forEach { removeObserver($0) }
    }

}
