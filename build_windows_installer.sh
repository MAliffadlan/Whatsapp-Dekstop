#!/bin/bash
# Builds the production Windows installer: GUI binary + branded NSIS setup.
#
#   bash build_windows_installer.sh 1.5.9.3
#
# Produces:
#   dist_win/WhatsAppDesk.exe                 portable single-file app
#   WhatsApp-Desk-Windows-x64-Setup.exe       installer (wizard graphics,
#                                             shortcuts, Apps & features entry)
#
# Requires makensis:  brew install makensis
set -euo pipefail
cd "$(dirname "$0")"

VERSION="${1:-1.5.9.3}"

echo "== 1/3 building Windows binary (v${VERSION}) =="
bash build_windows.sh "$VERSION"

echo "== 2/3 generating wizard graphics =="
WA_DESK_VERSION="$VERSION" python3 installer/windows/make_wizard_assets.py

echo "== 3/3 compiling installer =="
makensis -DVERSION="$VERSION" -DAPPEXE_PATH="../../dist_win/WhatsAppDesk.exe" \
  installer/windows/WhatsAppDesk.nsi

ls -la WhatsApp-Desk-Windows-x64-Setup.exe dist_win/WhatsAppDesk.exe
