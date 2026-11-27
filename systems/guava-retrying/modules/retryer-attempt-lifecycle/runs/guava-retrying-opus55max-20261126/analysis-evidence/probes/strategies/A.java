import com.github.rholder.retry.Attempt;
import java.util.concurrent.ExecutionException;
/** Hand-made Attempt for driving strategies directly. */
public class A<V> implements Attempt<V> {
  final long n, delay; final Throwable ex; final V res;
  A(long n, long delay, Throwable ex, V res) { this.n = n; this.delay = delay; this.ex = ex; this.res = res; }
  static <V> A<V> fail(long n) { return new A<V>(n, 0, new RuntimeException("x"), null); }
  static <V> A<V> fail(long n, Throwable t) { return new A<V>(n, 0, t, null); }
  static <V> A<V> failDelay(long n, long delay) { return new A<V>(n, delay, new RuntimeException("x"), null); }
  public V get() throws ExecutionException { if (ex != null) throw new ExecutionException(ex); return res; }
  public boolean hasResult() { return ex == null; }
  public boolean hasException() { return ex != null; }
  public V getResult() { if (ex != null) throw new IllegalStateException(); return res; }
  public Throwable getExceptionCause() { if (ex == null) throw new IllegalStateException(); return ex; }
  public long getAttemptNumber() { return n; }
  public long getDelaySinceFirstAttempt() { return delay; }
}
