#!/usr/bin/env bash
# Prepares the trace instrumentation for guava-retrying 2.0.0.
#
# The library source is NOT modified (instrumentation-spec.md): the
# instrumentation is a Java PathFinder listener (src/recorder/grtrace) that
# observes each base.tla action's commit point while JPF executes the real
# guava-retrying, Guava 22.0 and JDK 11 java.util.concurrent bytecode.
# "Applying" it means:
#   1. jpf-core carries the JDK 11 model fixes in patches/jpf-core (applied to
#      the checkout if missing, then the jars are rebuilt);
#   2. the unmodified guava-retrying sources are compiled (Maven, pom.xml here);
#   3. the recorder (JPF listener + search) and the workloads are compiled.
#
# Environment (defaults in brackets):
#   GR_SRC       guava-retrying source tree      [/home/ubuntu/scratch/guava-retrying-src/guava-retrying]
#   JPF_HOME     jpf-core checkout               [/home/ubuntu/tools/jpf-core-mku-spurious]
#   JAVA11_HOME  JDK 11                          [/usr/lib/jvm/java-11-openjdk-amd64]
#   M2_REPO      Maven repository                [$HOME/.m2/repository]
#   GR_UNIT_TESTS=1  also run the library's own 36 unit tests
set -euo pipefail

HARNESS=$(cd "$(dirname "$0")" && pwd)
GR_SRC=${GR_SRC:-/home/ubuntu/scratch/guava-retrying-src/guava-retrying}
if [ ! -d "$GR_SRC/src/main/java" ] && [ -d "$HARNESS/../artifact/guava-retrying/src/main/java" ]; then
    GR_SRC=$HARNESS/../artifact/guava-retrying
fi
JPF_HOME=${JPF_HOME:-/home/ubuntu/tools/jpf-core-mku-spurious}
JAVA11_HOME=${JAVA11_HOME:-/usr/lib/jvm/java-11-openjdk-amd64}
M2_REPO=${M2_REPO:-$HOME/.m2/repository}
BUILD=$HARNESS/build

die() { echo "apply.sh: $*" >&2; exit 1; }
[ -d "$GR_SRC/src/main/java/com/github/rholder/retry" ] || die "guava-retrying sources not found at GR_SRC=$GR_SRC"
[ -x "$JAVA11_HOME/bin/javac" ] || die "JDK 11 not found at JAVA11_HOME=$JAVA11_HOME"
[ -d "$JPF_HOME/src/main/gov/nasa/jpf" ] || die "jpf-core checkout not found at JPF_HOME=$JPF_HOME"

# ---- 1. jpf-core with the JDK 11 model fixes ---------------------------------
echo "==> jpf-core model fixes ($JPF_HOME)"
applied_now=0
for p in "$HARNESS"/patches/jpf-core/*.patch; do
    name=$(basename "$p")
    if git -C "$JPF_HOME" apply --reverse --check "$p" >/dev/null 2>&1; then
        echo "    present: $name"
    elif git -C "$JPF_HOME" apply --check "$p" >/dev/null 2>&1; then
        echo "    applying: $name"
        git -C "$JPF_HOME" -c user.name=local -c user.email=local@localhost am -q --keep-cr "$p" \
            || die "git am failed for $name"
        applied_now=1
    else
        die "patch $name neither applied nor applicable in $JPF_HOME"
    fi
done
if [ "$applied_now" = 1 ] || [ ! -f "$JPF_HOME/build/jpf.jar" ] \
   || [ -n "$(find "$JPF_HOME/src" -newer "$JPF_HOME/build/jpf.jar" -name '*.java' -print -quit)" ]; then
    echo "    rebuilding jpf-core jars"
    (cd "$JPF_HOME" && JAVA_HOME=$JAVA11_HOME timeout 1200 ./gradlew buildJars --offline -q) \
        || die "jpf-core build failed"
fi

# ---- 2. guava-retrying (unmodified) -------------------------------------------
echo "==> guava-retrying classes from $GR_SRC"
goal=compile
[ "${GR_UNIT_TESTS:-0}" = 1 ] && goal=test
(cd "$HARNESS" && JAVA_HOME=$JAVA11_HOME timeout 1200 mvn -q -B -o -f pom.xml \
    -Dsrc.root="$GR_SRC" -Dmaven.repo.local="$M2_REPO" "$goal") \
    || (cd "$HARNESS" && JAVA_HOME=$JAVA11_HOME timeout 1200 mvn -q -B -f pom.xml \
        -Dsrc.root="$GR_SRC" -Dmaven.repo.local="$M2_REPO" "$goal") \
    || die "Maven build of guava-retrying failed"

GUAVA=$M2_REPO/com/google/guava/guava/22.0/guava-22.0.jar
JSR305=$M2_REPO/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar
[ -f "$GUAVA" ] && [ -f "$JSR305" ] || die "Guava 22.0 / jsr305 2.0.2 jars missing under $M2_REPO"

# ---- 3. recorder and workloads ------------------------------------------------
echo "==> recorder and workloads"
rm -rf "$BUILD/recorder" "$BUILD/workloads"
mkdir -p "$BUILD/recorder" "$BUILD/workloads"
"$JAVA11_HOME/bin/javac" -g -nowarn -cp "$JPF_HOME/build/jpf.jar" -d "$BUILD/recorder" \
    $(find "$HARNESS/src/recorder" -name '*.java')
"$JAVA11_HOME/bin/javac" -g -nowarn \
    -cp "$BUILD/maven/classes:$GUAVA:$JSR305:$JPF_HOME/build/jpf-classes.jar" \
    -d "$BUILD/workloads" $(find "$HARNESS/src/workloads" -name '*.java')

cat > "$BUILD/env.sh" <<EOF
# written by apply.sh
JAVA11_HOME='$JAVA11_HOME'
JPF_HOME='$JPF_HOME'
GR_CLASSES='$BUILD/maven/classes'
GUAVA='$GUAVA'
JSR305='$JSR305'
EOF
echo "==> apply.sh done"
