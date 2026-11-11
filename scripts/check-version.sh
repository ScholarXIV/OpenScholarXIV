#!/bin/bash
#
# Fails when a release tag does not match the app version in pubspec.yaml.
#
# The version in pubspec.yaml is what ends up inside the built app (Android
# versionName / versionCode). If it drifts from the release tag, update tools
# such as Obtainium keep reporting an update that never "installs".
#
# Usage: ./scripts/check-version.sh v4.2.0

set -euo pipefail

tag="${1:-}"
if [ -z "$tag" ]; then
  echo "usage: $0 <release-tag>" >&2
  exit 2
fi

pubspec="$(dirname "$(realpath "$0")")/../pubspec.yaml"
version_line="$(grep -E '^version:[[:space:]]*' "$pubspec" | head -n 1 || true)"
full_version="$(echo "$version_line" | sed -E 's/^version:[[:space:]]*//; s/[[:space:]]+$//')"

if [ -z "$full_version" ]; then
  echo "error: could not find a version in pubspec.yaml" >&2
  exit 1
fi

version_name="${full_version%%+*}"
build_number=""
if [[ "$full_version" == *+* ]]; then
  build_number="${full_version#*+}"
fi

status=0

if [ "${tag#v}" != "$version_name" ]; then
  echo "error: release tag '$tag' does not match pubspec.yaml version '$version_name'." >&2
  echo "       Set 'version:' in pubspec.yaml to ${tag#v}+<build number> before building the release." >&2
  status=1
fi

if ! [[ "$build_number" =~ ^[0-9]+$ ]]; then
  echo "error: pubspec.yaml version '$full_version' has no build number." >&2
  echo "       Without one every APK gets versionCode 1. Use <name>+<build number>, e.g. 4.2.0+40200." >&2
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "ok: tag '$tag' matches pubspec.yaml version '$full_version'."
fi

exit "$status"
