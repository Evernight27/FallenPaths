import os, re
base = r'E:\FallenPaths\fallen-paths'

files_check = [
    'harness/d001/CombatD001SoakRunner.gd',
    'harness/d001/D001PresetRunnerTests.gd',
    'harness/d001/D001Ii5Ii6RunnerTests.gd',
    'harness/d001/D001RunnerHelpers.gd',
    'harness/d001/D001ProbesEnvelopMopup.gd',
    'harness/d001/D001ProbesLinePlug.gd',
    'harness/d001/D001ProbesSparseCloseBand.gd',
    'harness/d001/D001ProbesSparsePostFlee.gd',
]

for rel in files_check:
    path = os.path.join(base, rel)
    with open(path, 'r', newline='') as f:
        lines = f.readlines()

    real_bare_refs = []
    for i, line in enumerate(lines, 1):
        stripped = line.rstrip('\n').rstrip('\r')
        # Skip preload path strings - only check method/property calls (word followed by . and a method name)
        if 'preload(' in stripped:
            continue
        if 'load(' in stripped:
            continue

        # Check for bare D001PresetRunnerTests. or D001Ii5Ii6RunnerTests. NOT on self-class
        cls = rel.split('/')[-1].replace('.gd', '')
        for target_cls in ['D001PresetRunnerTests', 'D001Ii5Ii6RunnerTests']:
            # Self-reference: class calling its own methods - OK
            if target_cls == cls and re.search(r'(?<!\w)' + target_cls + r'\._[a-z]', stripped):
                continue
            # Check for bare refs (no underscore prefix, not in preload/load strings)
            pat = r'(?<![_\w])' + target_cls + r'\.'
            m = re.search(pat, stripped)
            if m:
                real_bare_refs.append('%s:%d: %s (target=%s)' % (rel, i, stripped.strip(), target_cls))

    if real_bare_refs:
        for ref in real_bare_refs:
            print(ref)
    else:
        print('%s: OK - no bare class_name refs' % rel)
