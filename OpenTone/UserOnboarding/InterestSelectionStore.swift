//
//  InterestSelectionStore.swift
//  OpenTone
//
//  Created by M S on 03/12/25.
//


import Foundation

final class InterestSelectionStore {
    static let shared = InterestSelectionStore()
    private init() {}

    var selected: Set<InterestItem> = []
}
