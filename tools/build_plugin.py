#!/usr/bin/env python3
"""Package plugin/ as pkb/praatgen.plugin (a zip). With --check, report
whether the files inside the packaged zip match plugin/. The check compares
contents, not the zip's own bytes, which an upload may recompress."""
import io, os, sys, zipfile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir)
SRC = os.path.join(ROOT, 'plugin')
OUT = os.path.join(ROOT, 'pkb', 'praatgen.plugin')


def build():
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as z:
        for d, _dirs, files in sorted(os.walk(SRC)):
            if '__pycache__' in d.split(os.sep):
                continue
            for fn in sorted(files):
                path = os.path.join(d, fn)
                info = zipfile.ZipInfo(os.path.relpath(path, SRC), (2026, 1, 1, 0, 0, 0))
                info.external_attr = 0o644 << 16
                info.compress_type = zipfile.ZIP_DEFLATED
                with open(path, 'rb') as f:
                    z.writestr(info, f.read())
    return buf.getvalue()


if __name__ == '__main__':
    data = build()
    if '--check' in sys.argv:
        def members(raw):
            with zipfile.ZipFile(io.BytesIO(raw)) as z:
                return {n: z.read(n) for n in z.namelist()}
        current = open(OUT, 'rb').read() if os.path.exists(OUT) else None
        ok = current is not None and members(current) == members(data)
        print('PKB plugin is current' if ok else 'PKB plugin is STALE: run tools/build_plugin.py')
        sys.exit(0 if ok else 1)
    with open(OUT, 'wb') as f:
        f.write(data)
    print(f'wrote pkb/praatgen.plugin ({len(data)} bytes)')
