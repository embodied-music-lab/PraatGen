# EML Praat Assistant — Handoff Document Template
#
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab
#
# Referenced by: Master Prompt Step 4 (Debugging Loop, Context budget awareness)
# Generated on: HANDOFF command during debugging sessions
#
# The handoff document is the **sole bridge** between sessions. It must
# pass this test: *Could someone unfamiliar with the session history
# resume all active work from this document alone, without access to
# the conversation transcript?*
#
# If the answer is no, the handoff is incomplete. Add what is missing
# before delivering it.

## Format

    # EML Praat Assistant — Session Handoff
    # [Session title or topic]
    # Date: [date]
    # Session type: [Debugging / Development / Design / Audit / Mixed]

    ## 1. Project State (all active workstreams)

    For EVERY workstream touched this session OR known to be in
    progress, state:

    ### [Workstream name] — [status: Active / Blocked / Complete]
    - **Current version:** [version number or "draft"]
    - **Location:** [filename in outputs, or "not yet generated"]
    - **What it does:** [one sentence]
    - **Current state:** [what works, what doesn't, where it stopped]
    - **Next step:** [the specific next action required]
    - **Blockers:** [what prevents progress, or "none"]

    Workstreams include scripts under development, tutorial modules,
    knowledge base files, prompt revisions, research protocols, and
    any other deliverable the project is tracking.

    Do not omit workstreams that were not touched this session if
    they are known to be active. State: "Not addressed this session.
    Last known state: [summary]."

    ## 2. Session Deliverables

    List every file produced or modified this session:

    | File | Action | Description |
    |------|--------|-------------|
    | [filename] | [Created / Modified / Corrected] | [what it is] |

    If a deliverable contains substantive content (e.g., a 300-line
    tutorial module draft, a scaffold design, a procedure library),
    state its structure and key design decisions here — do not assume
    the next session will have access to the file contents.

    ## 3. Design Decisions

    Document decisions made this session that affect future work.
    Each entry must include the decision, the alternatives considered,
    and the rationale:

    - **[Decision]:** [What was decided]
      - Alternatives: [what else was considered]
      - Rationale: [why this choice]

    If no design decisions were made, state: "No design decisions
    this session."

    ## 4. Current Script (if debugging)

    [complete script at latest version, or "No script under
    active debugging"]

    ## 5. Issue History (if debugging)

    [numbered list of errors reported and fixes applied, or
    "No debugging this session"]

    ## 6. Outstanding Issues and TODOs

    [any unresolved problems, pending verifications, or new TODO
    items generated — each with enough context to act on without
    the session transcript]

    ## 7. Commands and Corrections

    - **New commands verified:** [list for WHITELIST_CURRENT.txt,
      or "none"]
    - **Knowledge base corrections:** [errata discovered, or "none"]
    - **Prompt revisions:** [changes to master prompt text, or "none"]

    ## 8. Resumption Instructions

    State the specific next action for each active workstream:

    "Resuming from handoff. Active workstreams:
    - [Workstream 1]: [specific next action]
    - [Workstream 2]: [specific next action]
    
    Upload [list files needed] to continue."

## Self-Containment Checklist (hard)

Before delivering the handoff, verify:
1. Every active workstream is listed with current state
2. Every deliverable is described with enough detail to understand
   its contents without opening it
3. Every design decision is documented with rationale
4. Every TODO is actionable without reference to the session transcript
5. The resumption instructions name specific files to upload

If any item fails, revise the handoff before delivering.
