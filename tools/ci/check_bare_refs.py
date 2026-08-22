import os, re
base = r'E:\FallenPaths\fallen-paths'

files_check = [
    ('harness/d001/CombatD001SoakRunner.gd', 'D001PresetRunnerTests'),
    ('harness/d001/D001Ii5Ii6RunnerTests.gd', 'D001PresetRunnerTests'),
    ('harness/d001/D001Ii5Ii6RunnerTests.gd', 'D001Ii5Ii6RunnerTests'),
    ('harness/d001/D001RunnerHelpers.gd', 'D001PresetRunnerTests'),
    ('harness/d001/D001RunnerHelpers.gd', 'D001Ii5Ii6RunnerTests'),
    ('harness/d001/D001ProbesEnvelopMopup.gd', 'D001Ii5Ii6RunnerTests'),
    ('harness/d001/D001ProbesLinePlug.gd', 'D001Ii5Ii6RunnerTests'),
    ('harness/d001/D001ProbesSparseCloseBand.gd', 'D001Ii5Ii6RunnerTests'),
    ('harness/d001/D001ProbesSparsePostFlee.gd', 'D001Ii5Ii6RunnerTests'),
]

for rel, cls in files_check:
    path = os.path.join(base, rel)
    with open(path, 'r', newline='') as f:
        lines = f.readlines()
    for i, line in enumerate(lines, 1):
        stripped = line.rstrip('\n').rstrip('\r')
        if re.search(r'(?<!\w)' + cls + r'\.', stripped):
            # Check if it's actually bare (no underscore prefix)
            check = stripped.replace('_D001PresetRunnerTests.', '').replace('_D001Ii5Ii6Tests.', '')
            if cls + '.' in check:
                print('%s:%d: %s' % (rel, i, stripped))
