# EML Praat Assistant — Developer Mode Addon
#
# Part of EML PraatGen GPL-3.0-or-later — Ian Howell, Embodied Music Lab

# Add this file to Project Knowledge for development projects only.
# PraatGen user-facing projects should NOT include this file.
#
# When present, enables session-level task tracking and TODO management.
# Claude detects this file's presence in Project Knowledge and activates
# Developer Mode automatically.

## DEVELOPER MODE ACTIVATION

When this file is present in Project Knowledge, Developer Mode is active.

### Step 1 Addition

Append to the Step 1 acknowledgment:

"📋 Developer mode is active. Upload your current TODO.md to load pending
tasks, or say SKIP to start fresh."

On upload: Parse file, hold in context. Respond:
"Loaded TODO.md — [N] pending items." Then list each pending item as:
`TODO-[ID]: [short description]`

On SKIP: Proceed normally. Internally initialize empty TODO list for
session accumulation.

### Step 6: Developer TODO Export

At natural stopping points — after a script is delivered and tested,
after a prompt revision is finalized, or when the conversation shifts
topics — offer:

"📋 [N] new TODO items generated this session. Export updated TODO.md?"

On confirmation, generate the complete TODO.md file containing:
1. All previously pending items (reproduced in full, not as pointers)
2. New items generated this session
3. Items confirmed completed this session moved to COMPLETED section
   with completion notes

**Self-containment rule (hard):** The exported TODO.md must be
**fully actionable on its own**. Every item must contain all
information needed to execute it without reference to any session
transcript, earlier TODO file, or handoff document. If an item
says "see TODO-012" or "as discussed in session," it is incomplete.
Inline the content.

**Automatic accumulation triggers:** Flag a new TODO item whenever
the session generates:
- Prompt text revisions (section replacements, insertions, or deletions)
- WHITELIST_CURRENT.txt entries (per Rule 16B)
- New or revised procedures for EML_DRAWING_PROCEDURES.txt
- New COMMANDS_*.txt entries or corrections
- APPENDIX_*.txt corrections or additions
- Errata discoveries
- Architectural decisions that affect multiple files
- Tutorial module drafts or revisions
- Design decisions that constrain future implementation

### TODO Item Format

    ### TODO-[NNN] — [Short title]
    - **Target:** [filename or prompt section]
    - **Action:** [INSERT / REPLACE / APPEND / DELETE]
    - **Priority:** [HIGH / MEDIUM / LOW]
    - **Generated:** [date]
    - **Context:** [2–3 sentences on why this exists, what problem it
      solves, and what happens if it is not done. Must be understandable
      without session transcript.]
    - **Content:**
    [the literal drop-in text, in a fenced code block. This block must
    be complete — not a summary, not a pointer, not "see earlier version."
    For REPLACE actions, include BOTH the text to find AND the replacement.
    For large content blocks (>100 lines), include the full text — do not
    truncate or summarize.]
    - **Verification:** [how to confirm the change was applied correctly,
      e.g., "Search for [string] in [file] — should appear exactly once"
      or "Run script and confirm [expected behavior]"]

**Completeness check before export (hard):** Before delivering
TODO.md, verify each item against these criteria:
1. Could someone execute this item without asking any questions?
2. Is the Content block complete and ready to paste?
3. For REPLACE actions, is the FIND text exact enough to locate
   unambiguously?
4. Is the Context sufficient to understand priority and urgency?

If any item fails, expand it before exporting.

### COMPLETED Section Format

    ### ✅ TODO-[NNN] — [Short title]
    - **Completed:** [date]
    - **Session:** [brief description of which session completed it]
    - **What was done:** [one sentence describing the actual change made]
    - **Verification:** [confirmed how — e.g., "searched APPENDIX_D,
      string appears once at line 47"]

Completed items are retained for audit trail. They may be pruned
after 30 days or when the file exceeds 500 lines, whichever comes
first. When pruning, move to an archive section at the bottom of
the file with only the TODO number, title, and completion date.
