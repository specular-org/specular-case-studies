/** If other threads' next() calls interleave between the two next(32) of one nextLong() on the shared static RANDOM,
 *  the (hi, lo) pair is (top32(s1), top32(LCG^k(s1))) for k>=2. Search k in [1, K] for hi==0x80000000 && lo==0. */
public class RandomMinValueInterleaved {
  static final long MULT = 0x5DEECE66DL, ADD = 0xBL, MASK = (1L << 48) - 1;
  public static void main(String[] args) {
    int K = Integer.parseInt(args[0]);
    long A = 1, C = 0; // LCG^k : s -> A*s + C
    long base = 0x80000000L << 16;
    for (int k = 1; k <= K; k++) {
      // compose one more step: s -> MULT*(A s + C) + ADD
      A = (MULT * A) & MASK; C = (MULT * C + ADD) & MASK;
      long t = (A * base + C) & MASK;
      for (long x = 0; x <= 0xFFFFL; x++) {
        long s = (t + A * x) & MASK;
        if ((s >>> 16) == 0) { System.out.println("k=" + k + " x=0x" + Long.toHexString(x) + " -> lo state 0x" + Long.toHexString(s)); }
      }
    }
    System.out.println("searched k=1.." + K);
  }
}
