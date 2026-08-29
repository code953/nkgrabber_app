#!/bin/sh
# Installs NKgrabber desktop integration for the current user.
#
# The tarball is relocatable — the user picks where it lands — and the
# freedesktop spec forbids relative paths in Exec= and does not expand ~. So
# the .desktop file ships as a template and the absolute path is substituted
# here, at install time, once the location is actually known.
#
# Run from the extracted bundle directory:  ./install.sh
set -eu

BUNDLE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
APP_ID=top.code953.nkgrabber
DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ ! -x "$BUNDLE_DIR/nkgrabber" ]; then
  echo "错误: 未在 install.sh 同级目录找到 nkgrabber 可执行文件" >&2
  echo "请在解压后的目录中运行本脚本。" >&2
  exit 1
fi

# Desktop entry.
mkdir -p "$DATA_HOME/applications"
sed "s|@EXEC@|$BUNDLE_DIR/nkgrabber|g" \
  "$BUNDLE_DIR/data/$APP_ID.desktop.in" \
  > "$DATA_HOME/applications/$APP_ID.desktop"
chmod 644 "$DATA_HOME/applications/$APP_ID.desktop"

# Icons into the user's hicolor theme. Both the launcher entry and the running
# window resolve the icon by theme name (app_id -> .desktop -> Icon=), so an
# absolute path here would fix the menu entry but leave the taskbar blank.
for size in 48 64 128 256 512; do
  mkdir -p "$DATA_HOME/icons/hicolor/${size}x${size}/apps"
  cp "$BUNDLE_DIR/data/icons/hicolor/${size}x${size}/apps/$APP_ID.png" \
     "$DATA_HOME/icons/hicolor/${size}x${size}/apps/$APP_ID.png"
done

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$DATA_HOME/icons/hicolor" >/dev/null 2>&1 || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DATA_HOME/applications" >/dev/null 2>&1 || true
fi

echo "NKgrabber 已安装，可从应用菜单启动，或直接运行:"
echo "  $BUNDLE_DIR/nkgrabber"
echo ""
echo "卸载:"
echo "  rm -f $DATA_HOME/applications/$APP_ID.desktop"
echo "  rm -f $DATA_HOME/icons/hicolor/*/apps/$APP_ID.png"
