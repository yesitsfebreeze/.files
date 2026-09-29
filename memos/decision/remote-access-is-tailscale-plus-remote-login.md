---
kind: decision
date: 2026-09-29
status: decided
description: A tailnet peer reaches this machine over the built-in sshd (Remote Login) with a key, not over Tailscale SSH or a public tunnel
read_when: "giving a remote agent (a chat's command runner, another machine) a way to run commands here, or asking why kern is not served publicly"
---

# remote-access-is-tailscale-plus-remote-login

## Decision

Remote access to this machine is Tailscale (the `tailscale-app` cask) plus
macOS Remote Login, the built-in sshd. `install.sh` turns Remote Login on;
signing in to Tailscale is a GUI step it only hints at. A peer on the tailnet
runs commands with plain ssh and a key in `~/.ssh/authorized_keys`:

```
ssh feb@<machine>.<tailnet>.ts.net 'cd ~/dev/kern2 && kern call '"'"'{"op":"status"}'"'"''
```

## Why

- Tailscale SSH (keyless, tailnet identity) needs the open-source `tailscaled`
  variant on macOS; the GUI app cannot be a server. The GUI app is the
  supported daily driver, so sshd carries the connection.
- Public tunnels were tried first and each failed a chat's URL reader:
  serveo and pinggy front every html client with a "Continue" page, Cloudflare
  quick tunnels answer 403, localhost.run answers "no tunnel here" on most
  requests. Tailscale Funnel works but is public by design; `kern share`
  keeps it for a chat that can only open URLs, behind a random path key.
- sshd is already on the machine; no package, no daemon of its own.

## Consequences

- One sudo prompt in `install.sh`: `launchctl load -w` on the sshd job.
  `systemsetup -setremotelogin on` is not used: it wants Full Disk Access
  for the terminal on top of sudo.
- The tailnet ACL is the gate; the default policy admits every peer, so a
  remote agent's runtime must be a tailnet node and hold an authorized key.
- `kern call` must run inside the project directory; the ssh command carries
  the `cd`.
