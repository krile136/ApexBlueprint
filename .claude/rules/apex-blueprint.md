---
paths: ["**/*.cls", "**/*.trigger"]
---

# ApexBlueprint

This project builds test data for integration tests with ApexBlueprint (`SBlueprint.cls`, `SOrchestrator`, `SPersona`).

- When a test needs real records, declare them with `SBlueprint.of(<Object>.class)` and insert them with `SOrchestrator.start().add(...)` and `create()`. Don't hand-write insert chains that carry parent Ids from one statement to the next.
- Hang a child under its parent with `withChildren(...)`. Use `use(alias, 'Id', field)` only for a second reference or to copy a value. Add `parentIdField(field)` when the child has more than one lookup to the parent.
- Put the values every record of an object needs into a `Map` passed to `template(...)`, kept in one test data class. Call `set(...)` only for the fields the test is about, after `template(...)`.
- Every builder method of `SBlueprint`, `SOrchestrator` and `SPersona` (all but `create()` and `getByAlias()`) returns a new instance. Always use the return value. `create()` returns `void`: call it in its own statement, once per orchestrator.
- Give an `alias(...)` to each record you read back with `getByAlias(...)`. An unknown alias returns `null`.
- Create `System.runAs` users with `SPersona`. Declare record owners and manual shares with `owner(user)` and `sharedWith(user, 'Read' | 'Edit')`.
- `ApexBlueprintException` means the declaration is wrong: fix the test code. A `DmlException` from `create()` means the org rejected the data: fix the template or the values.
- Write test descriptions and assert messages in the language the project's tests already use, and keep its case labels (for example `正常系:` / `異常系:` / `エッジケース:`, or `Normal:` / `Error:` / `Edge:`).
- Before writing test data code, load the `apex-blueprint` skill.

These rules don't apply to ApexBlueprint's own source and tests (`SBlueprint.cls`, `SBlueprintAnalyzer.cls`, `SBlueprintRealizer.cls`, `SOrchestrator.cls`, `SPersona.cls`, `ApexBlueprintException.cls`, `DmlOperators/` and their test classes).
