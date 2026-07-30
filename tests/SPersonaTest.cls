@isTest
public with sharing class SPersonaTest {
  /**
   * Returns the current user's Profile Name — a Profile guaranteed to exist on any org.
   */
  private static String currentProfileName() {
    return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
  }

  @isTest
  static void testOf_WhenNameIsBlank_ThenThrowException() {
    // Act & Assert
    try {
      SPersona.of('');
      Assert.fail('Exception should be thrown');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('The `name` argument is required'), e.getMessage());
    }
  }

  @isTest
  static void testCreate_WhenProfileGiven_ThenUserInsertedWithDefaults() {
    // Arrange
    String profileName = currentProfileName();

    // Act
    User persona = SPersona.of('sales-rep').profile(profileName).create();

    // Assert
    Assert.isNotNull(persona.Id, 'User should be inserted');
    User queried = [SELECT LastName, Alias, Username, Email, ProfileId, LanguageLocaleKey FROM User WHERE Id = :persona.Id];
    Assert.areEqual('sales-rep', queried.LastName);
    Assert.areEqual('salesrep', queried.Alias);
    Assert.isTrue(queried.Username.startsWith('salesrep.'), queried.Username);
    Assert.isTrue(queried.Username.endsWith('@apexblueprint.test'), queried.Username);
    Assert.areEqual(UserInfo.getLanguage(), queried.LanguageLocaleKey);
  }

  @isTest
  static void testCreate_WhenCalledTwice_ThenUsernamesAreUnique() {
    // Arrange
    SPersona persona = SPersona.of('sales-rep').profile(currentProfileName());

    // Act
    User first = persona.create();
    User second = persona.create();

    // Assert
    Assert.areNotEqual(first.Id, second.Id);
    Assert.areNotEqual(first.Username, second.Username, 'Usernames must be unique per create()');
  }

  @isTest
  static void testCreate_WhenNameHasNoAlphanumeric_ThenAliasFallsBack() {
    // Act - a Japanese-only persona name has no alphanumeric seed characters
    User persona = SPersona.of('営業').profile(currentProfileName()).create();

    // Assert
    User queried = [SELECT LastName, Alias, Username FROM User WHERE Id = :persona.Id];
    Assert.areEqual('営業', queried.LastName);
    Assert.areEqual('persona', queried.Alias);
    Assert.isTrue(queried.Username.startsWith('persona.'), queried.Username);
  }

  @isTest
  static void testCreate_WhenProfileNotFound_ThenThrowException() {
    // Act & Assert
    try {
      SPersona.of('rep').profile('NoSuchProfile_ZZZ').create();
      Assert.fail('Exception should be thrown');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('Profile \'NoSuchProfile_ZZZ\' was not found'), e.getMessage());
    }
  }

  @isTest
  static void testCreate_WhenNoProfileSpecified_ThenThrowException() {
    // Act & Assert
    try {
      SPersona.of('rep').create();
      Assert.fail('Exception should be thrown');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('No profile specified'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('profile('), e.getMessage());
    }
  }

  @isTest
  static void testCreate_WhenPermissionSetsGiven_ThenAssigned() {
    // Arrange - PermissionSet is a setup object and can be created by DML in tests
    insert new PermissionSet(Name = 'SPersonaTestPS', Label = 'SPersona Test PS');

    // Act
    User persona = SPersona.of('rep').profile(currentProfileName()).permissionSets('SPersonaTestPS').create();

    // Assert
    Integer assignedCount = [
      SELECT COUNT()
      FROM PermissionSetAssignment
      WHERE AssigneeId = :persona.Id AND PermissionSet.Name = 'SPersonaTestPS'
    ];
    Assert.areEqual(1, assignedCount);
  }

  @isTest
  static void testCreate_WhenPermissionSetNotFound_ThenThrowException() {
    // Act & Assert
    try {
      SPersona.of('rep').profile(currentProfileName()).permissionSets('NoSuchPermSet_ZZZ').create();
      Assert.fail('Exception should be thrown');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('PermissionSet(s) not found: NoSuchPermSet_ZZZ'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('API Name'), e.getMessage());
    }
  }

  @isTest
  static void testSet_WhenOverrideGiven_ThenAppliedOverDefaults() {
    // Act
    User persona = SPersona.of('rep')
      .profile(currentProfileName())
      .set('LastName', 'Custom Name')
      .set('Email', 'custom@example.com')
      .create();

    // Assert
    User queried = [SELECT LastName, Email FROM User WHERE Id = :persona.Id];
    Assert.areEqual('Custom Name', queried.LastName);
    Assert.areEqual('custom@example.com', queried.Email);
  }

  @isTest
  static void testSet_WhenFieldDoesNotExist_ThenThrowException() {
    // Act & Assert
    try {
      SPersona.of('rep').profile(currentProfileName()).set('NoSuchField__c', 'x').create();
      Assert.fail('Exception should be thrown');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('NoSuchField__c'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('exists on User'), e.getMessage());
    }
  }

  @isTest
  static void testCreate_WhenMixedWithRegularDml_ThenNoMixedDmlError() {
    // Arrange - regular-object DML in the same transaction as persona creation
    insert new Account(Name = 'Before Persona');

    // Act - would throw MIXED_DML_OPERATION without the internal runAs wrap
    User persona = SPersona.of('rep').profile(currentProfileName()).create();
    insert new Account(Name = 'After Persona');

    // Assert
    Assert.isNotNull(persona.Id);
    Assert.areEqual(2, [SELECT COUNT() FROM Account WHERE Name LIKE '%Persona']);
  }

  @isTest
  static void testBuilder_WhenChained_ThenOriginalInstanceUnchanged() {
    // Arrange
    SPersona base = SPersona.of('rep');

    // Act - immutability: chaining must not mutate the base instance
    SPersona derived = base.profile(currentProfileName()).set('LastName', 'Derived');

    // Assert - base still has no profile, so create() on it must fail
    try {
      base.create();
      Assert.fail('Exception should be thrown');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('No profile specified'), e.getMessage());
    }
    Assert.isNotNull(derived.create().Id);
  }
}
