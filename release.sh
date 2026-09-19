#!/bin/bash
# Builds and publishes a release from this machine — no hosted CI required.
#
#   bash release.sh 1.5.9.7            build, checksum, publish
#   bash release.sh 1.5.9.7 --dry-run  build and checksum only, publish nothing
#   bash release.sh --check            verify toolchain and report what is missing
#
# What it does, in order:
#   1. Validates the version against updater.go, so a release can never claim a
#      version the binary does not report.
#   2. Builds macOS (universal DMG + ZIP) and Windows (portable EXE, ZIP, and the
#      NSIS Setup wizard). Linux is intentionally not part of the current
#      release scope; see build_linux.sh for the standalone path.
#   3. Stages the asset names the README links to, then creates the GitHub
#      release (or updates it when the tag already exists).
#   4. Generates SHA256SUMS from the published asset list and uploads it, so the
#      checksum file always describes files users can actually download.
#   5. Downloads one artifact back and verifies its digest end to end.
#
# Why local: see the note in .github/workflows/build.yml. Hosted runners need a
# healthy account; this path has no such dependency.
set -euo pipefail
cd "$(dirname "$0")"

REPO="vianziro/Whatsapp-Dekstop"
VERSION=""
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --check)   CHECK_ONLY=1 ;;
    -*)        echo "unknown flag: $arg" >&2; exit 2 ;;
    *)         VERSION="$arg" ;;
  esac
done

die() { echo "error: $*" >&2; exit 1; }
step() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

require() {
  command -v "$1" >/dev/null 2>&1 || MISSING+=("$1")
}

# --------------------------------------------------------------------------
# Toolchain check
# --------------------------------------------------------------------------
MISSING=()
require go
require gh
require zip
require shasum
require makensis   # Windows Setup wizard
require python3    # wizard graphics + checksum helpers
require lipo       # macOS universal binary
require hdiutil    # macOS DMG
require xattr

if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "Missing required tool(s): ${MISSING[*]}" >&2
  echo
  echo "Install hints:"
  echo "  makensis  -> brew install makensis"
  echo "  go        -> https://go.dev/dl/"
  echo "  gh        -> brew install gh && gh auth login"
  echo "  lipo/hdiutil/xattr ship with macOS; this script must run on macOS."
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  die "gh is not authenticated. Run: gh auth login"
fi

if [ -n "${CHECK_ONLY:-}" ]; then
  echo "toolchain OK — nothing missing"
  exit 0
fi

[ -n "$VERSION" ] || die "usage: bash release.sh <version> [--dry-run]
example: bash release.sh 1.5.9.7"

# --------------------------------------------------------------------------
# 1. Validate the version
# --------------------------------------------------------------------------
step "Validating version $VERSION"

[[ "$VERSION" =~ ^[0-9]+(\.[0-9]+){2,3}$ ]] || die "version must look like 1.5.9 or 1.5.9.7, got '$VERSION'"

grep -Fq "var appVersion = \"${VERSION}\"" updater.go \
  || die "updater.go must declare: var appVersion = \"${VERSION}\"
Bump it first, then re-run. A release whose binary reports a different version
would make the in-app updater offer the wrong download."

echo "version matches updater.go"

# --------------------------------------------------------------------------
# 2. Build
# --------------------------------------------------------------------------
step "Building macOS (universal)"
bash build_mac.sh "$VERSION" 2>&1 | grep -vE "deprecated|NSUserNotification|note:" | tail -3

step "Building Windows (portable + Setup wizard)"
bash build_windows_installer.sh "$VERSION" 2>&1 | tail -3

step "Staging release assets"
rm -f WhatsApp-Desk-Windows-x64.zip WhatsAppDesk.exe WhatsApp.exe \
      WhatsApp-macOS-Universal.dmg WhatsApp-macOS-Universal.zip
zip -j -q WhatsApp-Desk-Windows-x64.zip dist_win/WhatsAppDesk.exe
cp dist_win/WhatsAppDesk.exe WhatsAppDesk.exe
cp dist_win/WhatsAppDesk.exe WhatsApp.exe
cp WhatsApp-Desk-macOS-Universal.dmg WhatsApp-macOS-Universal.dmg
cp WhatsApp-Desk-macOS-Universal.zip WhatsApp-macOS-Universal.zip

ASSETS=(
  WhatsApp-Desk-Windows-x64-Setup.exe
  WhatsApp-Desk-Windows-x64.zip
  WhatsAppDesk.exe
  WhatsApp.exe
  WhatsApp-Desk-macOS-Universal.dmg
  WhatsApp-Desk-macOS-Universal.zip
  WhatsApp-macOS-Universal.dmg
  WhatsApp-macOS-Universal.zip
)

for f in "${ASSETS[@]}"; do
  [ -f "$f" ] || die "expected build output missing: $f"
done
ls -la "${ASSETS[@]}" | awk '{printf "%10s  %s\n", $5, $9}'

if [ "$DRY_RUN" = "1" ]; then
  step "Dry run complete"
  echo "Built and staged everything. Nothing was published."
  echo "Re-run without --dry-run to create/update the v$VERSION release."
  exit 0
fi

# --------------------------------------------------------------------------
# 3. Publish
# --------------------------------------------------------------------------
TAG="v$VERSION"
step "Publishing $TAG"

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "release $TAG already exists — replacing its assets"
  gh release upload "$TAG" --clobber --repo "$REPO" "${ASSETS[@]}"
else
  echo "creating release $TAG"
  gh release create "$TAG" --repo "$REPO" \
    --title "WhatsApp Desk $VERSION" \
    --notes "Built and published from a local machine. See the README for details.

macOS build is universal (Apple Silicon and Intel). Windows requires the
WebView2 runtime, which ships with Windows 11 and is present on virtually all
current Windows 10 systems." \
    "${ASSETS[@]}"
fi

# --------------------------------------------------------------------------
# 4. Checksums (derived from the published asset list, so they cannot drift)
# --------------------------------------------------------------------------
step "Generating and uploading SHA256SUMS"
bash make_checksums.sh "$TAG"

# --------------------------------------------------------------------------
# 5. Verify what a user would actually get
# --------------------------------------------------------------------------
step "Verifying the published download"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
(
  cd "$TMP"
  curl -sSL -O --max-time 180 "https://github.com/$REPO/releases/latest/download/WhatsApp-Desk-Windows-x64-Setup.exe"
  curl -sSL -O --max-time 60  "https://github.com/$REPO/releases/latest/download/SHA256SUMS"
  grep "Setup.exe" SHA256SUMS > sub
  shasum -a 256 -c sub
)

step "Done"
echo "Release: https://github.com/$REPO/releases/tag/$TAG"
echo "Latest:  $(gh api "repos/$REPO/releases/latest" --jq '.tag_name')"
