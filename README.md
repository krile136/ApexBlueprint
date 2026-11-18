# ApexBlueprint

**A declarative test data builder that revolutionizes test data creation in Salesforce.**

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

📚 **Documentation: [krileworks.com](https://krileworks.com/apex-stem/docs/apex-blueprint-guide)** — guides, API reference, and design deep-dives all live there.
(日本語ドキュメント: [https://krileworks.com/ja/apex-stem/docs/apex-blueprint-guide](https://krileworks.com/ja/apex-stem/docs/apex-blueprint-guide))

ApexBlueprint is part of [**Apex Stem**](https://krileworks.com/apex-stem), a set of independent, dependency-free Salesforce Apex frameworks.

## Installation

### A) Unlocked Package (recommended)

```bash
sf package install -p 04tgK000000b1LJQAY -o <your-org> -w 10
```

Or install from the browser:

- Production / Developer Edition: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04tgK000000b1LJQAY`
- Sandbox: `https://test.salesforce.com/packaging/installPackage.apexp?p0=04tgK000000b1LJQAY`

Current version: **v2.2.1** (`04tgK000000b1LJQAY`). Install IDs for every release are listed on the [Releases](https://github.com/krile136/ApexBlueprint/releases) page.

Why the package: tests inside an installed unlocked package are **excluded from `RunLocalTests`**, and its code is **excluded from your org's coverage calculation** — your deploys stay fast and unaffected by this framework's test suite.

### B) Git Submodule

```bash
git submodule add https://github.com/krile136/ApexBlueprint.git force-app/main/default/classes/ApexBlueprint
git submodule update --init --recursive
```

`sf project deploy start -d force-app/main/default/classes/ApexBlueprint` deploys it like any source folder. A Makefile is also included for direct installs (`make install`).

## AI agents

This repository ships an agent skill and a rule for [Claude Code](https://claude.com/claude-code) under `.claude/`:

| Path | Purpose |
|---|---|
| `.claude/rules/apex-blueprint.md` | Short rules applied to `*.cls` and `*.trigger` files: declare test data with `SBlueprint` + `SOrchestrator`, nest children with `withChildren`, keep shared values in `template()`, create `runAs` users with `SPersona` |
| `.claude/skills/apex-blueprint/` | `SBlueprint`, `SOrchestrator` and `SPersona`: declaring records, placeholders, insert order, bulk data, users and sharing, errors |

The skill describes the version of the tag it comes from. After you upgrade ApexBlueprint, update the skill from the matching tag too.

### Git submodule or clone

The files are already in your project inside the ApexBlueprint folder. Claude Code picks them up once it reads a file in that folder. Nothing to copy.

### Unlocked package

The package installs only Apex classes. Copy the skill and the rule from the git tag that matches your installed version (replace `v2.2.1` with it):

```bash
rm -rf /tmp/apex-blueprint
git clone --depth 1 --branch v2.2.1 https://github.com/krile136/ApexBlueprint.git /tmp/apex-blueprint
mkdir -p .claude/skills .claude/rules
cp -r /tmp/apex-blueprint/.claude/skills/* .claude/skills/
cp /tmp/apex-blueprint/.claude/rules/apex-blueprint.md .claude/rules/
```

Run it from your project root. It overwrites earlier copies of this skill and leaves your other skills alone.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
