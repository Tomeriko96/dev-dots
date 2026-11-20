# Merge container settings ($new) into a user's Claude settings ($existing).
# Usage: jq -n --argjson existing "$OLD" --argjson new "$NEW" -f merge-claude-settings.jq
#
# Hooks are merged per event: a group in $existing counts as ours (and is
# replaced) when any of its hook commands also appears in a $new group of the
# same event. Other groups and events are kept. Running it twice on its own
# output gives the same JSON.

def commands: [.hooks[]?.command];
def dedupe: reduce .[] as $g ([]; if any(.[]; . == $g) then . else . + [$g] end);

$existing + {
  hooks: (
    ($new.hooks // {}) as $add
    | reduce ($add | keys_unsorted[]) as $event (($existing.hooks // {});
        ([$add[$event][] | commands[]]) as $ours
        | .[$event] = (
            ((.[$event] // []) | map(select(any(commands[]; IN($ours[])) | not)))
            + $add[$event]
            | dedupe
          )
      )
  ),
  permissions: (($existing.permissions // {}) + {
    allow: (($existing.permissions.allow // []) + ($new.permissions.allow // []) | unique),
    deny:  (($existing.permissions.deny  // []) + ($new.permissions.deny  // []) | unique)
  }
  # bypass mode and the extra working directories (AGENTS.md "Autonomy"), when the container sets them
  + (if $new.permissions.defaultMode then {defaultMode: $new.permissions.defaultMode} else {} end)
  + (if $new.permissions.additionalDirectories then {additionalDirectories:
      (($existing.permissions.additionalDirectories // []) + $new.permissions.additionalDirectories | unique)} else {} end))
}
+ (if $new.skipDangerousModePermissionPrompt then {skipDangerousModePermissionPrompt: true} else {} end)
