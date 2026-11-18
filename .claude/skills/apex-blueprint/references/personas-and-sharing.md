# Personas and sharing

For tests that run code as a restricted user with `System.runAs`: create the user with `SPersona`, and declare who owns each record and who it is shared with on the blueprint.

## SPersona

```apex
User rep = SPersona.of('sales-rep')
  .profile('Standard User')
  .permissionSets(new List<String>{ 'Sales_Read_Only', 'Case_Editor' })
  .set('Department', 'Sales')
  .create();
```

| Method | Does |
|---|---|
| `SPersona.of(name)` | starts a persona. `name` becomes the `LastName` and the seed of `Alias` and `Username` |
| `profile(profileName)` | the Profile by its Name, looked up at `create()` and cached, so personas with the same profile in one test cost one query |
| `permissionSets(name)` / `permissionSets(List<String>)` | permission sets to assign, by API name (`Name`), not label. Adds to earlier calls |
| `set(field, value)` | any `User` field. The last call for a field wins. `set('ProfileId', id)` replaces `profile(...)` |
| `create()` | inserts the user and the assignments, and returns the `User` with its Id |

- `create()` inserts a new user every time. Keep the `User` in a variable instead of calling it twice.
- The inserts run inside `System.runAs(<current user>)`, so you can create personas and regular records in the same test without a mixed DML error.
- The name is reduced to letters and digits and lowercased (`persona` if nothing is left). `Username` is `<that>.<12 random hex>@apexblueprint.test`, unique per call so parallel tests don't collide; `Alias` is its first 8 characters and `Email` is `<that>@example.com`.
- `LanguageLocaleKey`, `LocaleSidKey` and `TimeZoneSidKey` default to the running user's values, `EmailEncodingKey` to `UTF-8`. Override any of them with `set(...)`.
- Profile names depend on the org's language: the same profile has a different Name in a Japanese org. Use the Name shown in Setup.
- `create()` works only in tests. Outside a test it throws `ApexBlueprintException`.
- `of`, `profile`, `permissionSets(String)` and `set` refuse a null or blank argument when called; `permissionSets(List)` refuses only a null list.
- Permission sets cost one SOQL query per `create()` that assigns any.

Keep the project's personas in one class next to the test data class, for example `Personas.salesRep()`, so a profile or permission set change is made once.

## owner and sharedWith

`admin` and `rep` are users made with `SPersona`.

```apex
SOrchestrator orchestrator = SOrchestrator.start()
  .add(
    SBlueprint.of(Account.class)
      .set('Name', 'Visible to rep')
      .owner(admin)
      .sharedWith(rep, 'Read')
      .alias('shared')
  )
  .add(
    SBlueprint.of(Account.class)
      .set('Name', 'Hidden from rep')
      .owner(admin)
      .alias('hidden')
  );
orchestrator.create();

System.runAs(rep) {
  List<Account> visible = [SELECT Id FROM Account];
  Assert.areEqual(1, visible.size(), 'Normal: the rep sees only the shared account.');
}
```

- `owner(user)` is `set('OwnerId', user.Id)`. The user must have an Id.
- `sharedWith(user, accessLevel)` adds a manual share row inserted one layer after the record. `accessLevel` is `'Read'` or `'Edit'`; `'All'` is refused when you call it. Call it several times for several users.
- The share object is derived from the record's object name: `Account` gives `AccountShare` (fields `AccountId`, `AccountAccessLevel`), `Foo__c` gives `Foo__Share` (fields `ParentId`, `AccessLevel`). `UserOrGroupId` and `RowCause = 'Manual'` are filled in too. For `Account`, `OpportunityAccessLevel` is set to `'None'`.
- Each share row gets the alias `<record alias>__share_<n>` (`shared__share_1`), one per `sharedWith` call, in call order.
- Shares multiply with `times` and nesting: a child declared with `sharedWith` under `Account.times(2)` gets one share per created child.

Checked at `create()`:

| Message (excerpt) | Cause |
|---|---|
| "Share object '...' was not found" | No share object of that name exists. Custom object: its org-wide default is Public Read/Write, or it is the detail of a master-detail relationship. Standard object: the object has no share object at all (for example `Task`, `Event`) |
| "The share target is the declared owner" | `sharedWith` names the user given to `owner(...)`, or set as `OwnerId` (spelled exactly so) by `set` / `template`. The owner already has full access |

A standard object's share object exists whatever its org-wide default. When the default already grants the access (or the object is controlled by its parent), no `ApexBlueprintException` is raised; the org refuses the share insert with a `DmlException`.

## Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| "Profile '...' was not found" | Profile label or the name in another language | Use the Name shown in Setup of the org that runs the tests |
| "No profile specified for persona" | Neither `profile(...)` nor `set('ProfileId', ...)` was called | Call `profile(...)` |
| "PermissionSet(s) not found: ..." | Label instead of API name, or the permission set is not deployed | Use the API name |
| Two different users where one was expected | `create()` called twice | Create once and keep the `User` |
| The restricted user still sees every record | The records are owned by that user, or the org-wide default is public | Set `owner(...)` to another user, and check the org-wide default |
