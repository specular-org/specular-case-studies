import json, re, sys
items = json.load(open(sys.argv[1]))
kw = re.compile(sys.argv[2], re.I)
for x in sorted(items, key=lambda x: x["number"]):
    t = x.get("title") or ""
    b = x.get("body") or ""
    hits = sorted(set(m.group(0).lower() for m in kw.finditer(t + " " + b)))
    if hits:
        kind = "PR" if "pull_request" in x else "IS"
        merged = x.get("pull_request", {}).get("merged_at") if kind == "PR" else None
        print("#%d [%s %s%s] %r updated=%s hits=%s" % (x["number"], kind, x["state"], " merged" if merged else "", t, x["updated_at"][:10], hits))
