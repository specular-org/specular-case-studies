import com.github.rholder.retry.*;
import java.io.*;
import java.util.concurrent.*;

/** Does a RetryException thrown by Retryer.call survive Java serialization (RMI, remote task frameworks, session replication)? */
public class SerProbe {
  public static void main(String[] a) throws Exception {
    Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfException()
        .withStopStrategy(StopStrategies.stopAfterAttempt(2)).build();
    try {
      r.call(new Callable<String>() { public String call() throws Exception { throw new IOException("boom"); } });
    } catch (RetryException e) {
      try {
        ObjectOutputStream oos = new ObjectOutputStream(new ByteArrayOutputStream());
        oos.writeObject(e);
        System.out.println("serialized OK");
      } catch (NotSerializableException nse) {
        System.out.println("NotSerializableException: " + nse.getMessage());
      }
    }
  }
}
