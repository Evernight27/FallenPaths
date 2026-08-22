import os, re
base = r'E:\FallenPaths\fallen-paths'

# Check D001Ii5Ii6RunnerTests.gd - self-references are fine
# The real issue is that _start_manager etc. ARE on the same class so self-refs are OK
# But let's check: does this file have a preload for itself? No, it IS the class_name D001Ii5Ii6RunnerTests
# So self-references like D001Ii5Ii6RunnerTests._start_manager() are correct - they're calling own static methods

# Check actual bare refs that should use underscore-prefixed constants:
# In D001Ii5Ii6RunnerTests.gd, references TO OTHER classes need preloads+underscores
# But self-references (to D001Ii5Ii6RunnerTests itself) are fine

# Check CR characters in files processed by the script
files_check = [
    'harness/d001/D001Ii5Ii6RunnerTests.gd',
    'harness/d001/D001RunnerHelpers.gd',
    'harness/d001/D001ProbesEnvelopMopup.gd',
    'harness/d001/D001ProbesLinePlug.gd',
    'harness/d001/D001ProbesSparseCloseBand.gd',
    'harness/d001/D001ProbesSparsePostFlee.gd',
]

for rel in files_check:
    path = os.path.join(base, rel)
    with open(path, 'rb') as f:
        raw = f.read()
    cr_count = raw.count(b'\r')
    lf_count = raw.count(b'\n')
    print('%s: CR=%d LF=%d' % (rel, cr_count, lf_count))

# Check bad preload paths specifically
bad_preloads_to_check = [
    'harness/d001/D001Ii5Ii6RunnerTests.gd',
    'harness/d001/D001ProbesLinePlug.gd',
]
for rel in bad_preloads_to_check:
    path = os.path.join(base, rel)
    with open(path, 'r', newline='') as f:
        content = f.read()
    if '_OpsLog := preload("res://core/_OpsLog.gd")' in content:
        print('%s: BAD _OpsLog preload path found!' % rel)
    if '_D001RunnerHelpers := preload("res://harness/d001/_D001RunnerHelpers.gd")' in content:
        print('%s: BAD _D001RunnerHelpers preload path found!' % rel)
