//
//  Time.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 08.04.2026.
//
import Foundation

struct Time: Codable, Hashable {
    private var _timeEntry: String?
    private var _timeClose: String?

    var isDayOff: Bool

    var timeEntry: DateComponents? {
        guard let parts = _timeEntry?.split(separator: ":").compactMap({ Int($0) }), parts.count >= 2 else {
            return nil
        }
        return DateComponents(hour: parts[0], minute: parts[1])
    }

    var timeClose: DateComponents? {
        guard let parts = _timeClose?.split(separator: ":").compactMap({ Int($0) }), parts.count >= 2 else {
            return nil
        }
        return DateComponents(hour: parts[0], minute: parts[1])
    }

    var isClosed: Bool {
        isDayOff || _timeEntry == nil || _timeClose == nil
    }

    enum CodingKeys: String, CodingKey {
        case _timeEntry = "timeEntry"
        case _timeClose = "timeClose"
        case isDayOff
    }

    init(entry: String?, close: String?, isDayOff: Bool = false) {
        _timeEntry = entry
        _timeClose = close
        self.isDayOff = isDayOff
    }
}

enum WeekDay: String, Codable {
    case Sunday
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
}
