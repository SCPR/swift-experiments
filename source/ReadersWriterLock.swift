//
//  ReadersWriterLock.swift
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

struct ReadersWriterLock<T> {

    var get: T? {
        get {
            var synchronized: T?
            dispatch_sync(queue) {
                synchronized = self.synchronized
            }
            return synchronized
        }
    }

    private let queue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)

    private var synchronized: T?

    mutating func set(synchronized: T?) {
        dispatch_barrier_async(queue) {
            self.synchronized = synchronized
        }
    }

    mutating func setAndWait(synchronized: T?) {
        dispatch_barrier_sync(queue) {
            self.synchronized = synchronized
        }
    }

}
