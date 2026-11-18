---
name: apex-blueprint
description: Apex integration-test data with ApexBlueprint, declared as SBlueprint graphs and inserted with real DML by SOrchestrator. Use when writing or fixing @IsTest data setup in a project that contains SBlueprint.cls, including SBlueprint.of / set / template / alias / use / after / times / withChildren / parentIdField / owner / sharedWith, SOrchestrator.start / add / create / getByAlias, sequence placeholders {#} / {A} / {a} and parent placeholders {P0} / {P1}, startAt / interval offsets, bulk data with times(201), SPersona.of / profile / permissionSets / set / create for System.runAs users, MockDmlOperator, replacing hand-written insert chains or test data factories, and errors such as "Circular or invalid reference detected", "Duplicate alias detected", "multiple parent relationships with the same parent object", "No parent relationship field found", "Alias '...' not found", "Failed to apply field", "Share object ... was not found", "The share target is the declared owner" or "could not be read back". Not for editing ApexBlueprint's own source.
---

# ApexBlueprint: Test Data

An `SBlueprint` declares records as their final state: field values, how many, and which parent they hang under. `SOrchestrator` works out the insert order from the parent links and `use()` references, inserts the records with real DML one layer at a time, and hands them back by alias. The test never carries Ids from one insert to the next. Use it where a test needs real records: triggers, flows, formulas, roll-ups, validation rules, sharing. Unit tests that don't need the database are better served by mocks.

## Rules

1. Every builder method of `SBlueprint`, `SOrchestrator` and `SPersona` (all but `create()` and `getByAlias()`) returns a new instance. A call whose result is discarded does nothing: chain or reassign.
2. `create()` returns `void`. Keep the orchestrator in a variable, then call `create()` in its own statement. Call it once per orchestrator, and don't `add()` to an orchestrator that has already run `create()`.
3. Hang children under their parent with `withChildren(...)`. The parent Id is filled in for you. Use `use()` only for a second reference (another root, a sibling) or to copy a field value.
4. Put the values every record of an object needs (required fields, record type, values validation rules expect) into a `Map` returned by one test data class, and pass it to `template(...)`. Call `set(...)` only for fields the test is about.
5. Write `template(...)` first, then `set(...)`. Both write the same field map, and the later call wins.
6. Give an `alias(...)` to every record you read back. `getByAlias(...)` returns `null` for an unknown alias, and children without an alias get generated names you should not rely on.
7. Write the blueprint's own calls (`template`, `set`, `alias`, `times`) before `withChildren(...)`, so the parent's settings don't appear after the child block.
8. `ApexBlueprintException` means the declaration is wrong. A `DmlException` from `create()` means the org refused the data (missing required field, validation rule).
9. Write test descriptions and assert messages in the language the project's tests already use (see "Test descriptions").

## Example

```apex
@IsTest
private class CaseEscalationTest {
  @IsTest
  static void escalatesCasesOfKeyAccounts() {
    SOrchestrator orchestrator = SOrchestrator.start()
      .add(
        SBlueprint.of(Account.class)
          .template(Blueprints.accountBasic())
          .set('Rating', 'Hot')
          .alias('account')
          .withChildren(
            SBlueprint.of(Contact.class)
              .template(Blueprints.contactBasic())
              .alias('contact')
              .withChildren(
                SBlueprint.of(Case.class)
                  .template(Blueprints.caseBasic())
                  .parentIdField('ContactId')
                  .use('account', 'Id', 'AccountId')
                  .alias('case')
              )
          )
      );
    orchestrator.create();

    Case created = (Case) orchestrator.getByAlias('case');
    Assert.isNotNull(created, 'Normal: the case alias exists.');
    Case saved = [SELECT Priority FROM Case WHERE Id = :created.Id];
    Assert.areEqual('High', saved.Priority, 'Normal: a case of a hot account is escalated.');
  }
}
```

The test data class holds plain maps, one method per object. It needs no `@IsTest` when non-test code also uses it.

```apex
public with sharing class Blueprints {
  public static Map<String, Object> accountBasic() {
    return new Map<String, Object>{ 'Name' => 'Test Account' };
  }
  public static Map<String, Object> contactBasic() {
    return new Map<String, Object>{ 'LastName' => 'Test Contact' };
  }
  public static Map<String, Object> caseBasic() {
    return new Map<String, Object>{ 'Origin' => 'Web' };
  }
  public static Map<String, Object> opportunityBasic() {
    return new Map<String, Object>{
      'Name' => 'Test Opportunity',
      'StageName' => 'Prospecting',
      'CloseDate' => Date.today().addDays(30)
    };
  }
}
```

When the org adds a required field, only that object's method changes. Keep the methods free of branches; put scenario differences in `set(...)` in the test.

## SBlueprint

| Method | Does |
|---|---|
| `of(Account.class)` | starts a blueprint. A type that is not an SObject throws |
| `set(field, value)` | sets one field. Text values may hold placeholders (below) |
| `set(field, value, startAt[, interval])` | the same, with the `{#}` sequence starting at `startAt` and stepping by `interval` |
| `template(Map<String, Object>)` | sets every key of the map. Overrides values set earlier |
| `alias(name[, startAt[, interval]])` | names the record. With `{#}` in the name, each copy gets its own name |
| `times(n)` | makes `n` records. `n` must be greater than 0 |
| `withChildren(child)` | adds a child blueprint. Call it once per child kind |
| `parentIdField(field)` | the child's field that receives the parent Id. Needed when the child has several lookups to the parent's object |
| `use(alias, fromField, toField[, startAt[, interval]])` | copies `fromField` of the record named `alias` into `toField`. The referenced record is inserted first |
| `after(alias[, startAt[, interval]])` | inserts this record after the record named `alias`, copying nothing. For trigger order |
| `owner(user)` | `set('OwnerId', user.Id)` |
| `sharedWith(user, accessLevel)` | adds a manual share row (`'Read'` or `'Edit'`) for the record. See [references/personas-and-sharing.md](references/personas-and-sharing.md) |

- Field names are strings and are not checked when you call `set` or `template`. At `create()`, a field the record refuses (wrong name, formula, auto number, other read-only field, value of the wrong type) throws `ApexBlueprintException` "Failed to apply field ..." with the alias, the source (`set() / template()` or `use(...)`) and the reason.
- A `null` field name in `set(...)` or a `null` key in the `template(...)` map has no guard: `create()` fails with a platform exception, not `ApexBlueprintException`.
- Checked when the method is called: a null or non-SObject type in `of`, a null `alias` (`alias`, `use`, `after`), a null `fromField` / `toField`, a null map, child or blueprint (`add`), a null `times` or `times(0)`, a `startAt` or `interval` that is null or 0 or less, a user that is null or has no Id (`owner`, `sharedWith`), and an access level other than `'Read'` / `'Edit'`. Everything else is checked at `create()`. A null or blank `parentIdField` falls back to inference.

## Placeholders

| Placeholder | Becomes | Works in |
|---|---|---|
| `{#}` | `1, 2, 3, ...` (or from `startAt`, by `interval`) | text values of `set` / `template`, `alias`, the alias argument of `use` / `after` |
| `{A}` / `{a}` | `A, B, C, ...` / `a, b, c, ...` (`AA` after `Z`) | the same |
| `{P0}`, `{P1}`, ... | the resolved alias of the ancestor at that depth from the root (`{P0}` is the root) | the same, in nested blueprints |

- The sequence restarts for each parent copy. Under `Account.times(2)`, a child `alias('contact_{#}').times(2)` makes `contact_1` twice and fails with "Duplicate alias detected". Prefix the parent: `alias('{P0}_contact_{#}')` gives `account_1_contact_1`, `account_2_contact_1`, ...
- A value of exactly `'{#}'` becomes an `Integer`. Use it for number fields. For text fields, add text around it: `'Contact-{#}'`.
- `set('Name', 'Account {#}')` without `times` gives `Account 1`.

See [references/relations-and-sequences.md](references/relations-and-sequences.md) for offsets, `{Pn}` in deep trees, self-references and second orchestrators.

## SOrchestrator

| Method | Does |
|---|---|
| `SOrchestrator.start()` | a new orchestrator with real DML |
| `SOrchestrator.start(new MockDmlOperator())` | no DML; records get fake Ids. Only for checking the declaration itself |
| `add(blueprint)` | queues a root blueprint. References decide the layers, not the order of `add` calls |
| `create()` | resolves references, then inserts layer by layer. Returns `void` |
| `getByAlias(alias)` | the created `SObject` (cast it), or `null` |

What `getByAlias` returns:

- the Id and the fields the blueprint set. Fields not set read as `null`.
- Values Salesforce fills in on save (defaults, auto numbers, formulas, values from triggers and flows) are not there. Query the record when you assert on them.
- Exception: a record that a later `use()` copied a non-Id field from also holds the saved values of the fields read back for it.

How `create()` runs:

- Records with no reference go in layer 0. A record goes one layer after everything it references (`withChildren`, `use`, `after`). Each layer is inserted before the next one is built, so references get real Ids.
- Only layer 0 keeps the order of the `add` calls. Don't rely on the order of records inside a later layer; when one record must be inserted before another, use `after(...)`.
- Records of one layer go in one insert. When a layer holds more than 10 object types or more than 10 chunks (a chunk ends where the type changes, or after 200 records of one type), the insert is split at that point. A layer of one type is never split.
- `use()` of `Id` costs no SOQL. `use()` of any other field reads the referenced records back before copying: one SOQL query per source object type per layer, in system mode. Values filled in on save are copied correctly.
- Aliases are resolved only within one orchestrator. To add records to data made by another orchestrator, `set(...)` the Id directly (see the reference).

## Bulk data

```apex
SOrchestrator orchestrator = SOrchestrator.start()
  .add(
    SBlueprint.of(Account.class)
      .template(Blueprints.accountBasic())
      .withChildren(
        SBlueprint.of(Opportunity.class)
          .template(Blueprints.opportunityBasic())
          .parentIdField('AccountId')
          .set('Name', 'Opportunity {#}')
          .times(201)
      )
  );
Test.startTest();
orchestrator.create();
Integer queriesUsed = Limits.getQueries();
Test.stopTest();
```

- `times` multiplies down the tree: `Account.times(2)` with `Contact.times(3)` makes 6 contacts. Watch the 10,000 DML row limit with deep trees.
- Salesforce runs triggers in chunks of 200 records, so 201 records reach a second chunk.
- `create()` can be the action under test: insert triggers fire on the records it inserts.
- Read `Limits` before `Test.stopTest()`. After it, the counters show the values from before `Test.startTest()`.
- A non-Id `use()` adds its SOQL queries to `Limits.getQueries()` when `create()` runs inside `Test.startTest()`. To measure only your code, call `create()` before `Test.startTest()` and act with your own DML.

## Users and sharing

```apex
User rep = SPersona.of('sales-rep')
  .profile('Standard User')
  .permissionSets('Sales_Read_Only')
  .create();
User admin = SPersona.of('admin').profile('System Administrator').create();

SOrchestrator orchestrator = SOrchestrator.start()
  .add(
    SBlueprint.of(Account.class)
      .template(Blueprints.accountBasic())
      .owner(admin)
      .sharedWith(rep, 'Read')
      .alias('account')
  );
orchestrator.create();

System.runAs(rep) {
  // the code under test, seeing the record through a Read share only
}
```

Profile names are the names shown in Setup and depend on the org's language. Details, defaults and errors: [references/personas-and-sharing.md](references/personas-and-sharing.md).

## Test descriptions

Write test descriptions, comments and assert messages in the language the project's existing tests use. If the project labels test cases, keep its labels and put them first:

| Language | Labels |
|---|---|
| Japanese | `正常系:` / `異常系:` / `エッジケース:` |
| English | `Normal:` / `Error:` / `Edge:` |

Follow the project's own naming for test classes, methods and the test data class. If the project has no tests yet, ask which language to use.

## Errors

| Message (excerpt) | When | Meaning |
|---|---|---|
| "The \`x\` argument is required" / "The \`x\` argument is Invalid." | at the call | null argument, `times(0)`, bad `startAt` / `interval` / access level. "Invalid" also heads the "Alias not found" error and `SPersona.create()` errors |
| "Circular or invalid reference detected" | `create()` | an alias in `use` / `after` is never defined (typo), or references form a loop. The message lists resolved aliases and what each pending one waits for |
| "Duplicate alias detected" | `create()` | two records resolve to the same alias, or `create()` ran again on the same orchestrator |
| "Alias '...' not found. Available aliases: ..." | `create()` | a `{#}` reference resolves past the records that exist (offset or count mismatch) |
| "multiple parent relationships with the same parent object" | `create()` | the child has several lookups to the parent's object. Add `parentIdField` |
| "No parent relationship field found between ..." | `create()` | the child has no lookup to the parent's object. Use `parentIdField`, or don't nest it |
| "Failed to apply field ..." | `create()` | wrong field name, formula, auto number, not createable, or wrong value type |
| `DmlException` | `create()` | the org refused the insert: required field, validation rule, trigger error |

All except `DmlException` are `ApexBlueprintException`.

## Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| Field values or children are missing | A call's result was discarded (`blueprint.set(...);`) | Chain, or reassign `blueprint = blueprint.set(...)` |
| Compile error on `SOrchestrator o = SOrchestrator.start().add(...).create();` | `create()` returns `void` | Assign the orchestrator, then call `o.create();` |
| `set` value is lost | `template(...)` came after `set(...)` | Call `template(...)` first |
| `getByAlias` returns `null` | Typo, no alias on that record, or `create()` not called | Alias it, and `Assert.isNotNull(...)` right after reading |
| The child links to the wrong lookup, or a required master-detail is empty | The parent's object has exactly one relationship to the child type, and it is not the one you meant | Nest along the master-detail path, add `parentIdField(...)`, or reference the other record with `use(...)` |
| Parent and child added side by side, linked by `use(..., 'Id', ...)` | Old style | Nest the child with `withChildren` |
| "Duplicate alias detected" under a multiplied parent | Child alias has only `{#}` | Add `{P0}` (or the right `{Pn}`) to the child's alias |
| "Duplicate alias detected" on a second `create()` | The same orchestrator ran `create()` twice, or `add()` was called on it after `create()` (the copy keeps the old blueprints and aliases). The first layer is inserted again before the error | Create once. Use a new orchestrator for more records |
| `use()` from another orchestrator's alias fails | Aliases don't cross orchestrators | Pass the Id and `set(...)` it |
| "Failed to apply field" with a number placeholder | `'{#}'` alone is an `Integer`, written to a text field | Write `'Name-{#}'` |
| Assert on a formula or default reads `null` | `getByAlias` holds the in-memory record | Query the record by its Id |
| Limits assertion always passes | `Limits` read after `Test.stopTest()` | Read it inside the `startTest` / `stopTest` block |
| "could not be read back" | A non-Id `use()` source was deleted by automation, or a custom `IDmlOperator` writes nothing | Keep the source record, use `MockDmlOperator`, or copy only `Id` |
