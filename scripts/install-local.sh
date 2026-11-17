#!/bin/sh
# Builds a release binary into ~/.local/bin (replacing any older one), then
# restarts the core the planned way so running terminals pick up the new build
# (never handing this shell's environment to a core it has to start).
set -eu
cd "$(dirname "$0")/.."
build_dir=target/release
if [ "$(uname -s)" = Darwin ]; then
  if [ "$(sysctl -n hw.optional.arm64 2>/dev/null || true)" = 1 ]; then
    target=aarch64-apple-darwin
  else
    target=x86_64-apple-darwin
  fi
  build_dir="target/$target/release"
  nice -n 10 cargo build --locked --release -p herdr-core --target "$target"
else
  nice -n 10 cargo build --locked --release -p herdr-core
fi
bin="${HC_INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$bin"
if [ "$(uname -s)" = Darwin ]; then
  app="target/release/Herdr Core.app"
  rm -rf "$app"
  sh scripts/mac-bundle "$build_dir/herdr-core" "$app"
  bash scripts/mac-sign "$app"
  "$app/Contents/MacOS/herdr-core" --hc-install-bundle "$app/Contents/MacOS/herdr-core" "$bin/herdr-core"
else
  install -m 755 "$build_dir/herdr-core" "$bin/herdr-core.new"
  mv -f "$bin/herdr-core.new" "$bin/herdr-core"
fi
[ -e "$bin/hc" ] || [ -L "$bin/hc" ] || ln -s herdr-core "$bin/hc"
sh scripts/restart-core.sh "$bin/herdr-core"
