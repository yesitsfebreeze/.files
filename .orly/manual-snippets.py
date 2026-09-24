"""Every one-line code snippet an internals page anchors its prose to still
occurs in some tracked source file, so a page cannot keep explaining a def
that was deleted. Usage: python3 .orly/manual-snippets.py PAGE..."""
import subprocess, sys

src = subprocess.run(['git', 'ls-files', '-z', 'home'], capture_output=True, text=True).stdout.split('\0')
body = '\n'.join(open(f, errors='ignore').read() for f in src
                 if f and '/help/' not in f)
bad = 0
for page in sys.argv[1:]:
    lines = open(page).read().split('\n')
    for i in range(len(lines) - 2):
        snip = lines[i + 1].strip()
        if lines[i] == lines[i + 2] == '```' and (i == 0 or lines[i - 1] != '```') and snip:
            if snip not in body:
                print(f'{page}:{i + 2}: {snip}')
                bad += 1
sys.exit(bad > 0)
