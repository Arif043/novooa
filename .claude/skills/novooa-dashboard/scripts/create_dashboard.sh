#!/usr/bin/env bash
# Legt ein neues Kunden-Dashboard aus der Vorlage des Skills an.
#
#   create_dashboard.sh "<Kundenname>" <Zielordner> [Optionen]
#
# Optionen:
#   --client-ref <tag>    Git-Tag von novooa_runtime_client
#                         (Standard: novooa-runtime-client-v0.2.0)
#   --client-repo <url>   Repo mit dem Paket
#                         (Standard: https://github.com/Arif043/syscat2.git)
#   --client-path <pfad>  Lokales Paket statt Git (Entwicklung); schreibt
#                         pubspec_overrides.yaml, das nicht eingecheckt wird.
#   --platforms <liste>   Standard: web,macos,windows,linux,ios,android
set -euo pipefail

skill_version="0.3.0"
client_ref="novooa-runtime-client-v0.2.0"
client_repo="https://github.com/Arif043/syscat2.git"
client_path=""
platforms="web,macos,windows,linux,ios,android"

usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
[[ $# -ge 2 ]] || usage
title="$1"; target="$2"; shift 2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --client-ref) client_ref="$2"; shift 2 ;;
    --client-repo) client_repo="$2"; shift 2 ;;
    --client-path) client_path="$(cd "$2" && pwd)"; shift 2 ;;
    --platforms) platforms="$2"; shift 2 ;;
    *) echo "Unbekannte Option: $1" >&2; usage ;;
  esac
done

command -v flutter >/dev/null || { echo "Flutter fehlt im PATH." >&2; exit 1; }
[[ ! -e "$target" ]] || { echo "Ziel existiert bereits: $target" >&2; exit 1; }

slug="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' \
  | sed -e 's/ä/ae/g; s/ö/oe/g; s/ü/ue/g; s/ß/ss/g' -e 's/[^a-z0-9]\{1,\}/_/g' -e 's/^_//; s/_$//')"
[[ -n "$slug" ]] || { echo "Der Kundenname braucht Buchstaben oder Ziffern." >&2; exit 1; }
package="novooa_dashboard_${slug}"

starter="$(cd "$(dirname "$0")/../assets/starter" && pwd)"
mkdir -p "$target"
cp -R "$starter/." "$target/"
target="$(cd "$target" && pwd)"

escaped_title="$(printf '%s' "$title" | sed 's/[&/\]/\\&/g')"
find "$target" -type f \( -name '*.dart' -o -name '*.yaml' -o -name '*.md' \) -print0 \
  | xargs -0 sed -i.bak \
      -e "s/__DASHBOARD_PACKAGE__/${package}/g" \
      -e "s/__DASHBOARD_TITLE__/${escaped_title}/g" \
      -e "s#__CLIENT_REPO__#${client_repo}#g" \
      -e "s#__CLIENT_REF__#${client_ref}#g"
find "$target" -name '*.bak' -delete

if [[ -n "$client_path" ]]; then
  printf 'dependency_overrides:\n  novooa_runtime_client:\n    path: %s\n' "$client_path" \
    > "$target/pubspec_overrides.yaml"
fi
printf 'skill: novooa-dashboard\nversion: %s\nclient: %s\n' \
  "$skill_version" "$client_ref" > "$target/.novooa-dashboard"
printf 'build/\n.dart_tool/\npubspec_overrides.yaml\n' > "$target/.gitignore"

cd "$target"
# Ergänzt nur fehlende Plattformordner; vorhandene Dateien bleiben.
flutter create --project-name "$package" --platforms "$platforms" --no-pub . >/dev/null
rm -f test/widget_test.dart
flutter pub get >/dev/null
echo "Dashboard angelegt: $target ($package, Skill $skill_version, Client $client_ref)"
