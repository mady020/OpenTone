import XCTest
@testable import OpenTone

@MainActor
final class AuthSessionLifecycleTests: XCTestCase {

    private let currentUserIDKey = "currentUserID"
    private let lastWpmDeltaKey = "opentone.lastWpmDelta"
    private let appThemePreferenceKey = "app_theme_preference"

    override func setUp() {
        super.setUp()
        resetAuthOverrides()

        UserDefaults.standard.removeObject(forKey: currentUserIDKey)
        UserDefaults.standard.removeObject(forKey: lastWpmDeltaKey)
        UserDefaults.standard.removeObject(forKey: appThemePreferenceKey)

        // Initialize singletons under a deterministic no-session test state.
        _ = UserDataModel.shared
        _ = SessionManager.shared

        UserDataModel.shared.deleteCurrentUser()
        SessionManager.shared.refreshSession()
    }

    override func tearDown() {
        resetAuthOverrides()
        UserDataModel.shared.deleteCurrentUser()
        SessionManager.shared.refreshSession()
        UserDefaults.standard.removeObject(forKey: currentUserIDKey)
        UserDefaults.standard.removeObject(forKey: lastWpmDeltaKey)
        UserDefaults.standard.removeObject(forKey: appThemePreferenceKey)
        super.tearDown()
    }

    func testLoginPersistsCurrentUserID() {
        let user = makeUser(name: "Auth Test", email: "auth@test.local")

        SessionManager.shared.login(user: user)

        XCTAssertTrue(SessionManager.shared.isLoggedIn)
        XCTAssertEqual(SessionManager.shared.currentUser?.id, user.id)
        XCTAssertEqual(UserDefaults.standard.string(forKey: currentUserIDKey), user.id.uuidString)
    }

    func testSessionRestoreUsesStoredSupabaseSessionUser() async {
        var user = makeUser(name: "Restore Test", email: "restore@test.local")
        let fixedID = UUID()
        user.setID(fixedID)

        UserDataModel.shared.cacheUserForTesting(user)
        UserDataModel.shared.deleteCurrentUser()

        SupabaseAuth.hasActiveSessionOverride = { true }
        SupabaseAuth.sessionUserOverride = {
            (id: fixedID, email: user.email)
        }

        await UserDataModel.shared.restoreCurrentUserFromSessionForTesting()

        XCTAssertEqual(UserDataModel.shared.getCurrentUser()?.id, fixedID)
        XCTAssertEqual(UserDefaults.standard.string(forKey: currentUserIDKey), fixedID.uuidString)
    }

    func testAuthenticatedAPIAccessReflectsSessionTokenPresence() async {
        SupabaseAuth.accessTokenOverride = { "test-access-token" }
        XCTAssertTrue(await SessionManager.shared.hasAuthenticatedAPIAccess())

        SupabaseAuth.accessTokenOverride = { nil }
        XCTAssertFalse(await SessionManager.shared.hasAuthenticatedAPIAccess())
    }

    func testLogoutClearsSessionStateAndCachedKeys() async {
        var signOutCalled = false
        SupabaseAuth.signOutOverride = {
            signOutCalled = true
        }

        let user = makeUser(name: "Logout Test", email: "logout@test.local")
        SessionManager.shared.login(user: user)
        UserDefaults.standard.set(1.5, forKey: lastWpmDeltaKey)

        let userId = user.id.uuidString
        let feedbackProfileKey = "opentone.feedback.profile.\(userId)"
        let feedbackSuggestionsKey = "opentone.feedback.recentSuggestions.\(userId)"
        let sampleSeedKey = "SampleDataSeeder.hasSeeded.\(userId)"
        let onboardingDraftKey = "opentone.onboarding.interestsDraft.\(userId)"
        let dailyGoalKey = "opentone.dailyGoalAchievement.\(userId).2026-03-16"

        UserDefaults.standard.set(Data([0x01, 0x02]), forKey: feedbackProfileKey)
        UserDefaults.standard.set(["Tip 1", "Tip 2"], forKey: feedbackSuggestionsKey)
        UserDefaults.standard.set(true, forKey: sampleSeedKey)
        UserDefaults.standard.set(Data([0x03]), forKey: onboardingDraftKey)
        UserDefaults.standard.set(true, forKey: dailyGoalKey)
        UserDefaults.standard.set(2, forKey: appThemePreferenceKey)

        await SessionManager.shared.logoutAsync()

        XCTAssertTrue(signOutCalled)
        XCTAssertFalse(SessionManager.shared.isLoggedIn)
        XCTAssertNil(SessionManager.shared.currentUser)
        XCTAssertNil(UserDefaults.standard.object(forKey: currentUserIDKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: lastWpmDeltaKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: feedbackProfileKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: feedbackSuggestionsKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: sampleSeedKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: onboardingDraftKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: dailyGoalKey))
        XCTAssertEqual(UserDefaults.standard.integer(forKey: appThemePreferenceKey), 2)
    }

    private func makeUser(name: String, email: String) -> User {
        User(
            name: name,
            email: email,
            password: "",
            country: nil,
            avatar: "pp1"
        )
    }

    private func resetAuthOverrides() {
        SupabaseAuth.signInOverride = nil
        SupabaseAuth.signUpOverride = nil
        SupabaseAuth.signOutOverride = nil
        SupabaseAuth.sessionUserOverride = nil
        SupabaseAuth.hasActiveSessionOverride = { false }
        SupabaseAuth.accessTokenOverride = nil
        SupabaseAuth.updatePasswordOverride = nil
    }
}
