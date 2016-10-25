//
//  NSDateExtension.swift
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

private let localeIdentifier = "en_US_POSIX"
private let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return ((lhs === rhs) || (lhs.compare(rhs) == .OrderedSame))
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return (lhs.compare(rhs) == .OrderedAscending)
}

public func >(lhs: NSDate, rhs: NSDate) -> Bool {
    return (lhs.compare(rhs) == .OrderedDescending)
}

extension NSDate: Comparable {

    var isPast: Bool {
        return (timeIntervalSinceNow < 0.0)
    }

    var isFuture: Bool {
        return (timeIntervalSinceNow > 0.0)
    }

}

extension NSDate {

    private static let ISO8601StringFromDateFormatter: NSDateFormatter = {
        var dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: localeIdentifier)
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        dateFormatter.dateFormat = dateFormat
        return dateFormatter
    }()

    private static let ISO8601DateFromStringFormatter: NSDateFormatter = {
        var dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: localeIdentifier)
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter
    }()

    var ISO8601String: String {
        return NSDate.ISO8601StringFromDateFormatter.stringFromDate(self)
    }

    convenience init?(ISO8601String string: String) {
        guard let date = NSDate.ISO8601DateFromStringFormatter.dateFromString(string) else {
            self.init(timeInterval: 0, sinceDate: NSDate()) // TODO: Remove when no longer causing crash without it
            return nil
        }
        self.init(timeInterval: 0, sinceDate: date)
    }

}
