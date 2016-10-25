//
//  NetworkReachability.swift
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
import SystemConfiguration

class NetworkReachability {

    // MARK: - Public Properties:

    // MARK: CONSTANT

    // MARK: LAZY

    lazy var notificationQueue: NSNotificationQueue = {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        return NSNotificationQueue(notificationCenter: notificationCenter)
    }()

    // MARK: OUTLET

    // MARK: STORED

    // MARK: READONLY

    private(set) var networkStatus: NetworkStatus = .Unknown {
        didSet {
            if networkStatus != oldValue {
                notificationQueue.dequeue(
                    NetworkStatusDidChangeNotification.materialize(object: self)
                )
                notificationQueue.enqueue(
                    NetworkStatusDidChangeNotification(networkStatus: networkStatus).materialize(object: self),
                    postingStyle: .PostASAP
                )
            }
        }
    }

    // MARK: COMPUTED

    var isNotifying: Bool {
        return (networkReachability != nil)
    }

    // MARK: - Private Properties:

    // MARK: CONSTANT

    private let queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)

    // MARK: LAZY

    // MARK: STORED

    private var networkReachability: SCNetworkReachabilityRef?

    // MARK: COMPUTED

    // MARK: - Initialization Methods:

    private init() {}

    deinit {
        stopNotifying()
    }

}

// MARK:

extension NetworkReachability {

    // MARK: - Public Type Properties:

    // MARK: CONSTANT

    static let sharedInstance = NetworkReachability()

    // MARK: STORED

    // MARK: READONLY

    // MARK: COMPUTED

    // MARK: - Private Type Properties:

    // MARK: CONSTANT

    // MARK: STORED

    // MARK: COMPUTED

}

// MARK: - Public Types:

extension NetworkReachability {

    // MARK: NetworkStatusDidChangeNotification Structure

    struct NetworkStatusDidChangeNotification: UserInfoTransformableNotification {

        private struct Key {
            static var networkStatus = "setting"
        }

        private(set) var networkStatus: NetworkStatus

        var userInfo: [NSObject : AnyObject]? {
            return [
                Key.networkStatus: networkStatus.rawValue
            ]
        }

        init?(userInfo: [NSObject : AnyObject]?) {
            guard let rawValue = userInfo?[Key.networkStatus] as? UInt else {
                return nil
            }
            guard let networkStatus = NetworkStatus(rawValue: rawValue) else {
                return nil
            }
            self.networkStatus = networkStatus
        }

        init(networkStatus: NetworkStatus) {
            self.networkStatus = networkStatus
        }

    }

    // MARK: Error Enumeration

    enum Error: ErrorType {
        case FailedToStartNotifying
    }

    // MARK: NetworkStatus Enumeration

    enum NetworkStatus: UInt {

        case Unknown
        case NotReachable
        case ReachableViaWiFi
        case ReachableViaWWAN

        var isNotReachable: Bool {
            return (self == .NotReachable)
        }

        var isReachable: Bool {
            return [ .ReachableViaWiFi, .ReachableViaWWAN ].contains(self)
        }

        var isReachableViaWiFi: Bool {
            return (self == .ReachableViaWiFi)
        }

        var isReachableViaWWAN: Bool {
            return (self == .ReachableViaWWAN)
        }

        init(flags: SCNetworkReachabilityFlags) {

            var networkStatus: NetworkStatus = .NotReachable

            if flags.contains(.Reachable) {

                if !flags.contains(.ConnectionRequired) {
                    networkStatus = .ReachableViaWiFi
                }

                if flags.contains(.ConnectionOnDemand) || flags.contains(.ConnectionOnTraffic) {
                    if !flags.contains(.InterventionRequired) {
                        networkStatus = .ReachableViaWiFi
                    }
                }

                if flags.contains(.IsWWAN) {
                    networkStatus = .ReachableViaWWAN
                }

            }

            self = networkStatus

        }

    }

}

// MARK: - Public Instance Methods:

extension NetworkReachability {

    func startNotifying(host host: String) throws {

        stopNotifying()

        guard let target = SCNetworkReachabilityCreateWithName(nil, host) else {
            throw Error.FailedToStartNotifying
        }

        func callout(target: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutablePointer<Void>) {
            let _self = Unmanaged<NetworkReachability>.fromOpaque(COpaquePointer(info)).takeUnretainedValue()
            Dispatch.async {
                [ weak _self ] in
                guard let _self = _self else { return }
                _self.setNetworkStatus(flags)
            }
        }

        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque())

        if !SCNetworkReachabilitySetCallback(target, callout, &context) {
            throw Error.FailedToStartNotifying
        }

        if !SCNetworkReachabilitySetDispatchQueue(target, queue) {
            SCNetworkReachabilitySetCallback(target, nil, nil)
            throw Error.FailedToStartNotifying
        }

        networkReachability = target

        Dispatch.async(queue: queue, delay: 1.0) {
            [ weak self ] in
            guard let _self = self else { return }
            if let target = _self.networkReachability {
                var flags: SCNetworkReachabilityFlags = []
                if SCNetworkReachabilityGetFlags(target, &flags) {
                    Dispatch.async {
                        [ weak self ] in
                        guard let _self = self else { return }
                        if _self.networkStatus == .Unknown {
                            _self.setNetworkStatus(flags)
                        }
                    }
                }
            }
        }

    }

    func stopNotifying() {
        if let target = networkReachability {
            SCNetworkReachabilitySetCallback(target, nil, nil)
            SCNetworkReachabilitySetDispatchQueue(target, nil)
            networkReachability = nil
        }
    }

}

// MARK: - Private Instance Methods:

private extension NetworkReachability {

    func setNetworkStatus(flags: SCNetworkReachabilityFlags) {
        networkStatus = NetworkStatus(flags: flags)
    }

}
