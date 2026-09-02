# probe — measure the shell surface's two directions before writing the resolver.
let dir = ($nu.home-dir | path join ".config" "nushell" "help")
let corpus = (["shell" "nvim" "terminal" "capsule"] | each {|f| open ($dir | path join $"($f).nuon") } | flatten)
let targets = ($corpus | each {|e| $e.verify | each {|t| $t | insert entry $e.id? } } | flatten)

let doc_kb = ($targets | where kind == "keybinding" | get name)
let doc_al = ($targets | where kind == "alias" | get name)
let doc_cm = ($targets | where kind == "command" | get name)

let live_kb = ($env.config.keybindings | get name | uniq)
let live_al = (scope aliases | get name)
let live_cm = (scope commands | where type == "custom" | get name)

print $"keybinding  documented ($doc_kb | length)  live ($live_kb | length)"
print $"  stale        : ($doc_kb | where {|n| $n not-in $live_kb} | str join ', ')"
print $"  undocumented : ($live_kb | where {|n| $n not-in $doc_kb} | str join ', ')"
print ""
print $"alias       documented ($doc_al | length)  live ($live_al | length)"
print $"  stale        : ($doc_al | where {|n| $n not-in $live_al} | str join ', ')"
print $"  undocumented : ($live_al | where {|n| $n not-in $doc_al} | str join ', ')"
print ""
print $"command     documented ($doc_cm | length)  live ($live_cm | length)"
print $"  stale        : ($doc_cm | where {|n| $n not-in $live_cm} | str join ', ')"
print $"  undocumented : ($live_cm | where {|n| $n not-in $doc_cm} | length) ->"
print ($live_cm | where {|n| $n not-in $doc_cm} | str join ', ')
