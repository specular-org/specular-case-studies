package grwork;

import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.RetryListener;

/**
 * A RetryListener with an id. Ids are given in the order the listeners are
 * added to the builder (1..numInitListeners before build(), then the extra
 * ones); the recorder reports the id of the element ArrayList.Itr.next()
 * returns.
 */
public final class IdListener implements RetryListener {
    public final int id;

    public IdListener(int id) {
        this.id = id;
    }

    @Override
    public <V> void onRetry(Attempt<V> attempt) {
        // intentionally empty: the notification itself is the observed step
    }
}
