import os

base = r'E:\FallenPaths\fallen-paths'


def read_binary(path):
    with open(path, 'rb') as f:
        return f.read()


def write_binary(path, data):
    with open(path, 'wb') as f:
        f.write(data)


# === 1. Fix D001ProbesLinePlug.gd bad preload paths + CRLF ===
path = os.path.join(base, 'harness/d001/D001ProbesLinePlug.gd')
raw = read_binary(path)
content = raw.decode('utf-8').replace('\r\n', '\n')

# Fix bad preload path
content = content.replace(
    '_OpsLog := preload("res://core/_OpsLog.gd")',
    '_OpsLog := preload("res://core/OperationalLog.gd")'
)

write_binary(path, content.encode('utf-8'))
print('6. D001ProbesLinePlug.gd - fixed bad preload + CRLF')


# === 2. Fix CRLF in all harness d001 files (skip ones already clean) ===
crlf_files = [
    'harness/d001/D001Ii5Ii6RunnerTests.gd',
    'harness/d001/D001RunnerHelpers.gd',
    'harness/d001/D001ProbesEnvelopMopup.gd',
    'harness/d001/D001ProbesSparseCloseBand.gd',
    'harness/d001/D001ProbesSparsePostFlee.gd',
]

for rel in crlf_files:
    path = os.path.join(base, rel)
    raw = read_binary(path)
    content = raw.decode('utf-8').replace('\r\n', '\n')
    write_binary(path, content.encode('utf-8'))
    print('%s - CRLF fixed' % rel)


# === 3. Fix D001Ii5Ii6RunnerTests.gd self-references ===
# Self-references to D001Ii5Ii6RunnerTests are OK (it IS that class), but we need to check
# if there are refs TO OTHER classes that still use bare names.

path = os.path.join(base, 'harness/d001/D001Ii5Ii6RunnerTests.gd')
with open(path, 'r', newline='') as f:
    content = f.read()

# Self-references like D001Ii5Ii6RunnerTests._start_manager are fine - that's self
# The file already has _D001PresetRunnerTests preload from step 3 above
# Let's verify the _D001PresetRunnerTests usage is correct
if '_D001PresetRunnerTests.' in content:
    print('D001Ii5Ii6RunnerTests.gd: has _D001PresetRunnerTests refs')

print()
print('All fixes applied.')
