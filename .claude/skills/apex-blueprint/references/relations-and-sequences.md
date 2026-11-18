# Relations and sequences

Patterns for linking records and numbering copies. Examples leave out `template(...)` where it doesn't matter to the pattern; real tests should keep it.

## Choosing between withChildren, use and after

| You want | Write |
|---|---|
| A child that belongs to a parent (master-detail or lookup) | `withChildren(...)` on the parent |
| The same, but the child has several lookups to the parent's object, or a polymorphic field (`WhatId`, `ParentId`) | `withChildren(...)` + `parentIdField('Field')` on the child |
| A child that also points to a second record (another root, a sibling) | `withChildren(...)` for the parent, `use('alias', 'Id', 'Field')` for the second record |
| A copy of a non-Id value from another record | `use('alias', 'FromField', 'ToField')` |
| Insert order only, no field link | `after('alias')` |

`withChildren` infers the parent field from the parent object's child relationships. If exactly one relationship points to the child's type, it is used, even when it is not the field you meant. If several do, `create()` throws "multiple parent relationships". If none does, it throws "No parent relationship field found". Build the tree along master-detail paths, and add `parentIdField` when in doubt.

```apex
SBlueprint.of(Account.class)
  .set('Name', 'Acme')
  .alias('account')
  .withChildren(SBlueprint.of(Contact.class).set('LastName', 'Contact-{#}').alias('contact_{#}').times(3))
  .withChildren(
    SBlueprint.of(Task.class)
      .parentIdField('WhatId')
      .set('Subject', 'Call')
      .alias('task')
  );
```

A file linked to a record. `ContentDocumentId` is filled in when the `ContentVersion` is saved; `use()` reads the saved value:

```apex
SOrchestrator orchestrator = SOrchestrator.start()
  .add(
    SBlueprint.of(ContentVersion.class)
      .set('Title', 'Contract')
      .set('PathOnClient', 'contract.txt')
      .set('VersionData', Blob.valueOf('body'))
      .alias('file')
  )
  .add(SBlueprint.of(Account.class).set('Name', 'Acme').alias('account'))
  .add(
    SBlueprint.of(ContentDocumentLink.class)
      .use('file', 'ContentDocumentId', 'ContentDocumentId')
      .use('account', 'Id', 'LinkedEntityId')
      .set('ShareType', 'V')
      .alias('link')
  );
orchestrator.create();
```

## Order without a link

`after` puts a record in a later layer than the referenced one. It is the only way to order records: inside a layer after layer 0 the order is not the order of `add` calls. It accepts `{#}` patterns: `after('group_{#}')` waits for every record of that alias pattern. It can be combined with `use`.

```apex
SOrchestrator.start()
  .add(SBlueprint.of(Account.class).set('Name', 'Group-{#}').alias('group_{#}').times(2))
  .add(SBlueprint.of(Account.class).set('Name', 'Late').alias('late').after('group_{#}'));
```

## Offsets: linking part of a set

`startAt` and `interval` exist on `set`, `alias`, `use` and `after`. Each one counts on its own. Ten accounts, and five contacts linked to accounts 6 to 10:

```apex
SOrchestrator.start()
  .add(SBlueprint.of(Account.class).set('Name', 'Account {#}').alias('account_{#}').times(10))
  .add(
    SBlueprint.of(Contact.class)
      .set('LastName', 'Contact {#}', 6)
      .use('account_{#}', 'Id', 'AccountId', 6)
      .alias('contact_{#}', 6)
      .times(5)
  );
```

`contact_6` links to `account_6`, ..., `contact_10` to `account_10`. If a pattern reference resolves past the last record (`account_11`), `create()` throws "Alias 'account_11' not found". A literal alias that no blueprint defines (`use('account_11', ...)`) fails earlier, with "Circular or invalid reference detected".

## Multiplied trees and {Pn}

`times` on a parent repeats the whole child set for every parent copy, and the `{#}` sequence of the children restarts for each one. Name children with the parent's alias to keep aliases unique:

```apex
SBlueprint.of(Account.class)
  .set('Name', 'Account {#}')
  .alias('account_{#}')
  .times(2)
  .withChildren(
    SBlueprint.of(Contact.class)
      .set('LastName', 'Contact {#}')
      .alias('{P0}_contact_{#}')
      .times(2)
  );
// account_1_contact_1, account_1_contact_2, account_2_contact_1, account_2_contact_2
```

`{Pn}` counts from the root: `{P0}` is the root, `{P1}` the next level down. It stands for the resolved alias of the actual ancestor of each copy, so it also works as the alias of `use`:

```apex
SBlueprint.of(Account.class)                      // P0
  .set('Name', 'Account {#}')
  .times(2)
  .withChildren(
    SBlueprint.of(Contact.class)                  // P1
      .parentIdField('AccountId')
      .set('LastName', 'Contact {#}')
      .times(2)
      .withChildren(
        SBlueprint.of(Case.class)                 // P2
          .parentIdField('ContactId')
          .use('{P1}', 'LastName', 'Subject')     // the LastName of this case's own contact
          .times(2)
      )
  );
```

This makes 2 accounts, 4 contacts and 8 cases.

## Records of the same object

References between records of one object work like any other. The referenced record goes in an earlier layer, even when both are children of the same parent:

```apex
SBlueprint.of(Account.class)
  .set('Name', 'Acme')
  .withChildren(
    SBlueprint.of(Case.class)
      .parentIdField('AccountId')
      .set('Subject', 'Parent case')
      .alias('parentCase')
  )
  .withChildren(
    SBlueprint.of(Case.class)
      .parentIdField('AccountId')
      .set('Subject', 'Child case')
      .use('parentCase', 'Id', 'ParentId')
  );
```

## Adding to data from another orchestrator

An orchestrator creates once, and its aliases are not visible to other orchestrators. To add records to data made earlier (for example in a shared setup method), pass the Id and `set` it. `use` still works between records of the new orchestrator:

```apex
Id accountId = createBaseAccount(); // made by another orchestrator

SOrchestrator extra = SOrchestrator.start()
  .add(SBlueprint.of(Case.class).set('AccountId', accountId).set('Subject', 'Parent').alias('parentCase'))
  .add(
    SBlueprint.of(Case.class)
      .set('AccountId', accountId)
      .set('Subject', 'Child')
      .use('parentCase', 'Id', 'ParentId')
  );
extra.create();
```

A blueprint itself can be reused: adding the same `SBlueprint` to two orchestrators creates two independent sets of records.

## Checking a declaration without DML

`SOrchestrator.start(new MockDmlOperator())` builds the records and gives them fake Ids without inserting. It checks the declaration (aliases, references, field names), not the org: no triggers, no validation, no required fields. A non-Id `use()` copies the in-memory value there, not a saved one. Use real DML in tests of your own code.
