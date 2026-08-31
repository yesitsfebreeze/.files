# recents.nu
# Why this file is shaped the way it is:
#   docs-site → Internals → Nushell modules

const RECENTS_CAP = 200

export def _recents_file [] {
    (_state_dir) | path join "recents.nuon"
}

export def _recents_key [e] {
    $"($e.channel)(char us)($e.value)"
}

export def _recents_load [] {
    let f = (_recents_file)
    if not ($f | path exists) { return [] }
    try {
        let v = (open --raw $f | from nuon)
        let t = ($v | describe)
        if ($t | str starts-with "list") or ($t | str starts-with "table") { $v } else { [] }
    } catch { [] }
}

export def _recents_add [kind: string, value: string, channel: string] {
    let e = {
        kind: $kind
        value: $value
        channel: $channel
        cwd: $env.PWD
        ts: (date now)
    }
    let k = (_recents_key $e)
    let rest = (_recents_load | where {|it| (_recents_key $it) != $k })
    ([$e] | append $rest | first $RECENTS_CAP) | to nuon | save -f (_recents_file)
}

export def _recents_lines [] {
    _recents_load
    | each {|e| [$e.kind $e.value $e.cwd $e.channel] | str join (char tab) }
    | str join (char nl)
}
