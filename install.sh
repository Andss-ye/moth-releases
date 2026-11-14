#!/bin/sh
# Instala la última versión de Moth en /Applications (o ~/Applications si no se puede escribir ahí).
# Descarga con curl, que no marca el archivo con cuarentena: macOS no lo trata como una descarga de navegador
# y no muestra el aviso de «Apple no pudo verificar…» de las apps sin notarizar.
# MOTH_DEST cambia el destino y MOTH_NO_OPEN=1 evita abrir la app (pruebas).
set -eu

[ "$(uname -m)" = arm64 ] || { echo "Moth solo funciona en Macs con Apple Silicon." >&2; exit 1; }

TMP=$(mktemp -d)
MNT=$TMP/mnt
trap 'hdiutil detach -quiet "$MNT" 2>/dev/null || true; rm -rf "$TMP"' EXIT INT TERM

echo "Descargando Moth…"
curl -fL --progress-bar -o "$TMP/Moth.dmg" https://github.com/Andss-ye/moth-releases/releases/latest/download/Moth.dmg
mkdir "$MNT"
hdiutil attach -quiet -nobrowse -readonly -mountpoint "$MNT" "$TMP/Moth.dmg" </dev/null

min=$(/usr/libexec/PlistBuddy -c "Print :LSMinimumSystemVersion" "$MNT/Moth.app/Contents/Info.plist")
if [ "$(printf '%s\n%s\n' "$min" "$(sw_vers -productVersion)" | sort -V | head -n 1)" != "$min" ]; then
  echo "Moth necesita macOS $min o posterior." >&2
  exit 1
fi

DEST=${MOTH_DEST:-/Applications}
if [ ! -w "$DEST" ]; then
  DEST=$HOME/Applications
  mkdir -p "$DEST"
fi

pkill -x Moth 2>/dev/null || true
rm -rf "$DEST/Moth.app"
ditto "$MNT/Moth.app" "$DEST/Moth.app"
xattr -dr com.apple.quarantine "$DEST/Moth.app" 2>/dev/null || true
echo "Moth instalada en $DEST"
[ "${MOTH_NO_OPEN:-}" = 1 ] || open "$DEST/Moth.app"
