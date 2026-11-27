#!/usr/bin/env bash
# Usage: run.sh <MainClass> [extra JPF +options...]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
JPF_HOME=${JPF_HOME:-/home/ubuntu/tools/jpf-core-mku-spurious}
JAVA11=${JAVA11:-/usr/lib/jvm/java-11-openjdk-amd64/bin}
APP_CLASSES=${APP_CLASSES:?set APP_CLASSES to the compiled guava-retrying classes}
GUAVA=${GUAVA:-$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}
JSR305=${JSR305:-$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}
mkdir -p "$HERE/build"
"$JAVA11/javac" -g -nowarn -cp "$APP_CLASSES:$GUAVA:$JSR305:$JPF_HOME/build/jpf.jar" -d "$HERE/build" "$HERE"/src/*.java
main=$1; shift
exec "$JAVA11/java" -Xmx4g -cp "$JPF_HOME/build/jpf.jar:$HERE/build:$APP_CLASSES:$GUAVA:$JSR305" gov.nasa.jpf.JPF \
  +classpath="$HERE/build:$APP_CLASSES:$GUAVA:$JSR305" "$@" "$main"
