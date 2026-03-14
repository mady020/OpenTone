import Foundation

private func line(_ text: String, _ replyOptions: [String]) -> RoleplayMessage {
    RoleplayMessage(speaker: .npc, text: text, replyOptions: replyOptions)
}

let scenarios: [RoleplayScenario] = [
    // MARK: - Professional Track (10)

    RoleplayScenario(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        title: "Behavioral Job Interview",
        description: "Practice structured interview answers with clear examples, measurable impact, and thoughtful follow-up questions.",
        category: .interview,
        difficulty: .advanced,
        estimatedTimeMinutes: 8,
        script: [
            line("Tell me about yourself in under one minute.", [
                "I am a backend engineer with five years of fintech experience focused on reliability.",
                "I lead API delivery and improve incident prevention across platform teams.",
                "My strength is converting ambiguous requirements into stable, user-focused systems.",
                "I build and support customer-facing features end to end."
            ]),
            line("Describe a time you influenced people without formal authority.", [
                "I aligned three teams around one SLA by publishing risk updates and milestones.",
                "I used data from production incidents to secure cross-team priority changes.",
                "I facilitated a decision session and documented trade-offs and owners.",
                "I proved the approach in one pilot service, then scaled it across teams."
            ]),
            line("How do you handle conflicting deadlines?", [
                "I clarify business impact, define options, and agree on trade-offs early.",
                "I negotiate scope first so quality does not collapse near deadline.",
                "I document assumptions and escalate only with proposed alternatives.",
                "I sequence high-risk tasks first to avoid late surprises."
            ]),
            line("Tell me about a mistake and what you changed.", [
                "I once under-communicated risk, so now I maintain a visible weekly risk log.",
                "I shipped with weak alerting once, then added SLO alarms and runbooks.",
                "I underestimated integration complexity, so now I gate work with design reviews.",
                "I optimized too early, and now I start with user outcomes and baselines."
            ]),
            line("What questions do you have for us?", [
                "How do you define success for this role in the first 90 days?",
                "What are the key risks this team needs this hire to address?",
                "How does this role partner with product and design in decision-making?",
                "What growth paths are realistic for strong performers here?"
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        title: "Team Introduction on Day One",
        description: "Practice introducing yourself in a new team with clear role scope, strengths, and collaboration preferences.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("Welcome. Could you introduce yourself to the team?", [
                "Hi everyone, I am Maya, joining as a product analyst for onboarding metrics.",
                "I am Rahul, new mobile engineer focused on performance and release quality.",
                "I am Ana, joining customer success to support implementation and adoption.",
                "I am David, a UX designer working on first-time user experience."
            ]),
            line("What experience from your previous role is most relevant here?", [
                "I built reporting workflows that reduced manual analysis time.",
                "I ran release-readiness reviews for cross-functional launches.",
                "I translated client feedback into practical product changes.",
                "I improved design-to-engineering handoffs with clearer specs."
            ]),
            line("How do you prefer to collaborate with teammates?", [
                "I prefer clear written context before meetings and concise follow-ups.",
                "I value direct feedback and visible ownership of action items.",
                "I like short weekly syncs with clear decisions and next steps.",
                "I work best with early feedback loops before final delivery."
            ]),
            line("What will you focus on in your first two weeks?", [
                "I will learn current goals, key metrics, and active priorities.",
                "I will meet core partners and map blockers in our workflow.",
                "I will review user feedback and identify one quick improvement.",
                "I will understand tools and process so I can contribute quickly."
            ]),
            line("What do you need from us to start strong?", [
                "A shortlist of key docs and owners would help a lot.",
                "Access to dashboards and release history would speed up onboarding.",
                "A brief architecture walkthrough would provide useful context.",
                "A team buddy for the first sprint would be very helpful."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        title: "Weekly Project Status Update",
        description: "Practice concise project updates that include progress, blockers, risk level, and clear support requests.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("Give us a short status update on onboarding.", [
                "Development is 70 percent complete and QA starts tomorrow.",
                "Core flow is done in staging and analytics validation is in progress.",
                "We completed three key tasks and are preparing stakeholder review.",
                "Timeline is on track with one dependency under review."
            ]),
            line("What changed since last week?", [
                "We shipped account verification to staging and fixed two major bugs.",
                "We merged API updates and finalized acceptance criteria.",
                "We improved first-screen performance and reduced load time.",
                "We closed legal review items and updated rollout checklist."
            ]),
            line("Any blockers?", [
                "Analytics schema access is still pending and blocks final instrumentation.",
                "Design approval for one edge case is delayed.",
                "No critical blockers, but QA bandwidth is tight next sprint.",
                "A dependency team changed an endpoint and we are validating impact."
            ]),
            line("What is the risk level this week?", [
                "Medium risk: timeline is stable, but dependency resolution is urgent.",
                "Low risk if schema access is approved within one day.",
                "Medium-high risk for analytics quality until end-to-end checks complete.",
                "Low scope risk, medium release-readiness risk due to test coverage gaps."
            ]),
            line("What support do you need from leadership?", [
                "Please unblock analytics schema approval today.",
                "Please prioritize QA regression support for this release.",
                "We need final security sign-off on one open item.",
                "Please align the dependency team on API contract freeze."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        title: "Clarifying Requirements with Product Manager",
        description: "Practice asking clear clarifying questions to avoid ambiguity and reduce rework before implementation starts.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("Before development starts, what do you need clarified?", [
                "Which user segment is in scope for this release?",
                "What is the primary success metric for launch?",
                "Are there legal or compliance constraints we must support?",
                "What should happen when required user data is missing?"
            ]),
            line("Which assumptions should we validate first?", [
                "Whether fewer steps increase completion without harming verification quality.",
                "Whether reminder messages improve completion in week one.",
                "Whether optional profile fields should stay optional at launch.",
                "Which failure cases are most common in current funnel data."
            ]),
            line("How should edge cases be handled in the spec?", [
                "I will document expected behavior for each edge case explicitly.",
                "I will define fallback states for timeouts and duplicate submissions.",
                "I will separate must-haves from deferred edge-case handling.",
                "I will include clear error message and recovery expectations."
            ]),
            line("What do you need from me to finalize requirements?", [
                "A ranked list of must-have versus optional outcomes.",
                "Acceptance criteria with concrete valid and invalid examples.",
                "Agreement on latency, accessibility, and analytics expectations.",
                "Decision owners for unresolved questions before sprint planning."
            ]),
            line("How will you align the team after this?", [
                "I will post a written decision summary with owners and deadlines.",
                "I will update tickets with scope boundaries and open risks.",
                "I will share a one-page implementation brief before planning.",
                "I will run a short walkthrough to confirm everyone is aligned."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
        title: "Disagreeing Professionally in a Design Review",
        description: "Practice challenging ideas respectfully using evidence, alternatives, and shared goals.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("You seem concerned about this proposal. What is your concern?", [
                "I support the goal, but this approach increases operational risk.",
                "I think this solves today\'s issue but creates long-term maintenance cost.",
                "I see scaling limitations that may impact reliability later.",
                "I am worried rollback safety is not strong enough yet."
            ]),
            line("Can you make that risk specific?", [
                "This creates a single failure point for checkout traffic.",
                "The dependency contract is unstable and may fail at runtime.",
                "The rollout plan has no safe fallback if error rates spike.",
                "We are coupling two systems that need independent scaling."
            ]),
            line("What alternative do you recommend?", [
                "Release behind a feature flag with measurable stop criteria.",
                "Ship read-only support first, then enable writes after validation.",
                "Pilot in one region before global rollout.",
                "Isolate risky logic in a separate component first."
            ]),
            line("How does that affect timeline?", [
                "It may add one sprint but significantly lowers production risk.",
                "We can keep the date by reducing lower-value scope.",
                "Minor delay, but better release confidence and less rework.",
                "We can parallelize testing to reduce schedule impact."
            ]),
            line("What do you need from the team to proceed?", [
                "Agreement on go/no-go launch criteria.",
                "A short decision meeting with trade-offs documented.",
                "Priority QA support for failure-mode testing.",
                "Product alignment on phased customer communication."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
        title: "Receiving Tough Feedback from Your Manager",
        description: "Practice receiving critical feedback calmly, clarifying expectations, and committing to measurable improvement.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("I want to discuss concerns about your project communication.", [
                "Thank you for raising this. I want to understand and improve quickly.",
                "I appreciate the feedback. Could you share specific examples?",
                "Understood. I am open to this and want to align with expectations.",
                "I hear you. Please walk me through the biggest gaps."
            ]),
            line("Two stakeholder updates were late and caused surprise.", [
                "That is fair. I should have escalated risk earlier.",
                "I understand the impact and take responsibility for that gap.",
                "I see how that created confusion. I will correct it immediately.",
                "Thank you for being direct. I agree this needs improvement."
            ]),
            line("What will you change going forward?", [
                "I will send weekly written updates with blockers, risk, and owners.",
                "I will escalate medium or higher risks within 24 hours.",
                "I will align expectations at sprint start and mid-sprint.",
                "I will maintain a visible risk log for stakeholders."
            ]),
            line("How will we measure improvement?", [
                "No stakeholder surprises on timeline or scope for the next two sprints.",
                "All updates are on time with explicit next steps.",
                "Risk changes are communicated within one business day.",
                "Cross-team blockers are surfaced earlier with clear owners."
            ]),
            line("What support do you need from me?", [
                "A quick weekly review of my update format would help.",
                "Feedback after my next stakeholder meeting would be valuable.",
                "Examples of strong updates used by senior leads would help me calibrate.",
                "Please flag early if my communication still misses expectations."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        title: "Client Kickoff Meeting",
        description: "Practice starting a client project with clear goals, scope boundaries, communication cadence, and next steps.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("Can you summarize our shared objective for phase one?", [
                "Launch the reporting dashboard by Q3 with agreed adoption targets.",
                "Reduce manual reporting effort by 40 percent in the first release.",
                "Deliver trusted visibility for operations decisions across key teams.",
                "Release stable core workflows before scaling to all regions."
            ]),
            line("What is in scope and out of scope for this phase?", [
                "Core dashboard metrics are in scope; advanced forecasting is phase two.",
                "Web dashboard is in scope; mobile support is deferred.",
                "Two integrations are included now; remaining systems later.",
                "Role-based access is included; custom exports are phase two."
            ]),
            line("How should we handle change requests?", [
                "Review weekly, then assess timeline and budget impact transparently.",
                "Log every request with business value and trade-offs.",
                "Escalate urgent changes with documented impact and approval.",
                "Use a light change-control process with a 48-hour response window."
            ]),
            line("What communication rhythm do you propose?", [
                "Weekly progress call plus written recap with decisions and blockers.",
                "Twice-weekly async updates and one live decision checkpoint.",
                "A fixed Thursday review with owners and next-week goals.",
                "Shared project board with clear status and deadlines."
            ]),
            line("What are immediate next steps after this meeting?", [
                "Send kickoff summary, confirm owners, and schedule discovery interviews.",
                "Share draft milestone plan by Friday for your sign-off.",
                "Publish risk register and communication plan within one day.",
                "Set up first requirements workshop with all core stakeholders."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!,
        title: "Negotiating Scope and Timeline",
        description: "Practice negotiating scope trade-offs with a client while preserving quality, trust, and delivery confidence.",
        category: .custom,
        difficulty: .advanced,
        estimatedTimeMinutes: 7,
        script: [
            line("We need full scope by the original date. Can you commit?", [
                "I want to meet your goals, and we need to discuss trade-offs to protect quality.",
                "We can deliver core value by that date with phased scope.",
                "If all items remain in scope, we need to align on a revised timeline.",
                "I recommend prioritizing highest business-value items first."
            ]),
            line("Why can\'t you just add more people and move faster?", [
                "Late staffing usually increases coordination overhead and delivery risk.",
                "Ramp-up time reduces short-term velocity for complex systems.",
                "Speed without alignment often creates defects and rework.",
                "We can accelerate selected tracks, but not all dependencies at once."
            ]),
            line("What plan do you propose?", [
                "Phase one: dashboard, alerts, exports. Phase two: advanced forecasting.",
                "Keep date by reducing lower-value customization in release one.",
                "Deliver 80 percent now and schedule remaining scope in next sprint.",
                "Use two milestones with checkpoint reviews and acceptance criteria."
            ]),
            line("How will this still meet our business commitments?", [
                "Phase-one scope directly maps to your top three business outcomes.",
                "We will review success metrics weekly with your stakeholders.",
                "High-visibility reporting ensures leadership can track value immediately.",
                "We will escalate issues within 24 hours with clear impact notes."
            ]),
            line("What do you need from us today?", [
                "Priority ranking and sign-off on deferred items.",
                "One decision-maker for rapid scope approvals.",
                "Agreement on milestone acceptance criteria.",
                "Confirmation of workflows that are business-critical for phase one."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        title: "Executive Presentation with Q&A",
        description: "Practice presenting recommendations to leadership and handling challenging questions with concise evidence-based responses.",
        category: .custom,
        difficulty: .advanced,
        estimatedTimeMinutes: 8,
        script: [
            line("You have five minutes. What is your recommendation?", [
                "I recommend prioritizing retention improvements over acquisition next quarter.",
                "We should improve onboarding first because churn is highest in week one.",
                "My recommendation is a phased rollout balancing impact and risk.",
                "We should consolidate tools to reduce cost and improve speed."
            ]),
            line("What evidence supports that?", [
                "Cohort data shows a 12 percent retention improvement with reduced onboarding friction.",
                "Pilot users activated faster and created fewer support tickets.",
                "Cost model shows payback within two quarters under conservative assumptions.",
                "Internal experiments indicate this has the strongest expected ROI."
            ]),
            line("What are the top risks?", [
                "Adoption risk is primary; we include change management in phase one.",
                "Dependency alignment risk is mitigated by milestone gates.",
                "Capacity risk exists, so lower-value items are de-scoped.",
                "Data-quality risk is addressed with parallel validation."
            ]),
            line("Why now instead of next quarter?", [
                "Delay extends known losses and increases customer churn risk.",
                "The current renewal cycle makes timing especially valuable.",
                "We already have validated groundwork and team readiness.",
                "Competing initiatives have lower impact than this option."
            ]),
            line("What decision do you need today?", [
                "Approval for phase-one scope, budget, and sponsor ownership.",
                "Go decision on timeline and launch criteria.",
                "Confirmation to reallocate capacity from lower-impact work.",
                "Agreement on success metrics and review cadence."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "A1A1A1A1-A1A1-A1A1-A1A1-A1A1A1A1A1A1")!,
        title: "High-Pressure Incident Communication",
        description: "Practice delivering clear incident updates under pressure, including knowns, unknowns, mitigation, and external communication.",
        category: .custom,
        difficulty: .advanced,
        estimatedTimeMinutes: 7,
        script: [
            line("We have a Sev-1 outage. Give me a 30-second update.", [
                "Checkout is degraded for 40 percent of traffic; mitigation is active and next update is in 15 minutes.",
                "Impact is limited to two regions; incident commander and responders are assigned.",
                "Root cause is not confirmed yet, but rollback is underway.",
                "Service is partially restored in one region while global safety checks continue."
            ]),
            line("What is known versus unknown right now?", [
                "Known: latency spike started after deployment. Unknown: exact dependency trigger.",
                "Known: read traffic is stable. Unknown: write-path failure at peak load.",
                "Known: rollback reduced errors. Unknown: cache behavior contribution.",
                "Known: customer complaints rising. Unknown: full recovery duration."
            ]),
            line("What is the immediate mitigation plan?", [
                "Complete rollback, cap non-essential traffic, and monitor error budget recovery.",
                "Shift traffic to healthy region and disable failing feature flag.",
                "Run controlled restart with guarded concurrency limits.",
                "Canary hotfix at 5 percent after staging validation."
            ]),
            line("How are we communicating externally?", [
                "Status page updates every 20 minutes with approved support messaging.",
                "Account teams have a consistent impact summary and ETA guidance.",
                "We are sharing verified facts and avoiding speculation.",
                "A post-incident summary will be published after stability is confirmed."
            ]),
            line("What happens after recovery?", [
                "Run a blameless postmortem with action owners and deadlines.",
                "Add detection controls and test them in incident drills.",
                "Strengthen rollout policy with stricter pre-launch gates.",
                "Report lessons learned and prevention milestones to leadership."
            ])
        ]
    ),

    // MARK: - Generic Track (10, students and young adults)

    RoleplayScenario(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        title: "Campus Group Project Kickoff",
        description: "Practice setting goals, dividing tasks, and agreeing communication norms in a student group project meeting.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("Let\'s start the project kickoff. How should we organize this?", [
                "Let\'s agree on scope first, then divide tasks by strengths.",
                "We can define milestones today and assign one owner per deliverable.",
                "Let\'s align on grading criteria before planning task details.",
                "I suggest setting deadlines first, then mapping responsibilities."
            ]),
            line("What role would you like to take?", [
                "I can lead research and summarize key sources.",
                "I can handle slide structure and final presentation flow.",
                "I can coordinate timeline and make sure tasks stay on track.",
                "I can handle data analysis and visuals."
            ]),
            line("How should we communicate between meetings?", [
                "A group chat for quick updates and one shared doc for decisions.",
                "Two check-ins per week with short status notes.",
                "Let\'s post blockers early so we can help each other.",
                "Use one task board so deadlines are visible to everyone."
            ]),
            line("What should be done by next week?", [
                "Complete topic research and finalize outline.",
                "Draft slide one to five and share for feedback.",
                "Confirm sources and build initial bibliography.",
                "Agree on speaking parts and rehearsal date."
            ]),
            line("Great. How do we close this meeting?", [
                "I\'ll send a recap with owners and deadlines tonight.",
                "Let\'s confirm next meeting time now.",
                "We\'ll track progress in the shared board before Friday.",
                "If anyone is blocked, post in chat within 24 hours."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
        title: "Asking a Professor for Clarification",
        description: "Practice politely asking for clarification on assignment instructions, grading criteria, and expectations.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("What would you like clarified about the assignment?", [
                "Could you clarify the expected depth of analysis in section two?",
                "I want to confirm whether outside sources are required or optional.",
                "Could you explain how the rubric weighs structure versus originality?",
                "I am unsure about the expected format for the final submission."
            ]),
            line("What have you understood so far?", [
                "I understand the topic and deadline, but not the evidence requirements.",
                "I understand the format, but I am unsure about citation style.",
                "I understand the case study, but not how detailed conclusions should be.",
                "I understand the word limit, but I need clarity on appendices."
            ]),
            line("How will this clarification help you?", [
                "It will help me focus effort on the right evaluation criteria.",
                "It will reduce rework and help me submit a stronger final draft.",
                "It will ensure my structure aligns with your expectations.",
                "It will help me prioritize the most important evidence."
            ]),
            line("Do you need feedback before final submission?", [
                "Yes, could I share a brief outline for quick feedback next week?",
                "Yes, I would appreciate feedback on whether my argument direction is appropriate.",
                "A short check on my thesis statement would be very helpful.",
                "If possible, feedback on my source quality would help."
            ]),
            line("How will you follow up after this conversation?", [
                "I will send a short summary of what I understood for confirmation.",
                "I will adjust my plan and start drafting based on this guidance.",
                "I will update my outline and check it against the rubric.",
                "I will submit the draft checkpoint by the date you suggested."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
        title: "Making Plans and Rescheduling Politely",
        description: "Practice making plans clearly and rescheduling respectfully when conflicts arise.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("Are you free to meet for study prep this week?", [
                "Yes, I am free Wednesday evening after 6 PM.",
                "I can meet Thursday afternoon if that works for you.",
                "I am available tomorrow, but only for one hour.",
                "I can do Friday morning before class."
            ]),
            line("I just got a conflict. Can we reschedule?", [
                "No problem, thanks for letting me know early.",
                "Sure, what alternate time works best for you?",
                "That\'s fine. I can move it to Thursday if needed.",
                "Thanks for the update. Let\'s pick a new time now."
            ]),
            line("Could we move it to next week instead?", [
                "Yes, Monday at 5 PM works for me.",
                "Next week is okay; Tuesday evening is best for me.",
                "I can do next week if we confirm by tonight.",
                "Yes, let\'s schedule for Wednesday and lock it now."
            ]),
            line("How should we make sure we both remember?", [
                "I\'ll send a calendar invite right now.",
                "Let\'s confirm in chat one day before meeting.",
                "I\'ll share a reminder with location and agenda.",
                "Let\'s pin the plan in our group conversation."
            ]),
            line("Great, anything else before we close?", [
                "I\'ll also share what topics we should review before meeting.",
                "I\'ll bring notes so we can use the time efficiently.",
                "If timing changes again, I\'ll message you early.",
                "Perfect, thanks for being flexible."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
        title: "Requesting an Assignment Extension",
        description: "Practice asking for an extension professionally with accountability, context, and a realistic revised deadline.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("What do you want to request regarding your assignment?", [
                "I would like to request a short extension due to an unexpected medical issue.",
                "I am requesting a 48-hour extension because of two overlapping exam deadlines.",
                "I need a brief extension to submit work that meets course standards.",
                "I am asking for extra time and can explain my updated completion plan."
            ]),
            line("Can you explain your situation clearly?", [
                "I had a documented health issue this week that reduced my study time significantly.",
                "A required lab submission moved unexpectedly and overlapped this deadline.",
                "I underestimated required data collection and want to submit accurate work.",
                "I can provide details and supporting documentation if needed."
            ]),
            line("What new deadline are you proposing?", [
                "I can submit by Monday 5 PM with full references and final edits.",
                "A two-day extension will allow me to complete analysis properly.",
                "I can deliver a complete draft tomorrow and final version the day after.",
                "I propose submitting by Friday noon and sharing progress before then."
            ]),
            line("How will you ensure this does not repeat?", [
                "I am revising my schedule and setting earlier checkpoints for major tasks.",
                "I will flag potential conflicts sooner and request support earlier.",
                "I will complete outline and research phases earlier in future assignments.",
                "I will use a weekly planning review to avoid late deadline risk."
            ]),
            line("How should we close this conversation?", [
                "Thank you for considering this. I will confirm the agreed date in writing.",
                "I appreciate your flexibility and will submit by the revised deadline.",
                "I will share a progress update before final submission.",
                "Thanks for your time. I will follow the plan we discussed."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
        title: "Roommate Conflict About Shared Responsibilities",
        description: "Practice resolving a roommate issue respectfully by discussing impact, boundaries, and a concrete agreement.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("You wanted to talk about apartment responsibilities. What is the issue?", [
                "I feel cleaning tasks have become uneven over the last two weeks.",
                "We agreed on chores, but the schedule has not been followed.",
                "I am finding it hard to focus because shared spaces stay messy.",
                "I want us to reset expectations in a fair way."
            ]),
            line("Can you explain the impact without blaming?", [
                "When dishes pile up, it affects my routine and stress level.",
                "I spend extra time cleaning before studying, which is difficult.",
                "I want a solution that works for both of us, not an argument.",
                "I care about keeping the apartment manageable for everyone."
            ]),
            line("What solution do you suggest?", [
                "Let\'s create a simple weekly rota and rotate harder tasks fairly.",
                "We can split chores by preference but keep equal total effort.",
                "Let\'s set two quick cleanup checkpoints during the week.",
                "We can use a shared checklist so expectations are clear."
            ]),
            line("How will we handle missed tasks?", [
                "If someone misses, they should swap or complete within 24 hours.",
                "Let\'s flag conflicts early and agree replacements in chat.",
                "We can review the system weekly and adjust if needed.",
                "No blame, just quick communication and follow-through."
            ]),
            line("How do we close this constructively?", [
                "Thanks for discussing this openly. I\'ll share the rota tonight.",
                "I appreciate this. Let\'s start the new plan from Monday.",
                "Let\'s check in next week to see if this is working.",
                "I\'m glad we talked. This should make things easier for both of us."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!,
        title: "Customer Support for a Broken App Subscription",
        description: "Practice explaining a service problem clearly and working with support to reach a practical resolution.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("Thanks for contacting support. How can I help today?", [
                "My subscription renewed, but premium features are still locked.",
                "I was charged twice this month and need help resolving billing.",
                "My account shows active, but the app asks me to subscribe again.",
                "I cannot access my paid features after updating the app."
            ]),
            line("Can you share details so I can check your account?", [
                "Sure, I\'ll provide the email, transaction ID, and screenshot.",
                "I can share the receipt and exact time the charge occurred.",
                "I have payment confirmation and my account profile details ready.",
                "I can send a screen recording showing the issue flow."
            ]),
            line("I found the issue. We can restore access now.", [
                "Great, please restore access and confirm once complete.",
                "Thank you. Could you also check whether duplicate charges are reversed?",
                "Please let me know how long the fix will take.",
                "Can you explain what caused this so I can avoid it next time?"
            ]),
            line("Would you like additional help with anything else?", [
                "Yes, I need confirmation email after resolution.",
                "Please share next steps if the issue returns.",
                "Could you provide a case number for tracking?",
                "No, this resolves the main issue. Thank you."
            ]),
            line("Thanks for your patience. Your case is now updated.", [
                "Thanks for the support and clear follow-up.",
                "I appreciate the quick resolution.",
                "Great, I\'ll verify in the app now.",
                "Thanks, this was very helpful."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!,
        title: "Returning a Faulty Purchase",
        description: "Practice requesting a refund or exchange calmly with clear evidence and polite negotiation.",
        category: .restaurant,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("How can I help you at the returns desk today?", [
                "I bought these headphones yesterday, but the left side is not working.",
                "I would like to return this item because it is defective.",
                "I need an exchange because this product fails after charging.",
                "I want to discuss refund options for a faulty purchase."
            ]),
            line("Do you have a receipt or proof of purchase?", [
                "Yes, here is the receipt and payment confirmation.",
                "I have the digital receipt on my phone.",
                "I can share my order number and card transaction details.",
                "Yes, I purchased it with my student account."
            ]),
            line("Would you prefer a refund, exchange, or store credit?", [
                "I would prefer an exchange for the same model.",
                "A refund to my original payment method is best.",
                "Store credit is fine if it can be used immediately.",
                "Could I upgrade and pay the difference instead?"
            ]),
            line("I can process that now. Anything else you need?", [
                "Please confirm the return timeline and email receipt.",
                "Could you confirm how long the refund usually takes?",
                "Can you note the defect in case quality team needs details?",
                "No, that covers everything. Thank you."
            ]),
            line("Done. Your request has been processed.", [
                "Great, thank you for your help today.",
                "I appreciate the quick support.",
                "Thanks for handling this smoothly.",
                "Perfect, have a good day."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "F6F6F6F6-F6F6-F6F6-F6F6-F6F6F6F6F6F6")!,
        title: "First-Time Networking at a Student Event",
        description: "Practice introducing yourself, asking meaningful questions, and ending with a clear follow-up.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("Hi, we have not met before. What are you studying?", [
                "I am studying computer science and interested in product development.",
                "I am in business analytics and exploring internships in data roles.",
                "I study media and I\'m interested in communication strategy.",
                "I am in engineering and focused on sustainable design projects."
            ]),
            line("What kind of opportunities are you looking for?", [
                "I am looking for internships where I can work on real user problems.",
                "I want experience in cross-functional teams and practical project work.",
                "I am hoping to find mentors and entry-level opportunities.",
                "I am interested in research assistant roles this semester."
            ]),
            line("What projects are you currently proud of?", [
                "I built a small app that tracks study habits and weekly goals.",
                "I led a class project where we improved survey response rates.",
                "I created a design portfolio focused on accessibility improvements.",
                "I built a dashboard for student event participation data."
            ]),
            line("Would you like to stay in touch after this event?", [
                "Yes, I\'d appreciate that. I can connect on LinkedIn today.",
                "Definitely. I\'ll send a short message with my details.",
                "That would be great. Could we set up a short follow-up chat?",
                "Yes, I would like to learn more about your experience."
            ]),
            line("Great meeting you. Any final note before we move on?", [
                "Thanks for the conversation. I\'ll follow up by tomorrow.",
                "I appreciate your advice and would like to keep in touch.",
                "Great to meet you. I\'ll share my portfolio link later.",
                "Thanks, this was really useful."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "A7A7A7A7-A7A7-A7A7-A7A7-A7A7A7A7A7A7")!,
        title: "Giving Advice to a Stressed Friend",
        description: "Practice empathetic listening and practical advice without being dismissive or judgmental.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("I am overwhelmed with classes and deadlines. I do not know where to start.", [
                "I\'m sorry you\'re feeling this way. Do you want to talk through what\'s most urgent?",
                "That sounds really hard. Let\'s break it into smaller steps together.",
                "I hear you. Would it help to prioritize one task for today first?",
                "Thanks for sharing this. You do not have to handle it alone."
            ]),
            line("I keep procrastinating and then panic at night.", [
                "That cycle is exhausting. A short timed study block might help restart momentum.",
                "Would a simple plan with two realistic goals for today feel manageable?",
                "Maybe we can set a 25-minute focus session and check in after.",
                "Could we remove one non-essential commitment this week to reduce pressure?"
            ]),
            line("I also feel guilty asking for help.", [
                "Asking for help is a strength, not a failure.",
                "You deserve support, especially when workload is heavy.",
                "Reaching out early can prevent things from becoming worse.",
                "Many people need support at this stage; you are not alone."
            ]),
            line("What should I do first after this conversation?", [
                "List deadlines, choose top two priorities, and start the easiest one now.",
                "Send one message for support and schedule one focused study block.",
                "Prepare a short plan for tomorrow before going to sleep.",
                "Take a short break, then spend 30 minutes on your highest-impact task."
            ]),
            line("Thanks. Can we check in later this week?", [
                "Absolutely. Let\'s check in Friday and review what worked.",
                "Of course. Message me tonight after your first study block.",
                "Yes, I\'m here for you. We\'ll adjust the plan together.",
                "Definitely. You are doing the right thing by taking this step."
            ])
        ]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "B8B8B8B8-B8B8-B8B8-B8B8-B8B8B8B8B8B8")!,
        title: "Fixing Miscommunication in a Group Chat",
        description: "Practice resolving misunderstandings in text-based group communication with clarity and professionalism.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("There seems to be confusion about who was responsible for yesterday\'s task.", [
                "I think we had different interpretations. Let\'s clarify responsibilities now.",
                "I may have communicated unclearly. I\'d like to reset expectations.",
                "I understand the confusion. Let\'s align on owners and deadlines.",
                "Thanks for raising this. Let\'s focus on solution instead of blame."
            ]),
            line("What exactly should have happened?", [
                "I was expected to draft slides, while review ownership was still unclear.",
                "The message said \"team update\" but did not assign one final owner.",
                "I completed my part, but handoff timing was not explicit.",
                "We did not confirm who would submit the final document."
            ]),
            line("How do we avoid this problem next time?", [
                "Let\'s assign one owner per task and confirm in one summary message.",
                "Use a checklist with due dates and initials for each item.",
                "After decisions, post a recap with action items and deadlines.",
                "Let\'s avoid ambiguous terms like \"someone\" or \"team\" for ownership."
            ]),
            line("What should we do right now to recover?", [
                "I can complete the missing section in the next hour.",
                "Let\'s split remaining tasks and confirm who submits final version.",
                "I\'ll post a revised plan now and tag each owner.",
                "We can do a quick 10-minute call to finalize next steps."
            ]),
            line("How should we close this thread?", [
                "I\'ll share a clear recap with owners, deadlines, and submission plan.",
                "Thanks everyone. Let\'s confirm completion by 8 PM.",
                "I appreciate the quick alignment. We\'re back on track now.",
                "Great, we have a plan. I\'ll post progress updates as we execute."
            ])
        ]
    )
]
