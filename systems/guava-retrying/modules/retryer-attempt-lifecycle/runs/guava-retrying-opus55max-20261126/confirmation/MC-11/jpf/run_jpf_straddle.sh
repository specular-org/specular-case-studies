#!/usr/bin/env bash
# Supplementary MC-11 evidence: JPF exhaustively explores thread schedules of MC11Straddle (public API
# workload, unmodified library) and reports whether the "straddle" interleaving of
# spec/output/hunt_sharing_bfs4.out is reachable in the real bytecode of RetryerBuilder/Retryer/JDK ArrayList.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SRC_DIR:-$HERE/../worktree}"
JPF_HOME="${JPF_HOME:-/home/ubuntu/tools/jpf-core-mku-spurious}"
JAVA11="${JAVA11:-/usr/lib/jvm/java-11-openjdk-amd64/bin}"
M2="${M2_REPO:-$HOME/.m2/repository}"
GUAVA="$M2/com/google/guava/guava/22.0/guava-22.0.jar"
JSR305="$M2/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar"
BUILD="$(mktemp -d /tmp/mc11-jpf.XXXXXX)"
trap 'rm -rf "$BUILD"' EXIT
mkdir -p "$BUILD/lib" "$BUILD/app"
echo "library source: $SRC_DIR @ $(git -C "$SRC_DIR" rev-parse --short HEAD) (dirty: $(git -C "$SRC_DIR" status --porcelain -- src | wc -l) files)"
"$JAVA11/javac" -g -nowarn --release 8 -cp "$GUAVA:$JSR305" -d "$BUILD/lib" $(find "$SRC_DIR/src/main/java" -name '*.java') 2>&1 | grep -v '^Note:' || true
"$JAVA11/javac" -g -nowarn -cp "$BUILD/lib:$GUAVA:$JSR305:$JPF_HOME/build/jpf.jar" -d "$BUILD/app" "$HERE"/src/*.java
CP="$BUILD/app:$BUILD/lib:$GUAVA:$JSR305"
"$JAVA11/java" -Xmx6g -cp "$JPF_HOME/build/jpf.jar:$CP" gov.nasa.jpf.JPF \
  +classpath="$CP" \
  +listener=MC11StraddleListener \
  +search.multiple_errors=false \
  +report.console.property_violation=error \
  MC11Straddle
