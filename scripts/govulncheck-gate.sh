#!/usr/bin/env bash
# Fail on any called-level vulnerability that is not explicitly allowed.
#
# govulncheck has no ignore mechanism of its own and exits 3 whenever it finds
# anything, so a bare invocation cannot pass while an unfixable transitive
# finding exists. This filters to findings this code can actually reach, then
# subtracts .govulncheck-allow.
set -euo pipefail

# comm needs a consistent collation or it reports identical lines as different.
export LC_ALL=C

allow_file=${1:-.govulncheck-allow}
json=$(mktemp); called=$(mktemp); allowed=$(mktemp)
trap 'rm -f "$json" "$called" "$allowed"' EXIT

# Exit 3 means "found something", which is not an error here.
govulncheck -format json ./... > "$json" || [ $? -eq 3 ]

# A trace entry carrying a function is a call this code can reach; module- and
# package-level findings are reported too but are not called.
jq -r 'select(.finding != null)
       | select(.finding.trace[0].function != null)
       | .finding.osv' "$json" | sort -u > "$called"

grep -vE '^[[:space:]]*(#|$)' "$allow_file" | awk '{print $1}' | sort -u > "$allowed"

unexpected=$(comm -23 "$called" "$allowed")
if [ -n "$unexpected" ]; then
    echo "::error::govulncheck found reachable vulnerabilities not in $allow_file:"
    while read -r id; do
        [ -n "$id" ] || continue
        echo "::error::  $id  https://pkg.go.dev/vuln/$id"
    done <<< "$unexpected"
    echo "Fix the dependency, or add the ID to $allow_file with the reason it is acceptable."
    exit 1
fi

# A stale entry is not a failure, but it should not linger.
stale=$(comm -13 "$called" "$allowed")
if [ -n "$stale" ]; then
    echo "::warning::allowed but no longer reported - remove from $allow_file:"
    while read -r id; do [ -n "$id" ] && echo "::warning::  $id"; done <<< "$stale"
fi

echo "govulncheck: $(wc -l < "$called") reachable finding(s), all allowed."
