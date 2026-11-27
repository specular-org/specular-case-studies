import re, sys
txt = open(sys.argv[1]).read()
# split states
parts = re.split(r'\n(State \d+: [^\n]*)\n', txt)
head = parts[0]
for line in head.splitlines():
    if line.startswith('Error') or 'violated' in line:
        print(line)
prev = {}
i = 1
while i < len(parts):
    hdr = parts[i]; body = parts[i+1] if i+1 < len(parts) else ''
    # stop body at blank line followed by non-/\ text
    lines = body.split('\n')
    cur = {}; key=None
    for ln in lines:
        if ln.startswith('/\\ '):
            m = re.match(r'/\\ (\w+) = (.*)', ln)
            key = m.group(1); cur[key] = m.group(2)
        elif key and ln.startswith('  ') :
            cur[key] += ' ' + ln.strip()
        elif ln.strip()=='' :
            key=None
        else:
            key=None
    print('=== ' + hdr)
    for k,v in cur.items():
        if prev.get(k) != v:
            print('   %s = %s' % (k, v))
    prev = cur
    i += 2
# tail lines
tail = parts[-1].split('\n')
for ln in tail:
    if ln and not ln.startswith('/\\') and not ln.startswith('  '):
        print('TAIL: ' + ln)
