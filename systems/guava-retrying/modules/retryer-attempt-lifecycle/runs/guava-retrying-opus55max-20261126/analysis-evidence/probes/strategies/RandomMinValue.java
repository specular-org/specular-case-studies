import java.util.Random;
import java.lang.reflect.Field;
import java.util.concurrent.atomic.AtomicLong;

/** Exact search: can java.util.Random.nextLong() return Long.MIN_VALUE? */
public class RandomMinValue {
  static final long MULT = 0x5DEECE66DL, ADD = 0xBL, MASK = (1L << 48) - 1;
  public static void main(String[] args) throws Exception {
    // nextLong = ((long)hi << 32) + lo (lo sign-extended). == Long.MIN_VALUE iff hi == 0x80000000 && lo == 0 (see derivation).
    // Brute-force the general identity over all (hi,lo) sign cases for sanity: check algebra on random samples.
    Random chk = new Random(1);
    for (int i = 0; i < 1000000; i++) {
      int hi = chk.nextInt(), lo = chk.nextInt();
      long v = ((long) hi << 32) + lo;
      boolean isMin = v == Long.MIN_VALUE;
      boolean pred = hi == Integer.MIN_VALUE && lo == 0;
      if (isMin != pred) throw new AssertionError(hi + " " + lo);
    }
    // explicit edge cases
    long[][] cases = {{Integer.MIN_VALUE, 0}, {Integer.MIN_VALUE + 1, Integer.MIN_VALUE}, {Integer.MIN_VALUE + 1, -1}, {Integer.MIN_VALUE, -1}};
    for (long[] c : cases) System.out.println("hi=" + Integer.toHexString((int) c[0]) + " lo=" + (int) c[1] + " -> " + (((long) (int) c[0] << 32) + (int) c[1]) + (((((long) (int) c[0] << 32) + (int) c[1]) == Long.MIN_VALUE) ? "  == MIN_VALUE" : ""));
    int found = 0;
    for (long x = 0; x <= 0xFFFFL; x++) {
      long s1 = (0x80000000L << 16) | x;            // state after the 'hi' draw: top 32 bits = 0x80000000
      long s2 = (s1 * MULT + ADD) & MASK;            // state after the 'lo' draw
      int hi = (int) (s1 >>> 16), lo = (int) (s2 >>> 16);
      if (hi != Integer.MIN_VALUE) throw new AssertionError();
      if (lo == 0) {
        found++;
        System.out.println("REACHABLE: state s1=0x" + Long.toHexString(s1) + " s2=0x" + Long.toHexString(s2));
        // Recover a state s0 such that next() from s0 yields s1: s0 = (s1 - ADD) * MULT^{-1} mod 2^48
        long inv = modInverse(MULT, 1L << 48);
        long s0 = ((s1 - ADD) * inv) & MASK;
        // Build a Random positioned at s0 via reflection-free approach: setSeed scrambles with MULT, so seed = s0 ^ MULT
        Random r = new Random(s0 ^ MULT);
        long v = r.nextLong();
        System.out.println("  new Random(0x" + Long.toHexString(s0 ^ MULT) + "L).nextLong() = " + v + " ; Math.abs = " + Math.abs(v)
            + " ; Math.abs(v) % 1000 = " + (Math.abs(v) % 1000));
      }
    }
    System.out.println("qualifying states among 65536 candidates: " + found);
  }
  static long modInverse(long a, long m) { // m = 2^48, a odd
    long x = 1; // Newton iteration for inverse mod 2^k
    for (int i = 0; i < 6; i++) x = x * (2 - a * x);
    return x & (m - 1);
  }
}
