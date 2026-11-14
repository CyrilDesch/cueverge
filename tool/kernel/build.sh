#!/usr/bin/env bash
# @what: builds the cueverge binary into dist/cueverge/bin, the install folder that mise links.
# @why: Kyo 1.0.0-RC7 is compiled for Java 25, so the launcher runs the jar on a JVM 25 from coursier.
# @ref: $> mise run build
set -euo pipefail
cd "$(dirname "$0")/../.."

OUT=dist/cueverge/bin
mkdir -p "$OUT"
scala --power package --server=false tool/kernel --assembly -o "$OUT/cueverge.jar" -f
JAVA_HOME_25="$(cs java-home --jvm 25)"
cat > "$OUT/cueverge" <<LAUNCHER
#!/usr/bin/env bash
exec "$JAVA_HOME_25/bin/java" --sun-misc-unsafe-memory-access=allow -jar "\$(dirname "\$0")/cueverge.jar" "\$@"
LAUNCHER
chmod +x "$OUT/cueverge"
echo "Built $OUT/cueverge"
