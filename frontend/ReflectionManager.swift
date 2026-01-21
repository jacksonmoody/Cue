//
//  ReflectionManager.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 1/19/26.
//

import Foundation

struct Session: Identifiable, Hashable {
    let id: UUID
    let startDate: Date
    let gear1Finished: Date?
    let gear2Finished: Date?
    let endDate: Date?
    
    var duration: TimeInterval {
        guard let endDate else { return 0 }
        return endDate.timeIntervalSince(startDate)
    }
    
    let gear1: GearOption
    let gear2: GearOption
    let gear3: GearOption
}

struct GearOption: Identifiable, Equatable, Hashable {
    let id = UUID()
    var text: String
    var icon: String
}

