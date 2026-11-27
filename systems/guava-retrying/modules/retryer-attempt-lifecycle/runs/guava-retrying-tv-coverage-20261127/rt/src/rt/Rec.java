package rt;

import java.io.FileWriter;
import java.io.IOException;
import java.lang.reflect.Field;
import java.util.*;

/**
 * Real-HotSpot recorder for the TV high-coverage experiment (Limiter = None
 * configurations). The library is unmodified: events come from the user-side
 * extension points (callable, listener) and from thin wrappers around the
 * built-in stop / wait / block strategies. Each event carries an interval
 * [start, end] (System.nanoTime) that contains its base.tla commit point.
 */
public final class Rec {
    public static final class Ev {
        final LinkedHashMap<String, Object> f = new LinkedHashMap<>();
        final Set<String> pending = new HashSet<>();
        public Ev put(String k, Object v) { f.put(k, v); pending.remove(k); return this; }
        public Ev open(String k) { pending.add(k); return this; }
        public Ev end(long t) { f.put("end", t); pending.remove("end"); return this; }
    }

    static final long T0 = System.nanoTime();
    static final List<Ev> events = Collections.synchronizedList(new ArrayList<>());
    public static volatile boolean invalid;
    public static volatile String invalidWhy = "";

    public static long now() { return System.nanoTime() - T0; }

    public static Ev ev(String name, String tid, long start, long end) {
        Ev e = new Ev();
        e.f.put("tag", "trace");
        e.f.put("event", name);
        e.f.put("tid", tid);
        e.f.put("start", start);
        if (end >= 0) e.f.put("end", end); else e.open("end");
        events.add(e);
        return e;
    }

    public static void invalidate(String why) { invalid = true; invalidWhy = why; }

    /** Reflection read of a field (Retryer.listeners, ArrayList.modCount / size). */
    public static Object field(Object o, Class<?> c, String name) {
        try {
            Field f = c.getDeclaredField(name);
            f.setAccessible(true);
            return f.get(o);
        } catch (ReflectiveOperationException ex) {
            throw new RuntimeException(ex);
        }
    }

    static String json(Object v) {
        if (v == null) return "null";
        if (v instanceof String) return "\"" + ((String) v).replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
        if (v instanceof Boolean || v instanceof Number) return v.toString();
        if (v instanceof Map) {
            StringBuilder b = new StringBuilder("{");
            boolean first = true;
            for (Map.Entry<?, ?> e : ((Map<?, ?>) v).entrySet()) {
                if (!first) b.append(',');
                first = false;
                b.append(json(e.getKey().toString())).append(':').append(json(e.getValue()));
            }
            return b.append('}').toString();
        }
        if (v instanceof Collection) {
            StringBuilder b = new StringBuilder("[");
            boolean first = true;
            for (Object o : (Collection<?>) v) {
                if (!first) b.append(',');
                first = false;
                b.append(json(o));
            }
            return b.append(']').toString();
        }
        throw new IllegalArgumentException(v.getClass().toString());
    }

    /** Writes the trace with a ready-made JSON config body (without the tag). */
    public static boolean writeRaw(String path, String cfgJson) throws IOException {
        if (invalid) return false;
        List<Ev> evs;
        synchronized (events) { evs = new ArrayList<>(events); }
        for (Ev e : evs) {
            if (!e.pending.isEmpty()) { invalidWhy = "pending " + e.pending + " in " + e.f.get("event"); return false; }
        }
        try (FileWriter w = new FileWriter(path)) {
            w.write("{\"tag\":\"config\"," + cfgJson.substring(1) + "\n");
            for (Ev e : evs) w.write(json(e.f) + "\n");
        }
        return true;
    }

    /** Writes the trace (config line + events), or nothing if invalid / incomplete. */
    public static boolean write(String path, Map<String, Object> cfg) throws IOException {
        if (invalid) return false;
        List<Ev> evs;
        synchronized (events) { evs = new ArrayList<>(events); }
        for (Ev e : evs) {
            if (!e.pending.isEmpty()) { invalidWhy = "pending " + e.pending + " in " + e.f.get("event"); return false; }
        }
        try (FileWriter w = new FileWriter(path)) {
            Map<String, Object> c = new LinkedHashMap<>();
            c.put("tag", "config");
            c.putAll(cfg);
            w.write(json(c) + "\n");
            for (Ev e : evs) w.write(json(e.f) + "\n");
        }
        return true;
    }
}
