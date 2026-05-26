# ForgeOS Security Policy

ForgeOS is a public bootstrap repository for rebuilding a secure Debian-based AI automation workstation.

Security is a design requirement, not an afterthought.

## Scope

This policy applies to:

- install scripts
- shell configs
- terminal configs
- TUI code
- manifests
- systemd user services and timers
- documentation
- future local agent orchestration components

## Public repo boundary

This repository may contain:

- bootstrap scripts
- package manifests
- safe example configs
- documentation
- templates
- local-only helper scripts

This repository must not contain:

- API keys
- SSH private keys
- cloud credentials
- access tokens
- production secrets
- private customer data
- personal identity material
- private screenshots or recordings
- responsible disclosure materials

## Installer safety rules

Installers should:

- be readable before execution
- log actions to `~/.forge-os/logs`
- avoid destructive behavior
- avoid silent privilege escalation
- keep privileged commands explicit
- prefer Debian packages where practical
- treat external installers as supply-chain risk
- avoid changing default shell, SSH, firewall, or services without a clear operator action

## Agent and automation safety

Automation must follow least privilege.

Sensitive actions require explicit operator approval or a clearly selected installer menu action:

- installing packages
- enabling services
- changing SSH behavior
- changing firewall behavior
- uploading data to cloud services
- modifying credentials
- launching browser automation with logged-in sessions
- running scanners against systems not owned or authorized by the operator
- deleting files or modifying partitions

## Responsible use

ForgeOS may include defensive security tools and authorized testing utilities.

Use them only in environments where testing is permitted.

Do not use this repository to target third-party systems without authorization.

## Dependency hygiene

Preferred order:

1. Debian packages
2. language package managers with lockfiles where practical
3. pinned releases for external tools
4. reviewed external install scripts only when necessary

Future hardening targets:

- shellcheck workflow
- markdown lint workflow
- Go build workflow
- dependency scanning
- secret scanning
- installer smoke tests
- checksums for high-risk downloads

## Reporting issues

For normal repo issues, use GitHub Issues.

For sensitive security concerns, do not post private details publicly. Use a private channel controlled by the repository owner.

## Operator checklist before public push

Before pushing changes, verify:

- no credentials are present
- no private materials are present
- no destructive commands run by default
- docs match the actual install path
- new services are opt-in or clearly selected
- risky package sources are documented
