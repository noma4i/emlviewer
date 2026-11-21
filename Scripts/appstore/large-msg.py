import math
import struct


def write_message(ns, root, path):
    free, end, fat_sector = ns['FREESECT'], ns['ENDOFCHAIN'], ns['FATSECT']
    nodes = ns['assign_dir_indices'](root)
    mini = bytearray()
    mini_fat = []
    large = []
    for node in nodes:
        if node.obj_type != ns['OBJ_STREAM']:
            continue
        if len(node.payload) >= 4096:
            large.append(node)
            continue
        node.mini_start = len(mini) // 64
        count = max(1, math.ceil(len(node.payload) / 64))
        mini_fat.extend([node.mini_start + i + 1 for i in range(count - 1)] + [end])
        mini.extend(node.payload.ljust(count * 64, b'\0'))
    mini_bytes = bytes(mini)
    mini_fat.extend([free] * ((-len(mini_fat)) % 128))
    mini_fat_bytes = b''.join(struct.pack('<I', n) for n in mini_fat)
    directory_count = math.ceil(len(nodes) * 128 / 512)
    mini_fat_count = len(mini_fat_bytes) // 512
    mini_count = math.ceil(len(mini_bytes) / 512)
    payload_counts = [math.ceil(len(node.payload) / 512) for node in large]
    data_count = directory_count + mini_fat_count + mini_count + sum(payload_counts)
    fat_count = 1
    while fat_count * 128 < data_count + fat_count:
        fat_count += 1
    directory_start = fat_count
    mini_fat_start = directory_start + directory_count
    mini_start = mini_fat_start + mini_fat_count
    next_sector = mini_start + mini_count
    for node, count in zip(large, payload_counts):
        node.large_start = next_sector
        next_sector += count
    fat = [free] * (fat_count * 128)
    for i in range(fat_count):
        fat[i] = fat_sector
    def chain(start, count):
        for i in range(count):
            fat[start + i] = start + i + 1 if i + 1 < count else end
    chain(directory_start, directory_count)
    chain(mini_fat_start, mini_fat_count)
    chain(mini_start, mini_count)
    for node, count in zip(large, payload_counts):
        chain(node.large_start, count)
    links = {}
    children = {}
    for node in nodes:
        if node.obj_type in (ns['OBJ_ROOT'], ns['OBJ_STORAGE']):
            pairs, child = ns['rb_links'](len(node.children))
            children[node] = node.children[child].dir_index if child != ns['NOSTREAM'] else ns['NOSTREAM']
            for child_node, (left, right) in zip(node.children, pairs):
                links[child_node] = (node.children[left].dir_index if left != ns['NOSTREAM'] else left,
                                     node.children[right].dir_index if right != ns['NOSTREAM'] else right)
    entries = []
    for node in nodes:
        left, right = links.get(node, (ns['NOSTREAM'], ns['NOSTREAM']))
        if node.obj_type == ns['OBJ_ROOT']:
            start, size = mini_start, len(mini_bytes)
        elif node.obj_type == ns['OBJ_STREAM']:
            start = node.large_start if len(node.payload) >= 4096 else node.mini_start
            size = len(node.payload)
        else:
            start, size = 0, 0
        entries.append(ns['build_dir_entry'](node.name, node.obj_type, left=left, right=right,
                       child=children.get(node, ns['NOSTREAM']), start_sector=start, size=size))
    header = ns['build_header'](dir_start=directory_start, fat_sectors=list(range(fat_count)),
                                mini_fat_start=mini_fat_start, mini_fat_count=mini_fat_count)
    fat_bytes = b''.join(struct.pack('<I', n) for n in fat)
    directory = b''.join(entries).ljust(directory_count * 512, b'\0')
    payloads = b''.join(node.payload.ljust(count * 512, b'\0') for node, count in zip(large, payload_counts))
    path.write_bytes(header + fat_bytes + directory + mini_fat_bytes + mini_bytes.ljust(mini_count * 512, b'\0') + payloads)
