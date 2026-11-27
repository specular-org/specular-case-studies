package grtrace;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Minimal JSON writer and reader for the recorder's own use. */
final class Json {
    private Json() {}

    static String write(Object v) {
        StringBuilder sb = new StringBuilder();
        write(sb, v);
        return sb.toString();
    }

    @SuppressWarnings("unchecked")
    static void write(StringBuilder sb, Object v) {
        if (v == null) {
            sb.append("null");
        } else if (v instanceof String) {
            sb.append('"');
            String s = (String) v;
            for (int i = 0; i < s.length(); i++) {
                char c = s.charAt(i);
                switch (c) {
                    case '"': sb.append("\\\""); break;
                    case '\\': sb.append("\\\\"); break;
                    case '\n': sb.append("\\n"); break;
                    case '\r': sb.append("\\r"); break;
                    case '\t': sb.append("\\t"); break;
                    default:
                        if (c < 0x20) {
                            sb.append(String.format("\\u%04x", (int) c));
                        } else {
                            sb.append(c);
                        }
                }
            }
            sb.append('"');
        } else if (v instanceof Boolean || v instanceof Integer || v instanceof Long) {
            sb.append(v);
        } else if (v instanceof Map) {
            sb.append('{');
            boolean first = true;
            for (Map.Entry<String, Object> e : ((Map<String, Object>) v).entrySet()) {
                if (!first) sb.append(',');
                first = false;
                write(sb, e.getKey());
                sb.append(':');
                write(sb, e.getValue());
            }
            sb.append('}');
        } else if (v instanceof Collection) {
            sb.append('[');
            boolean first = true;
            for (Object o : (Collection<Object>) v) {
                if (!first) sb.append(',');
                first = false;
                write(sb, o);
            }
            sb.append(']');
        } else {
            throw new IllegalArgumentException("cannot write " + v.getClass());
        }
    }

    /** Parses objects, arrays, strings, integers, booleans and null. */
    static Object parse(String s) {
        int[] pos = {0};
        Object v = value(s, pos);
        skipWs(s, pos);
        if (pos[0] != s.length()) throw new IllegalArgumentException("trailing JSON at " + pos[0]);
        return v;
    }

    private static void skipWs(String s, int[] p) {
        while (p[0] < s.length() && Character.isWhitespace(s.charAt(p[0]))) p[0]++;
    }

    private static Object value(String s, int[] p) {
        skipWs(s, p);
        char c = s.charAt(p[0]);
        if (c == '{') {
            p[0]++;
            Map<String, Object> m = new LinkedHashMap<>();
            skipWs(s, p);
            if (s.charAt(p[0]) == '}') { p[0]++; return m; }
            for (;;) {
                skipWs(s, p);
                String k = (String) value(s, p);
                skipWs(s, p);
                expect(s, p, ':');
                m.put(k, value(s, p));
                skipWs(s, p);
                if (s.charAt(p[0]) == ',') { p[0]++; continue; }
                expect(s, p, '}');
                return m;
            }
        } else if (c == '[') {
            p[0]++;
            List<Object> l = new ArrayList<>();
            skipWs(s, p);
            if (s.charAt(p[0]) == ']') { p[0]++; return l; }
            for (;;) {
                l.add(value(s, p));
                skipWs(s, p);
                if (s.charAt(p[0]) == ',') { p[0]++; continue; }
                expect(s, p, ']');
                return l;
            }
        } else if (c == '"') {
            p[0]++;
            StringBuilder sb = new StringBuilder();
            for (;;) {
                char d = s.charAt(p[0]++);
                if (d == '"') return sb.toString();
                if (d == '\\') {
                    char e = s.charAt(p[0]++);
                    switch (e) {
                        case 'n': sb.append('\n'); break;
                        case 't': sb.append('\t'); break;
                        case 'r': sb.append('\r'); break;
                        case 'u': sb.append((char) Integer.parseInt(s.substring(p[0], p[0] + 4), 16)); p[0] += 4; break;
                        default: sb.append(e);
                    }
                } else {
                    sb.append(d);
                }
            }
        } else if (s.startsWith("true", p[0])) {
            p[0] += 4;
            return Boolean.TRUE;
        } else if (s.startsWith("false", p[0])) {
            p[0] += 5;
            return Boolean.FALSE;
        } else if (s.startsWith("null", p[0])) {
            p[0] += 4;
            return null;
        } else {
            int start = p[0];
            if (s.charAt(p[0]) == '-') p[0]++;
            while (p[0] < s.length() && Character.isDigit(s.charAt(p[0]))) p[0]++;
            long l = Long.parseLong(s.substring(start, p[0]));
            if (l >= Integer.MIN_VALUE && l <= Integer.MAX_VALUE) return (int) l;
            return l;
        }
    }

    private static void expect(String s, int[] p, char c) {
        if (s.charAt(p[0]) != c) throw new IllegalArgumentException("expected '" + c + "' at " + p[0] + " in " + s);
        p[0]++;
    }
}
