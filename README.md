# ApexBlueprint

**A declarative test data builder that revolutionizes test data creation in Salesforce.**

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

📚 **Documentation: [krileworks.com](https://krileworks.com/apex-stem/docs/apex-blueprint-guide)** — guides, API reference, and design deep-dives all live there.
(日本語ドキュメント: [https://krileworks.com/ja/apex-stem/docs/apex-blueprint-guide](https://krileworks.com/ja/apex-stem/docs/apex-blueprint-guide))

ApexBlueprint is part of [**Apex Stem**](https://krileworks.com/apex-stem), a set of independent, dependency-free Salesforce Apex frameworks.

## Installation

### A) Unlocked Package (recommended)

```bash
sf package install -p 04tgK000000HuDtQAK -o <your-org> -w 10
```

Or install from the browser:

- Production / Developer Edition: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04tgK000000HuDtQAK`
- Sandbox: `https://test.salesforce.com/packaging/installPackage.apexp?p0=04tgK000000HuDtQAK`

Current version: **v2.1.0** (`04tgK000000HuDtQAK`). Install IDs for every release are listed on the [Releases](https://github.com/krile136/ApexBlueprint/releases) page.

Why the package: tests inside an installed unlocked package are **excluded from `RunLocalTests`**, and its code is **excluded from your org's coverage calculation** — your deploys stay fast and unaffected by this framework's test suite.

### B) Git Submodule

```bash
git submodule add https://github.com/krile136/ApexBlueprint.git force-app/main/default/classes/ApexBlueprint
git submodule update --init --recursive
```

`sf project deploy start -d force-app/main/default/classes/ApexBlueprint` deploys it like any source folder. A Makefile is also included for direct installs (`make install`).

## License

Apache License 2.0 — see [LICENSE](LICENSE).
