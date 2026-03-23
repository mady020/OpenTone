//
//  supabaseManager.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 23/02/26.
//

import Foundation
import Supabase

// MARK: - Configuration Helpers

private enum SupabaseConfig {
    /// Reads a value from Info.plist (populated via Secrets.xcconfig).
    static func plistValue(for key: String) -> String {
        guard let value = Bundle.main.infoDictionary?[key] as? String,
              !value.isEmpty else {
            fatalError("⚠️ Missing \(key) in Info.plist. " +
                       "Make sure Secrets.xcconfig exists and the project " +
                       "build configuration references it.")
        }
        return value
    }

    static var supabaseURL: URL {
        guard let url = URL(string: plistValue(for: "SUPABASE_URL")) else {
            fatalError("⚠️ SUPABASE_URL in Info.plist is not a valid URL.")
        }
        return url
    }

    static var supabaseKey: String {
        plistValue(for: "SUPABASE_KEY")
    }
}

/// Central Supabase client — used by all DataModel managers.
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.supabaseURL,
    supabaseKey: SupabaseConfig.supabaseKey,
    options: SupabaseClientOptions(
        auth: .init(
            emitLocalSessionAsInitialSession: true
        )
    )
)

enum SupabaseAuth {
    // Test hooks
    static var signInOverride: ((String, String) async throws -> (id: UUID, email: String?))?
    static var signUpOverride: ((String, String) async throws -> Void)?
    static var signOutOverride: (() async throws -> Void)?
    static var sessionUserOverride: (() async throws -> (id: UUID, email: String?))?
    static var hasActiveSessionOverride: (() async -> Bool)?
    static var accessTokenOverride: (() async -> String?)?
    static var updatePasswordOverride: ((String, String) async throws -> Void)?
    static var resetPasswordOverride: ((String) async throws -> Void)?

    static func signIn(email: String, password: String) async throws -> (id: UUID, email: String?) {
        if let override = signInOverride {
            return try await override(email, password)
        }
        let session = try await supabase.auth.signIn(email: email, password: password)
        return (session.user.id, session.user.email)
    }

    static func signUp(email: String, password: String) async throws {
        if let override = signUpOverride {
            try await override(email, password)
            return
        }
        _ = try await supabase.auth.signUp(email: email, password: password)
    }

    static func signOut() async throws {
        if let override = signOutOverride {
            try await override()
            return
        }
        try await supabase.auth.signOut()
    }

    static func sessionUser() async throws -> (id: UUID, email: String?) {
        if let override = sessionUserOverride {
            return try await override()
        }
        let session = try await supabase.auth.session
        return (session.user.id, session.user.email)
    }

    /// Returns true when a persisted or refreshed auth session is available.
    static func hasActiveSession() async -> Bool {
        if let override = hasActiveSessionOverride {
            return await override()
        }
        return (try? await supabase.auth.session) != nil
    }

    /// Returns the active access token when present.
    static func accessToken() async -> String? {
        if let override = accessTokenOverride {
            return await override()
        }
        return try? await supabase.auth.session.accessToken
    }

    /// Returns the authenticated user id if a session exists.
    static func currentUserID() async -> UUID? {
        try? await sessionUser().id
    }

    static func updatePassword(email: String, currentPassword: String, newPassword: String) async throws {
        if let override = updatePasswordOverride {
            try await override(currentPassword, newPassword)
            return
        }

        // Just use the active session to update the password directly.
        try await supabase.auth.update(user: UserAttributes(password: newPassword))
    }

    static func resetPassword(email: String) async throws {
        if let override = resetPasswordOverride {
            try await override(email)
            return
        }
        try await supabase.auth.resetPasswordForEmail(email)
    }
}

// MARK: - Supabase Table Names

/// Constants for table names to avoid string typos.
enum SupabaseTable {
    static let users            = "users"
    static let activities       = "activities"
    static let callRecords      = "call_records"
    static let jamSessions      = "jam_sessions"
    static let completedSessions = "completed_sessions"
    static let roleplaySessions = "roleplay_sessions"
    static let reports          = "reports"
}
