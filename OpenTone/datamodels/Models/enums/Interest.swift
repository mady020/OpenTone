//
//  Interest.swift
//  StoryboardsExample
//
//  Created by Harshdeep Singh on 05/11/25.
//

import Foundation

enum Interest: String, Codable, CaseIterable {
    case technology
    case health
    case education
    case entertainment
    case sports
    case music
    case movies
    case travel
    case food
    case science
    case art

    var displayName: String {
        switch self {
        case .technology: return "Technology"
        case .health: return "Health"
        case .education: return "Education"
        case .entertainment: return "Entertainment"
        case .sports: return "Sports"
        case .music: return "Music"
        case .movies: return "Movies"
        case .travel: return "Travel"
        case .food: return "Food"
        case .science: return "Science"
        case .art: return "Art"
        }
    }
}


