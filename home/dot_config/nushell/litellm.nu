# litellm — one launcher across every model provider we can reach.
#
# `cll` picks a model and starts Claude Code on it; `llm` is the catalogue and
# `llm quota` the balances. The heavy lifting lives in ~/.local/bin/{cll,llm-quota}
# so non-nu callers and the gate script share one implementation — this module
# is the interactive skin: the fuzzy picker and tab-completion.
#
# The picker is `input list --fuzzy`, the same one `_claude_login` uses for the
# cc profile list, so fzf stays where it belongs (zoxide's zi/cdi).

# Catalogue rows decorated with the balance of whichever provider serves first.
# A model is only as usable as the credit behind it, so the number rides along.
def _llm_rows [] {
  let cat = (do { ^cll --catalog } | complete)
  if $cat.exit_code != 0 { return [] }
  let q = (do { ^llm-quota --json } | complete)
  let bal = (if $q.exit_code == 0 { $q.stdout | from json } else { {} })
  let known = ($bal | columns)

  $cat.stdout | from json | each {|r|
    let head = ($r.providers | first)
    let left = (if ($head in $known) {
      let e = ($bal | get $head)
      if $e.unit? == "free" { "free" } else if ($e.remaining? | is-empty) { "?" } else { $e.remaining | into string }
    } else if $head == "max-plan" { "plan" } else { "?" })
    {
      model: $r.name
      via: ($r.providers | str join " → ")
      left: $left
    }
  }
}

def _cll_models [] { _llm_rows | get model }

# cll — launch Claude Code on a chosen model. No argument opens cll's own fzf
# picker, grouped by provider; `native:*` rows bypass the proxy and run on the
# Max plan, everything else goes through litellm with its fallback chain.
#
# The picker lives in the script, not here, so every shell gets the same one —
# an earlier split (nushell picker, script launcher) meant a stale shell called
# the script with no model and fell into a fallback path nothing had exercised.
def --wrapped cll [model?: string@_cll_models, ...args] {
  if ($model | is-not-empty) { ^cll $model ...$args } else { ^cll ...$args }
}

# llm — the catalogue as a table: every model, who serves it, what's left.
def llm [] { _llm_rows }

# llm quota — balances per provider. `refresh` re-fetches what has an API;
# `set` records what only a dashboard can tell us (zenmux, opencode).
def "llm quota" [...args] { ^llm-quota ...$args }

# llm regen — rebuild the litellm routing config from live provider inventories,
# then restart the proxy so it picks the new routes up.
def "llm regen" [] {
  ^litellm-gen-config
  print "regenerated ~/.config/litellm/config.yaml — restart litellm-up to apply"
}
