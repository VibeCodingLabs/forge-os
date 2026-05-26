# ForgeOS Master Operating Agreement

FORGE.md is the Master Operating Agreement for ForgeOS.

It defines how humans, AI agents, automation scripts, and future orchestration systems must behave when working in this repository.

This file is not a roadmap. Roadmaps, phases, task waves, and setup lanes belong in `docs/`.

## Mission

ForgeOS exists to provide a secure, reproducible, post-wipe command-center bootstrap for Debian-based AI automation workstations.

The system must help an operator rebuild quickly, work safely, automate responsibly, and preserve quality under pressure.

## Ethical foundation

All ForgeOS work is governed by these virtues:

1. Truth
2. Honor
3. Courage
4. Discipline
5. Perseverance
6. Fidelity
7. Industriousness
8. Self-Reliance
9. Hospitality

These are operating principles, not decoration. They apply to code, docs, automation, security decisions, agent behavior, and user interaction.

## Core rules

### Truth

- Do not fabricate capabilities, test results, citations, commits, file contents, package support, or security guarantees.
- State uncertainty clearly.
- Verify current software, security, and install information before presenting it as fact.
- When a command has not been tested, say so.

### Honor

- Respect the operator, the system, and the downstream users affected by this work.
- Keep private material private.
- Do not smuggle secrets, credentials, reports, customer data, or personal evidence into public files.
- Do not misrepresent generated work as tested production code unless it has actually been tested.

### Courage

- Identify problems directly.
- Flag unsafe assumptions, brittle scripts, supply-chain risks, insecure defaults, and missing tests.
- Prefer a clear correction over quiet agreement.

### Discipline

- Use plan-first, create-second workflows for substantial changes.
- Keep changes scoped.
- Preserve working recovery paths.
- Prefer reversible operations.
- Use explicit logs for privileged or destructive commands.

### Perseverance

- Favor incremental progress over abandoned complexity.
- Build thin, working layers before elaborate systems.
- Keep the HP14 lab path stable before promoting changes to the main workstation.

### Fidelity

- Follow the operator's naming, architecture, and product boundaries.
- Use Forge Symphony for the platform name when discussing that project.
- Use ForgeOS for this recovery and command-center bootstrap repo.
- Preserve brand names exactly: VibeCodingLabs, Phantom Digital LLC, CakeWorld AI, CakeVoid Productions, CakeVoid Prod., Cakeboys Entertainment, Cakeboys Ent.

### Industriousness

- Automate repetitive work.
- Create scripts, manifests, docs, and checks that make future work faster.
- Prefer maintainable automation over one-off magic.
- Leave the repo easier to operate than it was found.

### Self-Reliance

- Prefer local-first recovery paths.
- Keep critical bootstrap steps possible from a fresh Debian install with minimal dependencies.
- Do not depend on cloud services for core recovery.
- Keep private overrides separate from public bootstrap code.

### Hospitality

- Make the repo understandable to the future operator returning after a wipe, outage, or emergency.
- Use clear names, direct instructions, and sane defaults.
- Write docs for a tired human at a terminal, not only for the person who authored the system.

## Quality standard

All work must aim for production-grade reliability, even when the current implementation is a prototype.

Required standards:

- Clear purpose
- Minimal surprise
- Safe defaults
- Explicit privilege boundaries
- Idempotent or safely repeatable scripts where practical
- Logs for install actions
- No silent destructive behavior
- No hidden network exfiltration
- No secrets in source control
- No hallucinated package names or commands
- Clear separation between public bootstrap and private operator data

## Documentation standard

Docs must be current, direct, and operational.

- README.md explains what the repo is and how to use it.
- FORGE.md defines this operating agreement.
- AGENTS.md defines agent conduct, roles, and permissions.
- SECURITY.md defines safe-use and reporting policy.
- `docs/COMMAND_CENTER_TASK_MAP.md` contains setup lanes, phases, and implementation tasks.
- Manifests describe install profiles and package groups.

Do not put long task maps in FORGE.md.

## Security requirements

ForgeOS must be security-first.

- Least privilege by default.
- No credentials in public files.
- No bug bounty evidence in this repo.
- No customer data in this repo.
- No automatic execution of untrusted code without review.
- External installers must be treated as supply-chain risk.
- Privileged commands must be visible and intentional.
- Sensitive actions should require explicit operator approval.
- Agent sandboxes must not receive secrets by default.

## Agent operating rules

AI agents and automation helpers must obey these rules:

- Read relevant repo files before modifying them.
- Do not invent files, commits, packages, or test results.
- Keep commits small and named clearly.
- Preserve existing work unless replacement is explicitly requested.
- Prefer additive changes unless a file is known to be wrong.
- Do not overwrite user configs without backup or explicit operator intent.
- Do not run destructive commands by default.
- Do not escalate privileges without explaining why the privilege is needed.
- Do not install offensive tools without responsible-use boundaries.
- Do not route private audio, video, credentials, or evidence to cloud services without policy approval.

## Testing expectations

Before calling work complete, agents should attempt the safest relevant checks available:

- shell syntax checks for shell scripts
- markdown linting where available
- Go build checks for Go TUI code
- Rust checks for Rust crates when added
- dry-run or preflight modes for installers where possible
- manual smoke-test notes when full testing is not possible

When tests cannot be run, state exactly what was not run.

## Change management

Substantial changes should follow this order:

1. Restate the goal.
2. Identify affected files.
3. Preserve or migrate existing useful content.
4. Apply the smallest complete patch.
5. Document what changed.
6. State what was not tested.

## Approval boundaries

The following actions require explicit operator approval or a clearly selected installer menu option:

- package installation
- service enablement
- changing default shell
- modifying SSH configuration
- modifying firewall rules
- deleting files
- formatting disks
- changing partitions
- uploading data to cloud APIs
- pushing to GitHub
- running security scanners against external targets
- launching agents with filesystem, browser, network, or credential access

## Definition of done

A ForgeOS change is done only when:

- the file purpose is clear
- the recovery path remains understandable
- dangerous behavior is avoided or gated
- public/private boundaries are preserved
- docs match implementation
- untested assumptions are named
- the operator can continue from a clean Debian machine

## Final rule

ForgeOS must help the operator rebuild, ship, and secure systems without creating hidden risk.

When speed and safety conflict, choose the fastest safe path, not the most impressive risky path.
