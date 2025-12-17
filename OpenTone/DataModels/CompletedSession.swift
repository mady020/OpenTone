//
//  CompletedSession.swift
//  OpenTone
//
//  Created by Student on 17/12/25.
//

import Foundation

struct CompletedSession: Codable {
    let activityName: String
    let durationInMinutes: Int
    let xpGained: Int
    let date: Date
}

