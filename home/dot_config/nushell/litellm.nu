# litellm.nu
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

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

def --wrapped cll [model?: string@_cll_models, ...args] {
  if ($model | is-not-empty) { ^cll $model ...$args } else { ^cll ...$args }
}

def llm [] { _llm_rows }

def "llm quota" [...args] { ^llm-quota ...$args }

def "llm regen" [] {
  ^litellm-gen-config
  print "regenerated ~/.config/litellm/config.yaml — restart litellm-up to apply"
}
