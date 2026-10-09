#!/usr/bin/env python3
"""One-time migration: split Master Prompt 15.1.0 into the 16.0.0 core and
rule files. Every line of 15.1.0 lands in exactly one place, or in the
REPLACED set that the 16.0.0 core rewrites. Kept for provenance.

    python3 tools/split_prompt_v16.py SOURCE_15_1_0.md OUTDIR
Writes OUTDIR/_core_parts/<key>.md (verbatim sections the core includes)
and OUTDIR/pkb/RULES_*.md, then prints a coverage report.
"""
import os
import re
import sys

MAP = [  # (heading prefix, destination)
    ('## CHANGELOG', 'REPLACED'),
    ('## HARD GATE', 'CORE:hard_gate'),
    ('## CHECKPOINTS (hard)', 'REPLACED'),
    ('## STATE PERSISTENCE AND RECOVERY', 'CORE:state'),
    ('## SUBAGENTS', 'CORE:subagents'),
    ('## OUTPUT COMPRESSION', 'RULES_AUDIT.md'),
    ('## PERSONA OVERRIDE', 'CORE:persona'),
    ('## REFERENCE RETRIEVAL PROTOCOL', 'RULES_RETRIEVAL.md'),
    ('## WORKFLOW PROTOCOL', 'REPLACED'),
    ('### STEP 1: MASTER PROMPT RECEIVED', 'REPLACED'),
    ('## YOU MUST PRESENT THIS EXACT RESPONSE', 'CORE:intro'),
    ('### STEP 1B:', 'RULES_PLANNING.md'),
    ('### STEP 2: TASK SPECIFICATION', 'RULES_PLANNING.md'),
    ('### STEP 2A:', 'RULES_MODES.md'),
    ('### STEP 2B:', 'RULES_SANDBOX.md'),
    ('### STEP 2C:', 'RULES_MODES.md'),
    ('### STEP 2D:', 'RULES_MODES.md'),
    ('### STEP 3: CODE GENERATION', 'RULES_PLANNING.md'),
    ('### STEP 4: DEBUGGING LOOP', 'RULES_MODES.md'),
    ('### STEP 5: MODIFICATION REQUESTS', 'RULES_MODES.md'),
    ('## (0) PRE-FLIGHT requirement', 'CORE:preflight'),
    ('### Item ', 'CORE:preflight'),
    ('## Absolute prohibitions', 'CORE:prohibitions'),
    ('## Praat correctness contract', 'RULES_CODE.md'),
    ('### Rule 2:', 'RULES_PLANNING.md'),
    ('### Rule 12:', 'RULES_PLANNING.md'),
    ('### Rule 13:', 'RULES_PLANNING.md'),
    ('### Rule 14:', 'RULES_PLANNING.md'),
    ('### Rule 15:', 'RULES_PLANNING.md'),
    ('### Rule 16:', 'RULES_PLANNING.md'),
    ('### Rule 16B:', 'RULES_PLANNING.md'),
    ('### Rule 17:', 'RULES_PLANNING.md'),
    ('### Rule 22B:', 'RULES_PLANNING.md'),
    ('### Rule 23:', 'RULES_PLANNING.md'),
    ('### Rule 24:', 'RULES_PLANNING.md'),
    ('### Rule 24B:', 'RULES_PLANNING.md'),
    ('### Rule 24C:', 'RULES_SANDBOX.md'),
    ('### Rule 25:', 'RULES_MODES.md'),
    ('### Rule 31:', 'RULES_PLANNING.md'),
    ('### Rule 37:', 'RULES_PLANNING.md'),
    ('### Rule ', 'RULES_CODE.md'),
    ('### Vectorize by default', 'RULES_CODE.md'),
    ('## DEBUGGING INVARIANTS', 'RULES_MODES.md'),
    ('## HOUSE RULES', 'RULES_CODE.md'),
    ('## Ambiguity handling', 'RULES_CODE.md'),
    ('### Explanation integrity', 'RULES_CODE.md'),
    ('### Script header', 'RULES_CODE.md'),
    ('## REFERENCE FILE', 'RULES_RETRIEVAL.md'),
    ('## WORKFLOW PATTERNS', 'RULES_CODE.md'),
    ('### Pattern ', 'RULES_CODE.md'),
    ('## Output format (generation turns)', 'RULES_CODE.md'),
    ('### Header requirement', 'RULES_CODE.md'),
    ('### SELF-AUDIT template', 'RULES_AUDIT.md'),
    ('## COMPLIANCE CANARY', 'CORE:canary'),
]

HEADERS = {
    'RULES_PLANNING.md': ('PLANNING', 'At GO, before the COMMAND PLAN and FUNCTION PLAN (CHECKPOINTS step 1).'),
    'RULES_CODE.md': ('CODE', 'Before writing or changing any .praat file (CHECKPOINTS step 2).'),
    'RULES_AUDIT.md': ('AUDIT', 'Before the SELF-AUDIT (CHECKPOINTS step 3).'),
    'RULES_RETRIEVAL.md': ('REFERENCE RETRIEVAL', 'In Turn 1, before the PRE-FLIGHT, and whenever choosing a reference file.'),
    'RULES_MODES.md': ('MODES', 'When SCAFFOLD, AUTO or DEBUGGING starts, at every debugging turn, and for modification requests.'),
    'RULES_SANDBOX.md': ('SANDBOX', 'Before installing or running Praat, in any mode.'),
}


def dest_for(line):
    for prefix, dest in MAP:
        if line.startswith(prefix):
            return dest
    return None


def main():
    src, outdir = sys.argv[1], sys.argv[2]
    lines = open(src, encoding='utf-8').read().split('\n')
    version = re.search(r'\*\*Version:\*\* (\S+)', '\n'.join(lines[:10])).group(1)
    current = 'PREAMBLE'
    assigned = []
    for ln in lines:
        if re.match(r'^#{2,3} ', ln):
            d = dest_for(ln)
            if d is None:
                sys.exit(f'Unmapped heading: {ln}')
            current = d
        assigned.append(current)
    buckets = {}
    for ln, d in zip(lines, assigned):
        buckets.setdefault(d, []).append(ln)
    os.makedirs(os.path.join(outdir, 'pkb'), exist_ok=True)
    os.makedirs(os.path.join(outdir, '_core_parts'), exist_ok=True)
    for d, body in buckets.items():
        text = '\n'.join(body).strip('\n') + '\n'
        if d.startswith('CORE:'):
            open(os.path.join(outdir, '_core_parts', d[5:] + '.md'), 'w', encoding='utf-8').write(text)
        elif d.startswith('RULES_'):
            title, when = HEADERS[d]
            head = (f'# PRAATGEN RULES — {title}\n\n'
                    f'Part of the PraatGen Master Prompt 16.0.0. Part of EML PraatGen\n'
                    f'GPL-3.0-or-later — Ian Howell, Embodied Music Lab.\n\n'
                    f'**Read this file in full:** {when}\n\n'
                    f'These rules are as binding as the core prompt. Rule, step and phase\n'
                    f'numbers are unchanged from earlier versions; the core prompt\'s rule\n'
                    f'index says which file holds each one. "This prompt" means the core\n'
                    f'together with the six RULES files.\n\n---\n\n')
            open(os.path.join(outdir, 'pkb', d), 'w', encoding='utf-8').write(head + text)
    # coverage
    total = len(lines)
    counts = {d: len(b) for d, b in buckets.items()}
    print(f'source {src} (version {version}), {total} lines')
    for d in sorted(counts):
        n = sum(len(x.encode()) + 1 for x in buckets[d])
        print(f'  {d:28s} {counts[d]:5d} lines {n:7d} bytes')
    assert sum(counts.values()) == total
    print('coverage: every source line assigned exactly once')


if __name__ == '__main__':
    main()
