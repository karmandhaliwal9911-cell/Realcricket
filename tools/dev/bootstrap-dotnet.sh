#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bootstrap-dotnet.sh — install the pinned .NET SDK into a local directory.
#
# Follows tools/README.md conventions: non-interactive, argument-driven,
# exits non-zero on failure, prints a one-line summary.
#
# Usage:
#   tools/dev/bootstrap-dotnet.sh [--install-dir DIR] [--force] [--dry-run]
#
# Defaults to "$HOME/.dotnet". The version is read from global.json at the
# repository root, so the SDK and the repository can never disagree.
#
# This script never uses sudo and never touches a system-wide location.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
GLOBAL_JSON="${REPO_ROOT}/global.json"

INSTALL_DIR="${DOTNET_INSTALL_DIR:-$HOME/.dotnet}"
FORCE=0
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --install-dir) INSTALL_DIR="${2:?--install-dir needs a value}"; shift 2 ;;
    --force)       FORCE=1; shift ;;
    --dry-run)     DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "bootstrap-dotnet: unknown argument '$1'" >&2; exit 2 ;;
  esac
done

if [ ! -f "${GLOBAL_JSON}" ]; then
  echo "bootstrap-dotnet: FAILED — global.json not found at ${GLOBAL_JSON}" >&2
  exit 1
fi

SDK_VERSION="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "${GLOBAL_JSON}" | head -n 1)"
if [ -z "${SDK_VERSION}" ]; then
  echo "bootstrap-dotnet: FAILED — could not read sdk.version from ${GLOBAL_JSON}" >&2
  exit 1
fi

DOTNET_BIN="${INSTALL_DIR}/dotnet"

if [ "${FORCE}" -eq 0 ] && [ -x "${DOTNET_BIN}" ] && ${DOTNET_BIN} --list-sdks 2>/dev/null | grep -q "^${SDK_VERSION} "; then
  echo "bootstrap-dotnet: OK — SDK ${SDK_VERSION} already present at ${INSTALL_DIR}"
  exit 0
fi

if [ "${DRY_RUN}" -eq 1 ]; then
  echo "bootstrap-dotnet: DRY-RUN — would install SDK ${SDK_VERSION} into ${INSTALL_DIR}"
  exit 0
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

INSTALLER="${TMP_DIR}/dotnet-install.sh"
if ! curl -fsSL -o "${INSTALLER}" https://dot.net/v1/dotnet-install.sh; then
  echo "bootstrap-dotnet: FAILED — could not download dotnet-install.sh" >&2
  exit 1
fi
chmod +x "${INSTALLER}"

if ! "${INSTALLER}" --channel 10.0 --version "${SDK_VERSION}" --install-dir "${INSTALL_DIR}" --no-path; then
  echo "bootstrap-dotnet: FAILED — dotnet-install.sh reported an error" >&2
  exit 1
fi

if ! "${DOTNET_BIN}" --list-sdks | grep -q "^${SDK_VERSION} "; then
  echo "bootstrap-dotnet: FAILED — SDK ${SDK_VERSION} missing after install" >&2
  exit 1
fi

echo "bootstrap-dotnet: OK — installed SDK ${SDK_VERSION} at ${INSTALL_DIR} (add ${INSTALL_DIR} to PATH)"
