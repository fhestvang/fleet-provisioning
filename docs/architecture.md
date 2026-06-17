# Architecture & migration status

## Why

The fleet (Spark + eigil/ingvild/dicte/pi3 + future Scaleway VPCs) was converging
via three hand-rolled mechanisms:

1. `dotfiles/install.sh` + a commit-hook push fan-out (tools, stow, plugins)
2. `agent-sync` (agent runtime/skill definitions, agent hosts only)
3. `dotfiles-fleet-linear-key` (materialize secrets from Bao to the fleet)

These are a hand-rolled version of one capability: *bring a machine to parity*.
This repo converges them onto established tools.

## Target model

```
            ┌──────────────────────────── Ansible ───────────────────────────┐
            │  system plane (packages/sudo, services, users)  +  orchestration │
            │  static inventory (pets) + Scaleway dynamic inventory (VPCs)      │
            └───────────────────────────────┬─────────────────────────────────┘
                                             │ runs, per host
                                             ▼
            ┌──────────────────────────── chezmoi ───────────────────────────┐
            │  user-env plane: dotfiles, tools, shell, agent defs, secrets     │
            │  pull-model: `chezmoi init --apply`; per-machine data; Bao secrets│
            └─────────────────────────────────────────────────────────────────┘
```

- **Pull** (chezmoi / `ansible-pull`) self-converges a box — scales to VPCs that
  boot and provision themselves (cloud-init runs the bootstrap).
- **Push** (`ansible-playbook site.yml`) converges the known fleet from a control
  node.

## VPC path (cattle), when instances exist

1. Terraform/OpenTofu creates instances tagged `fleet`.
2. cloud-init: install Tailscale with an ephemeral, tagged, pre-auth key (joins
   the tailnet, no manual key copy), then `chezmoi init --apply`.
3. `inventory/scaleway.yml` auto-discovers them by tag for ongoing Ansible runs.
4. Access via Tailscale SSH + ACLs (no per-host authorized_keys / known_hosts).

## Migration status

| Phase | State |
|---|---|
| chezmoi installed (Spark) + repo scaffolded | ✅ done |
| chezmoi source: per-machine data, install.sh driver, agent-sync, Linear secret | ✅ done |
| Validated rendering on Spark (data + secret) without mutating any home | ✅ done |
| Ansible scaffold: inventory (static + Scaleway stub), site.yml, chezmoi role | ✅ done |
| **Apply on a live fleet box** (real cutover) | ⏳ deliberate, one box at a time |
| Retire the dotfiles commit-hook fan-out after cutover | ⏳ pending |
| **Bao reachable from the fleet** (CA trust + AppRole) | ❌ blocker — gates fleet secret rendering + Ansible vault + VPCs |
| System Ansible role (sudo packages/services) | ⏳ stub |

## Known blocker: OpenBao from the fleet — it's a Tailscale ACL

Diagnosed 2026-06-17. Bao runs on eigil (`:8200`, exposed via Tailscale Serve and
reachable from Spark at `bao.olm-hops.ts.net`). The tinys **cannot reach eigil on
any port** — `dicte -> 100.87.251.112:{22,8200}` both time out, while
`spark -> eigil:8200` is open. So it is not TLS/DNS/cert/auth: the tinys are
locked-down `tagged-devices` that the tailnet **ACL** does not permit to initiate
connections to eigil (Spark can reach them; they can't reach back). MagicDNS is
also not resolving on the tinys (secondary).

**Fix (admin console only — cannot be done from the machines):** add an ACL grant
allowing the fleet tag to reach the Bao host/port, e.g.

```jsonc
// tailnet policy
{ "action": "accept", "src": ["tag:fleet"], "dst": ["<eigil/bao>:8200"] }
```

and enable MagicDNS / `--accept-dns` on the fleet nodes so `bao.olm-hops.ts.net`
resolves there. Once the tinys can reach Bao + have a scoped read-only token in
`~/.vault-token`, `baoReachable` flips true, chezmoi renders secrets on every box,
and `dotfiles-fleet-linear-key` can be retired. Same unlock serves Ansible
`hashi_vault` and the VPC cattle path.
