

import Foundation

final class InterestSelectionStore {
    static let shared = InterestSelectionStore()
    private init() {}

    private let draftKeyPrefix = "opentone.onboarding.interestsDraft"

    var selected: Set<InterestItem> = [] {
        didSet {
            persistDraftForCurrentUser()
        }
    }

    func loadDraftForCurrentUser() {
        guard let userId = SessionManager.shared.currentUser?.id.uuidString else {
            selected = []
            return
        }

        let key = "\(draftKeyPrefix).\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([InterestItem].self, from: data) else {
            selected = []
            return
        }

        selected = Set(decoded)
    }

    func clearDraftForCurrentUser() {
        guard let userId = SessionManager.shared.currentUser?.id.uuidString else {
            selected = []
            return
        }

        let key = "\(draftKeyPrefix).\(userId)"
        UserDefaults.standard.removeObject(forKey: key)
        selected = []
    }

    private func persistDraftForCurrentUser() {
        guard let userId = SessionManager.shared.currentUser?.id.uuidString else { return }

        let key = "\(draftKeyPrefix).\(userId)"
        if selected.isEmpty {
            UserDefaults.standard.removeObject(forKey: key)
            return
        }

        let payload = Array(selected)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
