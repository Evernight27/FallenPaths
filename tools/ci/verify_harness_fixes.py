import os, re

base = r'E:\FallenPaths\fallen-paths'

files_to_check = [
    'harness/d001/CombatD001SoakRunner.gd',
    'harness/d001/D001PresetRunnerTests.gd',
    'harness/d001/D001Ii5Ii6RunnerTests.gd',
    'harness/d001/D001RunnerHelpers.gd',
    'harness/d001/D001ProbesEnvelopMopup.gd',
    'harness/d001/D001ProbesLinePlug.gd',
    'harness/d001/D001ProbesSparseCloseBand.gd',
    'harness/d001/D001ProbesSparsePostFlee.gd',
]

patterns = [
    r'(?<!\w)D001PresetRunnerTests\.',
    r'(?<!\w)D001Ii5Ii6RunnerTests\.',
]

bad_preloads = [
    'preload("res://core/_OpsLog.gd")',
    'preload("res://harness/d001/_D001RunnerHelpers.gd")',
    'preload("res://harness/d001/_D001Ii5Ii6Tests.gd")',
]

for rel in files_to_check:
    path = os.path.join(base, rel)
    with open(path, 'r', newline='') as f:
        content = f.read()

    issues = []
    for pat in patterns:
        matches = list(re.finditer(pat, content))
        if matches:
            issues.append('bare %s: %d occurrences' % (pat, len(matches)))

    for bp in bad_preloads:
        if bp in content:
            issues.append('bad preload path: ' + bp)

    cr_count = content.count('\r')
    if cr_count > 0:
        issues.append('CR characters found: %d' % cr_count)

    status = 'OK' if not issues else 'ISSUES: ' + '; '.join(issues)
    print('%s: %s' % (rel, status))

print()
print('Verification complete.')
