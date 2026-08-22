import os

base = r'E:\FallenPaths\fallen-paths'


def write_file(path, content):
    with open(path, 'w', newline='\n') as f:
        f.write(content)


# === 1. CombatD001SoakRunner.gd ===
path = os.path.join(base, 'harness/d001/CombatD001SoakRunner.gd')
with open(path, 'r', newline='') as f:
    content = f.read()

lines = content.split('\n')
# Remove the _D001PresetRunnerTests preload line
new_lines = []
for line in lines:
    if 'const _D001PresetRunnerTests := preload' in line:
        continue
    new_lines.append(line)

# Find FallenPathsErrorLogger line to insert after
insert_after = None
for i, line in enumerate(new_lines):
    if 'FallenPathsErrorLogger := preload' in line:
        insert_after = i
        break

if insert_after is not None:
    block = [
        '',
        '\tstatic var _preset_runner_cls: Variant = null',
        '',
        '\tstatic func _ensure_preset_runner() -> Variant:',
        "\t\tif _preset_runner_cls == null:",
        '\t\t\t_preset_runner_cls = load("res://harness/d001/D001PresetRunnerTests.gd")',
        '\treturn _preset_runner_cls',
    ]
    new_lines[insert_after+1:insert_after+1] = block

content = '\n'.join(new_lines)

# Replace all remaining _D001PresetRunnerTests. with _ensure_preset_runner().
content = content.replace('_D001PresetRunnerTests.', '_ensure_preset_runner().')

write_file(path, content)
print('1. CombatD001SoakRunner.gd done')


# === 2. D001PresetRunnerTests.gd ===
path = os.path.join(base, 'harness/d001/D001PresetRunnerTests.gd')
with open(path, 'r', newline='') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
for line in lines:
    # Replace D001Ii5Ii6RunnerTests. with _D001Ii5Ii6Tests. (self-refs on D001PresetRunnerTests stay)
    if 'D001Ii5Ii6RunnerTests.' in line:
        line = line.replace('D001Ii5Ii6RunnerTests.', '_D001Ii5Ii6Tests.')
    new_lines.append(line)

content = '\n'.join(new_lines)
write_file(path, content)
print('2. D001PresetRunnerTests.gd done')


# === 3. D001Ii5Ii6RunnerTests.gd ===
path = os.path.join(base, 'harness/d001/D001Ii5Ii6RunnerTests.gd')
with open(path, 'r', newline='') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
for line in lines:
    # Fix preload paths
    if '_OpsLog := preload("res://core/_OpsLog.gd")' in line:
        line = 'const _OpsLog := preload("res://core/OperationalLog.gd")'
    if '_D001RunnerHelpers := preload("res://harness/d001/_D001RunnerHelpers.gd")' in line:
        line = 'const _D001RunnerHelpers := preload("res://harness/d001/D001RunnerHelpers.gd")'

    # Replace bare D001PresetRunnerTests. with _D001PresetRunnerTests. (need to add preload later)
    if 'D001PresetRunnerTests.' in line and '_D001PresetRunnerTests.' not in line:
        line = line.replace('D001PresetRunnerTests.', '_D001PresetRunnerTests.')

    new_lines.append(line)

content = '\n'.join(new_lines)

# Add preload for _D001PresetRunnerTests after existing preloads
preload_block_added = False
new_lines = content.split('\n')
result_lines = []
for line in new_lines:
    result_lines.append(line)
    if 'const _D001RunnerHelpers := preload("res://harness/d001/D001RunnerHelpers.gd")' in line and not preload_block_added:
        result_lines.append('const _D001PresetRunnerTests := preload("res://harness/d001/D001PresetRunnerTests.gd")')
        preload_block_added = True

content = '\n'.join(result_lines)
write_file(path, content)
print('3. D001Ii5Ii6RunnerTests.gd done')


# === 4. D001RunnerHelpers.gd ===
path = os.path.join(base, 'harness/d001/D001RunnerHelpers.gd')
with open(path, 'r', newline='') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
for line in lines:
    # Replace bare D001PresetRunnerTests. with _D001PresetRunnerTests. (need to add preload)
    if 'D001PresetRunnerTests.' in line and '_D001PresetRunnerTests.' not in line:
        line = line.replace('D001PresetRunnerTests.', '_D001PresetRunnerTests.')
    new_lines.append(line)

content = '\n'.join(new_lines)

# Add preload for _D001PresetRunnerTests after existing preloads
preload_block_added = False
new_lines = content.split('\n')
result_lines = []
for line in new_lines:
    result_lines.append(line)
    if 'const _D001Ii5Ii6Tests := preload("res://harness/d001/D001Ii5Ii6RunnerTests.gd")' in line and not preload_block_added:
        result_lines.append('const _D001PresetRunnerTests := preload("res://harness/d001/D001PresetRunnerTests.gd")')
        preload_block_added = True

content = '\n'.join(result_lines)
write_file(path, content)
print('4. D001RunnerHelpers.gd done')


# === 5. D001ProbesEnvelopMopup.gd ===
path = os.path.join(base, 'harness/d001/D001ProbesEnvelopMopup.gd')
with open(path, 'r', newline='') as f:
    content = f.read()

# Fix the broken preload path for _D001Ii5Ii6Tests (has wrong underscore + missing filename)
content = content.replace(
    'const _D001Ii5Ii6Tests := preload("res://harness/d001/_D001Ii5Ii6Tests.gd")',
    'const _D001Ii5Ii6Tests := preload("res://harness/d001/D001Ii5Ii6RunnerTests.gd")'
)

write_file(path, content)
print('5. D001ProbesEnvelopMopup.gd done')


# === 6. D001ProbesLinePlug.gd ===
path = os.path.join(base, 'harness/d001/D001ProbesLinePlug.gd')
with open(path, 'r', newline='') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
for line in lines:
    # Fix preload paths
    if '_OpsLog := preload("res://core/_OpsLog.gd")' in line:
        line = 'const _OpsLog := preload("res://core/OperationalLog.gd")'
    if '_D001RunnerHelpers := preload("res://harness/d001/_D001RunnerHelpers.gd")' in line:
        line = 'const _D001RunnerHelpers := preload("res://harness/d001/D001RunnerHelpers.gd")'

    # Replace bare class_name refs - OperationalLog. (not _OpsLog.)
    if 'OperationalLog.' in line and '_OpsLog.' not in line:
        line = line.replace('OperationalLog.', '_OpsLog.')

    # D001Ii5Ii6RunnerTests. -> _D001Ii5Ii6Tests. (need preload)
    if 'D001Ii5Ii6RunnerTests.' in line and '_D001Ii5Ii6Tests.' not in line:
        line = line.replace('D001Ii5Ii6RunnerTests.', '_D001Ii5Ii6Tests.')

    # D001PresetRunnerTests. -> _D001PresetRunnerTests. (need preload)
    if 'D001PresetRunnerTests.' in line and '_D001PresetRunnerTests.' not in line:
        line = line.replace('D001PresetRunnerTests.', '_D001PresetRunnerTests.')

    new_lines.append(line)

content = '\n'.join(new_lines)

# Add preloads for _D001Ii5Ii6Tests and _D001PresetRunnerTests after existing preloads
preload_block_added_i = False
preload_block_added_p = False
new_lines = content.split('\n')
result_lines = []
for line in new_lines:
    result_lines.append(line)
    if 'const _D001RunnerHelpers := preload("res://harness/d001/D001RunnerHelpers.gd")' in line and not preload_block_added_i:
        result_lines.append('const _D001Ii5Ii6Tests := preload("res://harness/d001/D001Ii5Ii6RunnerTests.gd")')
        preload_block_added_i = True
    if 'const _D001Ii5Ii6Tests := preload("res://harness/d001/D001Ii5Ii6RunnerTests.gd")' in line and not preload_block_added_p:
        result_lines.append('const _D001PresetRunnerTests := preload("res://harness/d001/D001PresetRunnerTests.gd")')
        preload_block_added_p = True

content = '\n'.join(result_lines)
write_file(path, content)
print('6. D001ProbesLinePlug.gd done')


# === 7. D001ProbesSparseCloseBand.gd ===
path = os.path.join(base, 'harness/d001/D001ProbesSparseCloseBand.gd')
with open(path, 'r', newline='') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
for line in lines:
    # Fix preload paths
    if '_OpsLog := preload("res://core/_OpsLog.gd")' in line:
        line = 'const _OpsLog := preload("res://core/OperationalLog.gd")'
    if '_D001RunnerHelpers := preload("res://harness/d001/_D001RunnerHelpers.gd")' in line:
        line = 'const _D001RunnerHelpers := preload("res://harness/d001/D001RunnerHelpers.gd")'

    # D001Ii5Ii6RunnerTests. -> _D001Ii5Ii6Tests. (need preload)
    if 'D001Ii5Ii6RunnerTests.' in line and '_D001Ii5Ii6Tests.' not in line:
        line = line.replace('D001Ii5Ii6RunnerTests.', '_D001Ii5Ii6Tests.')

    # D001PresetRunnerTests. -> _D001PresetRunnerTests. (need preload)
    if 'D001PresetRunnerTests.' in line and '_D001PresetRunnerTests.' not in line:
        line = line.replace('D001PresetRunnerTests.', '_D001PresetRunnerTests.')

    new_lines.append(line)

content = '\n'.join(new_lines)

# Add preloads
preload_block_added_i = False
preload_block_added_p = False
new_lines = content.split('\n')
result_lines = []
for line in new_lines:
    result_lines.append(line)
    if 'const _D001RunnerHelpers := preload("res://harness/d001/D001RunnerHelpers.gd")' in line and not preload_block_added_i:
        result_lines.append('const _D001Ii5Ii6Tests := preload("res://harness/d001/D001Ii5Ii6RunnerTests.gd")')
        preload_block_added_i = True
    if 'const _D001Ii5Ii6Tests := preload("res://harness/d001/D001Ii5Ii6RunnerTests.gd")' in line and not preload_block_added_p:
        result_lines.append('const _D001PresetRunnerTests := preload("res://harness/d001/D001PresetRunnerTests.gd")')
        preload_block_added_p = True

content = '\n'.join(result_lines)
write_file(path, content)
print('7. D001ProbesSparseCloseBand.gd done')


# === 8. D001ProbesSparsePostFlee.gd ===
path = os.path.join(base, 'harness/d001/D001ProbesSparsePostFlee.gd')
with open(path, 'r', newline='') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
for line in lines:
    # Fix preload paths
    if '_OpsLog := preload("res://core/_OpsLog.gd")' in line:
        line = 'const _OpsLog := preload("res://core/OperationalLog.gd")'
    if '_D001RunnerHelpers := preload("res://harness/d001/_D001RunnerHelpers.gd")' in line:
        line = 'const _D001RunnerHelpers := preload("res://harness/d001/D001RunnerHelpers.gd")'

    # D001Ii5Ii6RunnerTests. -> _D001Ii5Ii6Tests. (need preload)
    if 'D001Ii5Ii6RunnerTests.' in line and '_D001Ii5Ii6Tests.' not in line:
        line = line.replace('D001Ii5Ii6RunnerTests.', '_D001Ii5Ii6Tests.')

    # D001PresetRunnerTests. -> _D001PresetRunnerTests. (need preload)
    if 'D001PresetRunnerTests.' in line and '_D001PresetRunnerTests.' not in line:
        line = line.replace('D001PresetRunnerTests.', '_D001PresetRunnerTests.')

    new_lines.append(line)

content = '\n'.join(new_lines)

# Add preloads
preload_block_added_i = False
preload_block_added_p = False
new_lines = content.split('\n')
result_lines = []
for line in new_lines:
    result_lines.append(line)
    if 'const _D001RunnerHelpers := preload("res://harness/d001/D001RunnerHelpers.gd")' in line and not preload_block_added_i:
        result_lines.append('const _D001Ii5Ii6Tests := preload("res://harness/d001/D001Ii5Ii6RunnerTests.gd")')
        preload_block_added_i = True
    if 'const _D001Ii5Ii6Tests := preload("res://harness/d001/D001Ii5Ii6RunnerTests.gd")' in line and not preload_block_added_p:
        result_lines.append('const _D001PresetRunnerTests := preload("res://harness/d001/D001PresetRunnerTests.gd")')
        preload_block_added_p = True

content = '\n'.join(result_lines)
write_file(path, content)
print('8. D001ProbesSparsePostFlee.gd done')

print('All files processed.')
