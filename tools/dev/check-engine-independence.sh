#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# check-engine-independence.sh — fail if RealCricket.Core depends on Unity.
#
# Reads the compiled assembly's CLI metadata (assembly references, type
# references, type definitions) and rejects UnityEngine / UnityEditor.
# Works locally and in GitHub Actions; needs only a .NET SDK.
#
# Follows tools/README.md conventions: non-interactive, argument-driven,
# exits non-zero on failure, prints a one-line summary.
#
# Usage:
#   tools/dev/check-engine-independence.sh [--configuration Release] [--assembly PATH]
#
# Default assembly: tools/dotnet/RealCricket.Core/bin/<Configuration>/netstandard2.1/RealCricket.Core.dll
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

CONFIGURATION="Debug"
ASSEMBLY=""

while [ $# -gt 0 ]; do
  case "$1" in
    -c|--configuration) CONFIGURATION="${2:?--configuration needs a value}"; shift 2 ;;
    -a|--assembly)      ASSEMBLY="${2:?--assembly needs a value}"; shift 2 ;;
    -h|--help)
      sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "check-engine-independence: unknown argument '$1'" >&2; exit 2 ;;
  esac
done

if ! command -v dotnet >/dev/null 2>&1; then
  echo "check-engine-independence: FAILED — dotnet not on PATH (run tools/dev/bootstrap-dotnet.sh and add \$HOME/.dotnet to PATH)" >&2
  exit 1
fi

if [ -z "${ASSEMBLY}" ]; then
  ASSEMBLY="${REPO_ROOT}/tools/dotnet/RealCricket.Core/bin/${CONFIGURATION}/netstandard2.1/RealCricket.Core.dll"
fi

if [ ! -f "${ASSEMBLY}" ]; then
  echo "check-engine-independence: FAILED — assembly not found: ${ASSEMBLY} (build the solution first)" >&2
  exit 1
fi

GUARD_PROJECT="${REPO_ROOT}/tools/dotnet/RealCricket.EngineGuard/RealCricket.EngineGuard.csproj"
GUARD_DLL="${REPO_ROOT}/tools/dotnet/RealCricket.EngineGuard/bin/Release/net10.0/RealCricket.EngineGuard.dll"

if [ ! -f "${GUARD_DLL}" ]; then
  if ! dotnet build "${GUARD_PROJECT}" --configuration Release --nologo --verbosity quiet -maxcpucount:1 >/dev/null; then
    echo "check-engine-independence: FAILED — could not build the guard tool" >&2
    exit 1
  fi
fi

if ! dotnet "${GUARD_DLL}" "${ASSEMBLY}"; then
  exit 1
fi

exit 0
