import Foundation

private func line(_ text: String, _ replyOptions: [String]) -> RoleplayMessage {
    RoleplayMessage(speaker: .npc, text: text, replyOptions: replyOptions)
}

let scenarios: [RoleplayScenario] = [
    // MARK: - Professional Track (10)

    RoleplayScenario(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        title: "Job Interview",
        description: "Practice structured interview answers with clear examples, measurable impact, and thoughtful follow-up questions.",
        category: .interview,
        difficulty: .advanced,
        estimatedTimeMinutes: 8,
        script: [
            line("Tell me about yourself in under one minute.", [
                "I have five years of experience focused on solving complex problems.",
                "I lead cross-functional delivery and improve processes across teams.",
                "My strength is converting ambiguous requirements into stable solutions.",
                "I build and support user-facing features end to end."
            ]),
            line("Describe a time you influenced people without formal authority.", [
                "I aligned three teams around one goal by publishing risk updates.",
                "I used data from past projects to secure cross-team buy-in.",
                "I facilitated a decision session and documented trade-offs.",
                "I proved the approach in one pilot phase, then scaled it."
            ]),
            line("How do you handle conflicting deadlines?", [
                "I clarify business impact, define options, and agree on trade-offs early.",
                "I negotiate scope first so quality does not collapse near the deadline.",
                "I document assumptions and escalate only with proposed alternatives.",
                "I sequence high-risk tasks first to avoid late surprises."
            ]),
            line("Tell me about a mistake and what you changed.", [
                "I once under-communicated risk, so now I maintain a visible weekly risk log.",
                "I shipped without enough review once, then added clear pre-launch checklists.",
                "I underestimated integration complexity, so now I gate work with early design reviews.",
                "I optimized too early, and now I start with user outcomes and baselines."
            ]),
            line("What questions do you have for us?", [
                "How do you define success for this role in the first 90 days?",
                "What are the key risks this team needs this hire to address?",
                "How does this role partner with other departments in decision-making?",
                "What growth paths are realistic for strong performers here?"
            ])
        ],
        relatedInterests: ["Business", "Technology", "Finance", "Productivity"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        title: "Team Intro",
        description: "Practice introducing yourself in a new team with clear role scope, strengths, and collaboration preferences.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("Welcome. Could you introduce yourself to the team?", [
                "Hi everyone, I am joining to focus on our primary growth metrics.",
                "I am a new team member focused on performance and quality.",
                "I am joining to support client implementation and product adoption.",
                "I am a specialist working on improving our core user experience."
            ]),
            line("What experience from your previous role is most relevant here?", [
                "I built reporting workflows that reduced manual analysis time.",
                "I ran readiness reviews for cross-functional launches.",
                "I translated client feedback into practical process changes.",
                "I improved the handoff process with clearer guidelines."
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
                "I will understand the tools and process so I can contribute quickly."
            ]),
            line("What do you need from us to start strong?", [
                "A shortlist of key docs and owners would help a lot.",
                "Access to our main dashboards would speed up onboarding.",
                "A brief system walkthrough would provide useful context.",
                "A team buddy for the first sprint would be very helpful."
            ])
        ],
        relatedInterests: ["Business", "Productivity", "Learning"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        title: "Project Update",
        description: "Practice concise project updates that include progress, blockers, risk level, and clear support requests.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("Give us a short status update on the current project.", [
                "Work is 70 percent complete and final review starts tomorrow.",
                "Core tasks are done and validation is in progress.",
                "We completed three key milestones and are preparing stakeholder review.",
                "Timeline is on track with one dependency currently under review."
            ]),
            line("What changed since last week?", [
                "We shipped the latest update and fixed two major issues.",
                "We merged final changes and finalized acceptance criteria.",
                "We improved performance and significantly reduced processing time.",
                "We closed the review items and updated the rollout checklist."
            ]),
            line("Any blockers?", [
                "Access approval is still pending and blocks final steps.",
                "Approval for one edge case is currently delayed.",
                "No critical blockers, but bandwidth is tight next week.",
                "A dependency changed its requirements and we are validating the impact."
            ]),
            line("What is the risk level this week?", [
                "Medium risk: timeline is stable, but dependency resolution is urgent.",
                "Low risk if access is approved within one day.",
                "Medium-high risk for quality until end-to-end checks complete.",
                "Low scope risk, but medium readiness risk due to testing gaps."
            ]),
            line("What support do you need from leadership?", [
                "Please unblock the access approval today.",
                "Please prioritize final review support for this release.",
                "We need final sign-off on one open item.",
                "Please align the partner team on the final deliverables."
            ])
        ],
        relatedInterests: ["Business", "Productivity", "Technology"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        title: "Scope Clarify",
        description: "Practice asking clear clarifying questions to avoid ambiguity and reduce rework before implementation starts.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("Before we start, what do you need clarified?", [
                "Which user segment is in scope for this phase?",
                "What is the primary success metric for launch?",
                "Are there compliance constraints we must support?",
                "What should happen when required data is missing?"
            ]),
            line("Which assumptions should we validate first?", [
                "Whether fewer steps increase completion rates without harming quality.",
                "Whether automated reminders improve engagement in week one.",
                "Whether optional inputs should stay optional at launch.",
                "Which failure cases are most common in current workflows."
            ]),
            line("How should edge cases be handled in the spec?", [
                "I will document expected behavior for each edge case explicitly.",
                "I will define fallback states for errors and duplicate submissions.",
                "I will separate must-haves from deferred edge-case handling.",
                "I will include clear error messaging and recovery expectations."
            ]),
            line("What do you need from me to finalize requirements?", [
                "A ranked list of must-have versus optional outcomes.",
                "Acceptance criteria with concrete valid and invalid examples.",
                "Agreement on performance, accessibility, and reporting expectations.",
                "Decision owners for unresolved questions before we start planning."
            ]),
            line("How will you align the team after this?", [
                "I will post a written decision summary with owners and deadlines.",
                "I will update our tracker with scope boundaries and open risks.",
                "I will share a one-page brief before our planning session.",
                "I will run a short walkthrough to confirm everyone is aligned."
            ])
        ],
        relatedInterests: ["Business", "Productivity", "Learning", "Technology"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
        title: "Design Review",
        description: "Practice challenging ideas respectfully using evidence, alternatives, and shared goals.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("You seem concerned about this proposal. What is your concern?", [
                "I support the goal, but this approach increases our operational risk.",
                "I think this solves today's issue but creates long-term maintenance cost.",
                "I see scaling limitations that may impact reliability later.",
                "I am worried that our fallback safety is not strong enough yet."
            ]),
            line("Can you make that risk specific?", [
                "This creates a single failure point for critical traffic.",
                "The dependency contract is unstable and may fail under load.",
                "The rollout plan has no safe fallback if error rates spike.",
                "We are coupling two systems that need independent scaling."
            ]),
            line("What alternative do you recommend?", [
                "Release behind a feature toggle with measurable stop criteria.",
                "Ship read-only support first, then enable updates after validation.",
                "Pilot in one controlled environment before full rollout.",
                "Isolate risky logic in a separate component first."
            ]),
            line("How does that affect timeline?", [
                "It may add one week but significantly lowers production risk.",
                "We can keep the date by reducing lower-value scope.",
                "Minor delay, but better release confidence and less rework.",
                "We can parallelize our testing to reduce schedule impact."
            ]),
            line("What do you need from the team to proceed?", [
                "Agreement on clear go/no-go launch criteria.",
                "A short decision meeting with trade-offs documented.",
                "Priority testing support for failure-mode scenarios.",
                "Alignment on phased communication."
            ])
        ],
        relatedInterests: ["Art & Design", "Technology", "Business"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
        title: "Manager Feedback",
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
                "That is fair. I should have escalated the risk earlier.",
                "I understand the impact and take responsibility for that gap.",
                "I see how that created confusion. I will correct it immediately.",
                "Thank you for being direct. I agree this needs improvement."
            ]),
            line("What will you change going forward?", [
                "I will send weekly written updates with blockers, risk, and owners.",
                "I will escalate medium or higher risks within 24 hours.",
                "I will align expectations at the start and middle of every cycle.",
                "I will maintain a visible risk log for all stakeholders."
            ]),
            line("How will we measure improvement?", [
                "No stakeholder surprises on timeline or scope for the next month.",
                "All updates are delivered on time with explicit next steps.",
                "Risk changes are communicated within one business day.",
                "Cross-team blockers are surfaced earlier with clear owners."
            ]),
            line("What support do you need from me?", [
                "A quick weekly review of my update format would help.",
                "Feedback after my next major meeting would be valuable.",
                "Examples of strong updates used by senior leads would help me calibrate.",
                "Please flag early if my communication still misses expectations."
            ])
        ],
        relatedInterests: ["Business", "Learning", "Productivity"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        title: "Client Kickoff",
        description: "Practice starting a client project with clear goals, scope boundaries, communication cadence, and next steps.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("Can you summarize our shared objective for phase one?", [
                "Launch the new platform by Q3 with agreed adoption targets.",
                "Reduce manual effort by 40 percent in the first major release.",
                "Deliver trusted visibility for decisions across key teams.",
                "Release stable core workflows before scaling globally."
            ]),
            line("What is in scope and out of scope for this phase?", [
                "Core functionality is in scope; advanced features are phase two.",
                "Web access is in scope; mobile support is deferred.",
                "Two main integrations are included now; remaining systems later.",
                "Standard access is included; custom exports are phase two."
            ]),
            line("How should we handle change requests?", [
                "Review weekly, then assess timeline and budget impact transparently.",
                "Log every request with business value and trade-offs.",
                "Escalate urgent changes with documented impact and approval.",
                "Use a light scope-control process with a 48-hour response window."
            ]),
            line("What communication rhythm do you propose?", [
                "Weekly progress call plus written recap with decisions and blockers.",
                "Twice-weekly async updates and one live decision checkpoint.",
                "A fixed weekly review with owners and next-week goals.",
                "Shared project board with clear status and deadlines."
            ]),
            line("What are immediate next steps after this meeting?", [
                "Send kickoff summary, confirm owners, and schedule discovery interviews.",
                "Share draft milestone plan by Friday for your sign-off.",
                "Publish risk register and communication plan within one day.",
                "Set up first requirements workshop with all core stakeholders."
            ])
        ],
        relatedInterests: ["Business", "Finance", "Technology"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!,
        title: "Negotiate Scope",
        description: "Practice negotiating scope trade-offs with a client while preserving quality, trust, and delivery confidence.",
        category: .custom,
        difficulty: .advanced,
        estimatedTimeMinutes: 7,
        script: [
            line("We need full scope by the original date. Can you commit?", [
                "I want to meet your goals, and we need to discuss trade-offs to protect quality.",
                "We can deliver core value by that date with a phased scope approach.",
                "If all items remain in scope, we need to align on a revised timeline.",
                "I recommend prioritizing the highest business-value items first."
            ]),
            line("Why can't you just add more people and move faster?", [
                "Late staffing usually increases coordination overhead and delivery risk.",
                "Ramp-up time reduces short-term velocity for complex tasks.",
                "Speed without alignment often creates defects and requires rework.",
                "We can accelerate selected tracks, but not all dependencies at once."
            ]),
            line("What plan do you propose?", [
                "Phase one delivers the core; phase two delivers the advanced features.",
                "Keep the date by reducing lower-value customization in release one.",
                "Deliver 80 percent now and schedule the remaining scope in the next cycle.",
                "Use two milestones with checkpoint reviews and strict acceptance criteria."
            ]),
            line("How will this still meet our business commitments?", [
                "Phase-one scope directly maps to your top three business outcomes.",
                "We will review success metrics weekly with your stakeholders.",
                "High-visibility outcomes ensure leadership can track value immediately.",
                "We will escalate issues within 24 hours with clear impact notes."
            ]),
            line("What do you need from us today?", [
                "Priority ranking and sign-off on deferred items.",
                "One decision-maker for rapid scope approvals.",
                "Agreement on milestone acceptance criteria.",
                "Confirmation of workflows that are business-critical for phase one."
            ])
        ],
        relatedInterests: ["Business", "Finance"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        title: "Executive Pitch",
        description: "Practice presenting recommendations to leadership and handling challenging questions with concise evidence-based responses.",
        category: .custom,
        difficulty: .advanced,
        estimatedTimeMinutes: 8,
        script: [
            line("You have five minutes. What is your recommendation?", [
                "I recommend prioritizing retention improvements over acquisition next quarter.",
                "We should improve user onboarding first because drop-off is highest in week one.",
                "My recommendation is a phased rollout balancing impact and risk.",
                "We should consolidate our tools to reduce cost and improve speed."
            ]),
            line("What evidence supports that?", [
                "Data shows a 12 percent improvement when we reduce friction.",
                "Pilot users activated faster and created fewer support tickets.",
                "Cost models show payback within two quarters under conservative assumptions.",
                "Internal experiments indicate this has the strongest expected ROI."
            ]),
            line("What are the top risks?", [
                "Adoption risk is primary; we include change management in phase one.",
                "Dependency alignment risk is mitigated by milestone gates.",
                "Capacity risk exists, so lower-value items are proactively de-scoped.",
                "Data-quality risk is addressed with parallel validation."
            ]),
            line("Why now instead of next quarter?", [
                "Delay extends known losses and increases risk of failure.",
                "The current cycle makes the timing especially valuable.",
                "We already have validated groundwork and team readiness.",
                "Competing initiatives have significantly lower impact than this option."
            ]),
            line("What decision do you need today?", [
                "Approval for phase-one scope, budget, and sponsor ownership.",
                "A go decision on the timeline and core launch criteria.",
                "Confirmation to reallocate capacity from lower-impact work.",
                "Agreement on success metrics and review cadence."
            ])
        ],
        relatedInterests: ["Business", "Finance", "Productivity"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "A1A1A1A1-A1A1-A1A1-A1A1-A1A1A1A1A1A1")!,
        title: "Incident Comms",
        description: "Practice delivering clear incident updates under pressure, including knowns, unknowns, mitigation, and external communication.",
        category: .custom,
        difficulty: .advanced,
        estimatedTimeMinutes: 7,
        script: [
            line("We have a major issue. Give me a 30-second update.", [
                "Performance is degraded for 40 percent of users; mitigation is active.",
                "Impact is limited to two systems; response lead is assigned.",
                "Root cause is not confirmed yet, but a rollback is underway.",
                "Service is partially restored while global safety checks continue."
            ]),
            line("What is known versus unknown right now?", [
                "Known: issues started after the update. Unknown: exact trigger.",
                "Known: primary flows are stable. Unknown: secondary failure impact.",
                "Known: rollback reduced errors. Unknown: caching contribution.",
                "Known: user complaints are rising. Unknown: full recovery duration."
            ]),
            line("What is the immediate mitigation plan?", [
                "Complete rollback, cap non-essential traffic, and monitor recovery.",
                "Shift traffic to healthy systems and disable failing features.",
                "Run a controlled restart with guarded concurrency limits.",
                "Deploy a hotfix gradually after strict validation."
            ]),
            line("How are we communicating externally?", [
                "Updates are going out every 20 minutes with approved messaging.",
                "Account teams have a consistent impact summary and ETA guidance.",
                "We are sharing verified facts and avoiding speculation.",
                "A full summary will be published after stability is confirmed."
            ]),
            line("What happens after recovery?", [
                "Run a postmortem with clear action owners and deadlines.",
                "Add detection controls and test them in future drills.",
                "Strengthen our policy with stricter pre-launch quality gates.",
                "Report lessons learned and prevention milestones to leadership."
            ])
        ],
        relatedInterests: ["Technology", "Business"]
    ),

    // MARK: - Generic Track (10)

    RoleplayScenario(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        title: "Group Project",
        description: "Practice setting goals, dividing tasks, and agreeing communication norms in a group project meeting.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("Let's start the kickoff. How should we organize this?", [
                "Let's agree on scope first, then divide tasks by strengths.",
                "We can define milestones today and assign one owner per deliverable.",
                "Let's align on standards before planning task details.",
                "I suggest setting deadlines first, then mapping responsibilities."
            ]),
            line("What role would you like to take?", [
                "I can lead the research and summarize key points.",
                "I can handle structure and presentation flow.",
                "I can coordinate the timeline and make sure tasks stay on track.",
                "I can handle data gathering and visuals."
            ]),
            line("How should we communicate between meetings?", [
                "A group chat for quick updates and one shared doc for decisions.",
                "Two check-ins per week with short status notes.",
                "Let's post blockers early so we can help each other.",
                "Use one task board so deadlines are visible to everyone."
            ]),
            line("What should be done by next week?", [
                "Complete the research and finalize our general outline.",
                "Draft the first sections and share them for group feedback.",
                "Confirm our primary sources and build an initial index.",
                "Agree on individual parts and schedule a rehearsal date."
            ]),
            line("Great. How do we close this meeting?", [
                "I'll send a recap with owners and deadlines tonight.",
                "Let's confirm our next meeting time right now.",
                "We'll track progress in the shared board before Friday.",
                "If anyone gets stuck, simply post in chat within 24 hours."
            ])
        ],
        relatedInterests: ["Learning", "Productivity"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
        title: "Class Clarify",
        description: "Practice politely asking for clarification on instructions, criteria, and expectations.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("What would you like clarified about the task?", [
                "Could you clarify the expected depth of detail in section two?",
                "I want to confirm whether outside sources are required or optional.",
                "Could you explain how the rubric weighs structure versus originality?",
                "I am unsure about the expected exact format for the final output."
            ]),
            line("What have you understood so far?", [
                "I understand the topic and deadline, but not the evidence requirements.",
                "I understand the format, but I am unsure about the required style.",
                "I understand the core idea, but not how detailed conclusions should be.",
                "I understand the core limits, but I need clarity on the appendices."
            ]),
            line("How will this clarification help you?", [
                "It will help me focus effort on the right evaluation criteria.",
                "It will reduce rework and help me submit a stronger final version.",
                "It will ensure my structure fully aligns with your expectations.",
                "It will help me prioritize the most important areas to focus on."
            ]),
            line("Do you need feedback before the final deadline?", [
                "Yes, could I share a brief outline for quick feedback next week?",
                "Yes, I would appreciate feedback on whether my direction is appropriate.",
                "A short check on my main thesis would be very helpful.",
                "If possible, feedback on my overall approach would help."
            ]),
            line("How will you follow up after this conversation?", [
                "I will send a short summary of what I understood for confirmation.",
                "I will adjust my plan and start drafting based on this guidance.",
                "I will update my outline and check it against the rubric.",
                "I will submit a draft checkpoint by the date you suggested."
            ])
        ],
        relatedInterests: ["Learning"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
        title: "Making Plans",
        description: "Practice making plans clearly and rescheduling respectfully when conflicts arise.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("Are you free to meet up this week?", [
                "Yes, I am free Wednesday evening after 6 PM.",
                "I can meet Thursday afternoon if that works for you.",
                "I am available tomorrow, but only for one hour.",
                "I can do Friday morning."
            ]),
            line("I just got a conflict. Can we reschedule?", [
                "No problem, thanks for letting me know early.",
                "Sure, what alternate time works best for you?",
                "That's fine. I can move it to Thursday if needed.",
                "Thanks for the update. Let's pick a new time now."
            ]),
            line("Could we move it to next week instead?", [
                "Yes, Monday at 5 PM works for me.",
                "Next week is okay; Tuesday evening is best for me.",
                "I can do next week if we confirm by tonight.",
                "Yes, let's schedule for Wednesday and lock it now."
            ]),
            line("How should we make sure we both remember?", [
                "I'll send a calendar invite right now.",
                "Let's confirm in text one day before meeting.",
                "I'll share a reminder with the location.",
                "Let's pin the plan in our conversation."
            ]),
            line("Great, anything else before we close?", [
                "I'll also share what we should bring before the meeting.",
                "I'll prepare some notes so we can use the time efficiently.",
                "If timing changes again, I'll message you early.",
                "Perfect, thanks for being flexible."
            ])
        ],
        relatedInterests: ["Travel", "Food", "Sports"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
        title: "Ask Extension",
        description: "Practice asking for an extension professionally with accountability, context, and a realistic revised deadline.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("What do you want to request regarding your deadline?", [
                "I would like to request a short extension due to an unexpected issue.",
                "I am requesting an extension because of two overlapping priorities.",
                "I need a brief extension to submit work that meets standards.",
                "I am asking for extra time and can explain my updated plan."
            ]),
            line("Can you explain your situation clearly?", [
                "I had a documented issue this week that reduced my focus time significantly.",
                "A required prior step moved unexpectedly and overlapped this deadline.",
                "I underestimated data collection and want to submit accurate work.",
                "I can provide details and supporting documentation if needed."
            ]),
            line("What new deadline are you proposing?", [
                "I can submit by Monday 5 PM with full references and final edits.",
                "A two-day extension will allow me to complete analysis properly.",
                "I can deliver a complete draft tomorrow and final version the day after.",
                "I propose submitting by Friday noon and sharing progress before then."
            ]),
            line("How will you ensure this does not repeat?", [
                "I am revising my schedule and setting earlier checkpoints.",
                "I will flag potential conflicts sooner and request support earlier.",
                "I will complete my initial tasks earlier in future occurrences.",
                "I will use a weekly planning review to avoid late deadline risk."
            ]),
            line("How should we close this conversation?", [
                "Thank you for considering this. I will confirm the date in writing.",
                "I appreciate your flexibility and will deliver by the revised deadline.",
                "I will share a progress update before the final submission.",
                "Thanks for your time. I will follow the plan we discussed."
            ])
        ],
        relatedInterests: ["Learning", "Productivity"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
        title: "Fix Conflict",
        description: "Practice resolving an interpersonal issue respectfully by discussing impact, boundaries, and a concrete agreement.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("You wanted to talk about our shared responsibilities. What is the issue?", [
                "I feel things have become uneven over the last two weeks.",
                "We agreed on a routine, but the schedule has not been followed.",
                "I am finding it hard to focus because shared spaces are untidy.",
                "I want us to reset expectations in a fair way."
            ]),
            line("Can you explain the impact without blaming?", [
                "When tasks pile up, it affects my routine and general stress level.",
                "I spend extra time picking up the slack, which is difficult.",
                "I want a solution that works for both of us, not an argument.",
                "I care about keeping things manageable for everyone."
            ]),
            line("What solution do you suggest?", [
                "Let's create a simple rotation map and rotate harder tasks fairly.",
                "We can split chores by preference but keep equal total effort.",
                "Let's set two quick checkpoints during the week.",
                "We can use a shared checklist so expectations are crystal clear."
            ]),
            line("How will we handle missed tasks?", [
                "If someone misses, they should swap or complete within 24 hours.",
                "Let's flag conflicts early and agree on replacements.",
                "We can review the system weekly and adjust if needed.",
                "No blame, just quick communication and prompt follow-through."
            ]),
            line("How do we close this constructively?", [
                "Thanks for discussing this openly. I'll share the plan tonight.",
                "I appreciate this. Let's start the new routine from Monday.",
                "Let's check in next week to see if this is working well.",
                "I'm glad we talked. This should make things easier for both of us."
            ])
        ],
        relatedInterests: ["Learning", "Cooking", "Pets"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!,
        title: "App Support",
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
                "Sure, I'll provide the email, transaction ID, and screenshot.",
                "I can share the receipt and exact time the charge occurred.",
                "I have payment confirmation and my account profile details ready.",
                "I can send a screen recording showing the issue flow."
            ]),
            line("I found the issue. We can restore access now.", [
                "Great, please restore access and confirm once complete.",
                "Thank you. Could you also check whether duplicate charges are reversed?",
                "Please let me know how long the fix will take to process.",
                "Can you explain what caused this so I can avoid it next time?"
            ]),
            line("Would you like additional help with anything else?", [
                "Yes, I need a confirmation email after resolution.",
                "Please share next steps if the issue returns.",
                "Could you provide a case number for my tracking?",
                "No, this resolves the main issue. Thank you."
            ]),
            line("Thanks for your patience. Your case is now updated.", [
                "Thanks for the support and clear follow-up.",
                "I appreciate the quick resolution.",
                "Great, I'll verify in the app now.",
                "Thanks, this was very helpful."
            ])
        ],
        relatedInterests: ["Technology", "Shopping"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!,
        title: "Store Return",
        description: "Practice requesting a refund or exchange calmly with clear evidence and polite negotiation.",
        category: .restaurant,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("How can I help you at the returns desk today?", [
                "I bought this item yesterday, but a core component is not working.",
                "I would like to return this item because it is fundamentally defective.",
                "I need an exchange because this product fails after charging.",
                "I want to discuss refund options for a faulty purchase."
            ]),
            line("Do you have a receipt or proof of purchase?", [
                "Yes, here is the receipt and payment confirmation.",
                "I have the digital receipt on my phone right here.",
                "I can share my order number and card transaction details.",
                "Yes, I purchased it with my registered profile account."
            ]),
            line("Would you prefer a refund, exchange, or store credit?", [
                "I would prefer an exchange for the exact same model.",
                "A refund to my original payment method is the best option.",
                "Store credit is fine if it can be used immediately.",
                "Could I upgrade and simply pay the difference instead?"
            ]),
            line("I can process that now. Anything else you need?", [
                "Please confirm the return timeline and email me the receipt.",
                "Could you confirm how long the refund usually takes?",
                "Can you note the defect in case the quality team needs details?",
                "No, that covers everything. Thank you for your assistance."
            ]),
            line("Done. Your request has been processed.", [
                "Great, thank you for your help today.",
                "I appreciate the quick support and professionalism.",
                "Thanks for handling this so smoothly.",
                "Perfect, have a good day."
            ])
        ],
        relatedInterests: ["Shopping", "Fashion", "Technology"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "F6F6F6F6-F6F6-F6F6-F6F6-F6F6F6F6F6F6")!,
        title: "Networking",
        description: "Practice introducing yourself, asking meaningful questions, and ending with a clear follow-up.",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 5,
        script: [
            line("Hi, we have not met before. What is your focus area?", [
                "I am focused on development and interested in building new products.",
                "I am exploring roles in analytics and data-driven strategy.",
                "My focus is on communication and broad overall strategy.",
                "I am highly focused on sustainable design and efficiency."
            ]),
            line("What kind of opportunities are you looking for?", [
                "I am looking for roles where I can work on real user problems.",
                "I want experience in cross-functional teams and practical project work.",
                "I am hoping to find strong mentors and entry-level opportunities.",
                "I am interested in specialized assistant roles this year."
            ]),
            line("What projects are you currently proud of?", [
                "I built a small tool that tracks important daily habits.",
                "I led a project where we improved response rates significantly.",
                "I created a portfolio focused primarily on accessibility improvements.",
                "I built a neat dashboard for visualizing participation data."
            ]),
            line("Would you like to stay in touch after this event?", [
                "Yes, I'd appreciate that. We can connect on professional platforms.",
                "Definitely. I'll send a short message with my contact details.",
                "That would be great. Could we set up a short follow-up chat?",
                "Yes, I would definitely like to learn more about your experience."
            ]),
            line("Great meeting you. Any final note before we move on?", [
                "Thanks for the conversation. I'll follow up by tomorrow.",
                "I appreciate your advice and would like to keep in touch.",
                "Great to meet you. I'll share my portfolio link later.",
                "Thanks, this was extremely useful."
            ])
        ],
        relatedInterests: ["Business", "Technology", "Learning"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "A7A7A7A7-A7A7-A7A7-A7A7-A7A7A7A7A7A7")!,
        title: "Giving Advice",
        description: "Practice empathetic listening and practical advice without being dismissive or judgmental.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("I am overwhelmed with my workload. I do not know where to start.", [
                "I'm sorry you're feeling this way. Do you want to talk through what's urgent?",
                "That sounds really hard. Let's break it into smaller steps together.",
                "I hear you. Would it help to prioritize just one task for today?",
                "Thanks for sharing this. You do not have to handle it entirely alone."
            ]),
            line("I keep procrastinating and then panic at night.", [
                "That cycle is exhausting. A short timed block might restart momentum.",
                "Would a simple plan with two realistic goals for today feel manageable?",
                "Maybe we can set a 25-minute focus session and check in after.",
                "Could we remove one non-essential commitment this week to reduce pressure?"
            ]),
            line("I also feel guilty asking for help.", [
                "Asking for help is a sign of strength, not a failure.",
                "You deserve support, especially when the workload is heavy.",
                "Reaching out early can prevent things from becoming much worse.",
                "Many people need support at this stage; you are not alone."
            ]),
            line("What should I do first after this conversation?", [
                "List deadlines, choose the top priority, and start immediately.",
                "Send one message for support and schedule one focused work block.",
                "Prepare a short, actionable plan for tomorrow before going to sleep.",
                "Take a short break, then spend 30 minutes on your highest-impact task."
            ]),
            line("Thanks. Can we check in later this week?", [
                "Absolutely. Let's check in Friday and review what worked.",
                "Of course. Message me tonight after your first work block.",
                "Yes, I'm here for you. We'll adjust the plan together over time.",
                "Definitely. You are doing the exact right thing by taking this step."
            ])
        ],
        relatedInterests: ["Health", "Fitness", "Productivity"]
    ),

    RoleplayScenario(
        id: UUID(uuidString: "B8B8B8B8-B8B8-B8B8-B8B8-B8B8B8B8B8B8")!,
        title: "Fix Confusion",
        description: "Practice resolving misunderstandings in communication with clarity and professionalism.",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            line("There seems to be confusion about who was responsible for yesterday's task.", [
                "I think we had different interpretations. Let's clarify responsibilities now.",
                "I agree, the breakdown wasn't completely clear. How can we fix it?",
                "My understanding was different. Can we review the original plan together?",
                "Let's figure out what dropped so we can get it back on track."
            ]),
            line("I thought you were going to handle the final submission.", [
                "I missed that detail. I'll make sure to confirm next time.",
                "Ah, my mistake. I thought I only needed to do the preliminary review.",
                "I see. Let's create a clear checklist next time so we don't assume.",
                "That wasn't my understanding, but I'll step in and finish it now."
            ]),
            line("Okay, how do we make sure this doesn't happen again?", [
                "At the end of every check-in, we just quickly summarize who is doing what.",
                "Let's use a clear, shared list with assigned owners.",
                "We can always double-check assignments before a major deadline.",
                "I'll be more proactive in asking if anything is ambiguous."
            ]),
            line("Should we use a different tool to track this?", [
                "I think our current tool is fine, we just need to use it consistently.",
                "A shared doc or tracker could help keep us aligned.",
                "Let's just pin the assignments to our chat as a reminder.",
                "Whatever is easiest as long as it clearly shows the owner."
            ]),
            line("Thanks for sorting this out. Everything clear now?", [
                "Yes, perfectly clear. I will handle the pending items.",
                "Yes, and thanks for being understanding about the mix-up.",
                "All good. I appreciate the direct communication.",
                "Yes, I'm on it. Let's sync up again tomorrow."
            ])
        ],
        relatedInterests: ["Business", "Learning", "Productivity"]
    )
]
