#!/usr/bin/env python3
"""Smoke run of the 0.6.0 hook (in the maintainer's test build,
praatgen-plugin-usagelog/) on this machine's own session transcripts, read
only. For each transcript it runs the turn-end hook once, with the log in a
temporary folder that is deleted afterwards, and counts: how many sessions the
hook takes for PraatGen sessions, runs that printed anything (the hook never
should), error lines, and whether the usage lines (measured for every session
here) sum to the last usage of each message id. It prints counts only; nothing
from a transcript is printed or kept.

    python3 smoke_local_transcripts.py [--plugin DIR] [--transcripts DIR]
"""
import argparse, collections, contextlib, glob, importlib.util, io, json, os, shutil, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.dont_write_bytecode = True                  # nothing written into the plugin
ap = argparse.ArgumentParser()
ap.add_argument('--plugin', default=os.path.join(HERE, os.pardir, 'plugin-usagelog'))
ap.add_argument('--transcripts', default='/root/.claude/projects')
ARGS = ap.parse_args()
TMP = tempfile.mkdtemp(prefix='smoke_060_')

os.environ['CLAUDE_PLUGIN_ROOT'] = os.path.abspath(ARGS.plugin)
spec = importlib.util.spec_from_file_location('hook', os.path.join(ARGS.plugin, 'hooks', 'rules_check.py'))
H = importlib.util.module_from_spec(spec)
spec.loader.exec_module(H)
LOG = os.path.join(TMP, 'usage.log')
H.LOGS, H.TRANSCRIPT_TRIES, H.USAGE_SESSIONS = (LOG,), 1, ('praatgen', 'other')

paths = sorted(glob.glob(os.path.join(ARGS.transcripts, '**', '*.jsonl'), recursive=True))
count = collections.Counter()
for k, path in enumerate(paths):
    with contextlib.suppress(FileNotFoundError):
        os.remove(LOG)
    data = {'session_id': f'smoke-{k:04d}', 'transcript_path': path}
    out = io.StringIO()
    argv, stdin = sys.argv, sys.stdin
    sys.argv, sys.stdin = ['rules_check.py', 'stop'], io.StringIO(json.dumps(data))
    try:
        with contextlib.redirect_stdout(out):
            H.main()
    finally:
        sys.argv, sys.stdin = argv, stdin
    rows = []
    if os.path.exists(LOG):
        rows = [json.loads(l.split(' ', 1)[1]) for l in open(LOG).read().splitlines()]
    entries, _ = H.load(path)
    kind = H.classify(entries)
    count[f'sessions: {kind}'] += 1
    count['runs that printed'] += bool(out.getvalue())
    count['usage error lines'] += sum(r['kind'] == 'error' for r in rows)
    if kind not in H.USAGE_SESSIONS:                # turned off: logged only while on, so sums aren't compared
        continue
    last = {}
    for e in entries:
        m = e.get('message')
        if e.get('type') == 'assistant' and isinstance(m, dict) and m.get('id') and isinstance(m.get('usage'), dict):
            last[m['id']] = m['usage']
    if not last:
        count['transcripts with no usage'] += 1
        continue
    want = {u: sum(int(v.get(u) or 0) for v in last.values()) for u in H.USAGE}
    calls = [r for r in rows if r['kind'] == 'call']
    turns = [r for r in rows if r['kind'] == 'turn']
    ok = (len(calls) == len(last)
          and all(sum(r[u] for r in calls) == want[u] for u in H.USAGE)
          and all(sum(r[u] for r in turns) == want[u] for u in H.USAGE))
    count['usage sums match' if ok else 'usage sums DIFFER'] += 1
shutil.rmtree(TMP, ignore_errors=True)
print(f'{len(paths)} transcripts')
for key in sorted(count):
    print(f'  {key}: {count[key]}')
sys.exit(1 if count['runs that printed'] or count['usage sums DIFFER'] or count['usage error lines'] else 0)
