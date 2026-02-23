//
//  supabaseManager.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 23/02/26.
//

import Foundation
import Supabase

/// Central Supabase client — used by all DataModel managers.
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://tnjawcfajxmcnucsfrzm.supabase.co")!,
    supabaseKey: "sb_publishable_2BgOnfn_woDQlWE5KY8saA_pCYzsKO1"
)

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
