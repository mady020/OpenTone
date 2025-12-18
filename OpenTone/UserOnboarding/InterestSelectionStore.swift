

import Foundation

final class InterestSelectionStore {
    static let shared = InterestSelectionStore()
    private init() {}

    var selected: Set<InterestItem> = []
}
