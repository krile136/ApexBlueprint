# ApexBlueprint

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

**A declarative test data builder that revolutionizes test data creation in Salesforce.**

It fundamentally solves the problems of poor readability and difficult maintenance inherent in traditional, procedural test data factories, elevating your test code into "**executable specifications.**"

## 😩 The Problem: Limitations of Test Data Factories

While the traditional TestDataFactory is a best practice adopted in many Salesforce projects, it suffers from structural challenges.

### 🕸️ The Trap of Common Scenario Patterns 🕸️

This is the approach of creating a convenient method (e.g., `createFullScenario()`) that builds a frequently used set of data, like an Account with its Opportunities, Quotes, and Quote Items, all at once.

- Drawbacks:
    - Poor Visibility: You can't tell what's being created or with what values just by reading the test code; you have to go inspect the factory's implementation every time.
    - Lack of Flexibility: For a minor change, like "I just want to change the Opportunity's stage this time," you either have to add a new method (createFullScenarioForClosedWon()) or take the extra step of updating the data after it's been created.
    - Wasteful: It often creates unnecessary records not required for the test, slowing down test execution.

### 😥 The Pain of Individual Object Creation Patterns 

This is the approach of providing separate methods for each object, like createAccount() and createOpportunity(acc.Id).

- Drawbacks:
    - High Cognitive Load: It results in an "ID bucket brigade" where you must manually pass the ID of a parent record to the next method, making the code verbose and hard to read.
    - Poor Maintainability: To handle slightly different field values, you must add new methods, update the object after creation, or use flag arguments, all of which hinder continuous development.
    - Obscures the Overall Scenario: The test code becomes a sequence of imperative commands ("create this," "then create that"), making it difficult to grasp the final data structure at a glance.


In all of these conventional patterns, you describe the insertion (and updates) procedurally. This makes it difficult to see what kind of data structure is being created, and ultimately, hard to understand what test data you've prepared.

## 💡 What ApexBlueprint Solves

ApexBlueprint solves these issues with the concept of a "**Blueprint.**"

You no longer need to write the **procedure** of "how to create records." Instead, you simply **declare the final state** of "what data you want."

All the tedious work, like the insertion order of records and passing IDs, is automatically handled by the framework (`SOrchestrator`). This makes your test code clean, maintainable, and understandable to anyone.

### ✨ Key Features
- **Declarative API**
    Intuitively define blueprints with a fluent syntax like `SBlueprint.of(...).set(...)`.

- **Visual Hierarchy**
    By using the `withChildren` method, the code's indentation directly represents the data's parent-child relationships, making relations instantly clear.

- **Automatic Dependency Resolution**
    Based on the dependencies defined with `.use()` and the parent-child relationships from `.withChildren()`, the framework's topological sort algorithm automatically determines the optimal insertion order. No more worrying about the order of `insert` statements.

- **Flexible Customization**
    Reuse basic settings with `template` while safely overriding only the necessary fields for a specific test with `.set()`. You will no longer suffer from "flag hell" or a proliferation of methods.

- **Powerful Bulk Generation**
    Combine the `.times()` method with sequence placeholders (`{#}`, `{A}`, `{a}`, etc.) to describe complex data sets like one-to-many or many-to-many with surprising simplicity.

## 📦 Installation

Add `ApexBlueprint` to your project using `git submodule`.
```bash
$ cd force-app/main/default/classes
$ git submodule add https://github.com/krile136/ApexBlueprint.git ApexBlueprint
```

One Command Deployment!
A `Makefile` is provided, so you can deploy all necessary classes to your org with a single command.
```bash
$ make install
```

## 🚀 Quick Start

Here is the most basic example of creating one `Account` and one related `Contact`.
```apex
// Arrange
SOrchestrator orchestrator = SOrchestrator.start()
    .add(
        SBlueprint.of(Account.class)
            .set('Name', 'Test Account')
            .alias('acc') // Set an alias
            .withChildren(
                SBlueprint.of(Contact.class)
                    .set('LastName', 'Test Contact')
                    .alias('con')
            )
    );

// Act
orchestrator.create();

// Assert
// Access in-memory results without SOQL
Account acc = (Account) orchestrator.getByAlias('acc');
Contact con = (Contact) orchestrator.getByAlias('con');

Assert.areEqual('Test Account', acc.Name);
Assert.isNotNull(acc.Id);
Assert.areEqual(acc.Id, con.AccountId);
```

## 📖 Core Features

### SBlueprint.of(SObject.class)

Every blueprint begins with this static method.
```apex
SBlueprint accBp = SBlueprint.of(Account.class);
```
### .set(fieldName, value)

Sets a value for a specific field. Due to the immutable design, it always returns a new `SBlueprint` instance.
```apex
SBlueprint accBp = SBlueprint.of(Account.class)
    .set('Name', 'ACME Inc.')
    .set('Industry', 'Technology');
```

### .template(templateMap)

Loads a set of commonly used field values as a "template." Defining templates as static methods in a separate class enhances reusability. Values can be overridden later with `.set()`.
```apex
// AccountBlueprint.cls (created by the user)
public class AccountBlueprint {
    public static Map<String, Object> basic() {
        return new Map<String, Object>{
            'Industry' => 'Technology',
            'Type' => 'Prospect'
        };
    }
}

// Usage in test code
SBlueprint.of(Account.class)
    .template(AccountBlueprint.basic()) // Load basic settings
    .set('Name', 'ACME Inc.'); // Set a value specific to this test
```

### .alias(aliasName)

Assigns a name (alias) to the created record so you can access it later.
```apex
.alias('myAccount');
```

### .times(count)

Generates a specified number of records from the same blueprint. You can use sequence placeholders in aliases and `.set()` values.
- `{#}`: Numeric sequence (1, 2, 3...)
- `{A}`: Uppercase alphabetic sequence (A, B, C...)
- `{a}`: Lowercase alphabetic sequence (a, b, c...)

```apex
// Create 3 Accounts
SBlueprint.of(Account.class)
    .times(3)
    .alias('acc_{#}') // acc_1, acc_2, acc_3
    .set('Name', 'Test Account {A}') // Test Account A,Test Account B, Test Account C 
    .set('BillingCity', 'City {a}'); // City a, City b, City c 
```

### .withChildren(childBlueprint)

Defines a parent-child relationship. If you don't specify a `parentIdField`, the framework will infer the relationship automatically.
```apex
SBlueprint.of(Account.class)
    .withChildren(
        SBlueprint.of(Contact.class) // AccountId is set automatically
    );
```

### .use(alias, fromField, toField)

**Allows you to set a field on your record using a value from another aliased object's field.** This is useful for defining dependencies other than parent-child relationships that cannot be expressed with `withChildren`.
```apex
// Set the PricebookEntryId on a QuoteItem using the Id from a Product2 with the alias 'prod'
SBlueprint.of(QuoteLineItem.class)
    .use('prod', 'Id', 'PricebookEntryId');
```

### {P0} Placeholder

A special placeholder to reference a parent's alias from within a child blueprint nested in `withChildren`.
- `{P0}`: The root parent (layer 0)
- `{P1}`: The parent at layer 1
- `{Px}`: The parent at layer x

```apex
// Set the child (Contact) LastName to the parent (Account) Name
SBlueprint.of(Account.class)
    .set('Name', 'Parent Name')
    .withChildren(
        SBlueprint.of(Contact.class)
            .use('{P0}', 'Name', 'LastName')
    );
```

I believe that `ApexBlueprint` will help make your test code cleaner and more maintainable.

More detailed usage, advanced use cases, and the design philosophy will be posted on the official website, which is currently under construction. Please stay tuned!

[KrileWorks.com](https://krileworks.com/)
