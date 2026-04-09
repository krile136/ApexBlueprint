@isTest
public with sharing class SBlueprintTest {
  @isTest
  static void testOf_WhenAddRecordType_ThenCreateSBlueprint() {
    // Arrange
    System.Type recordType = Account.class;

    // Act
    SBlueprint sBluePrint = SBlueprint.of(recordType);
    // Assert
    Assert.areEqual(recordType, sBluePrint.recordType, 'RecordType should be set');
  }

  @isTest
  static void testOf_WhenRecordTypeIsNull_ThenThrowException() {
    // Arrange
    System.Type recordType = null;

    // Act & Assert
    try {
      SBlueprint sBluePrint = SBlueprint.of(recordType);
      Assert.fail('Exception should be thrown');
    } catch (DmlException e) {
      String actual = e.getMessage();
      System.debug(actual);
      String expected = 'RecordType must not be null';
      Assert.areEqual(expected, actual);
    }
  }

  @isTest
  static void testOf_WhenRecordTypeIsNotSObject_ThenThrowException() {
    // Arrange
    System.Type recordType = String.class;

    // Act & Assert
    try {
      SBlueprint sBluePrint = SBlueprint.of(recordType);
      Assert.fail('Exception should be thrown');
    } catch (DmlException e) {
      String actual = e.getMessage();
      System.debug(actual);
      String expected = 'RecordType must be SObject type';
      Assert.areEqual(expected, actual);
    }
  }

  @isTest
  static void testSet_WhenAddFieldValue_ThenReturnNewSBlueprintWithFieldValue() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    String fieldName = 'Name';
    String fieldValue = 'Test Account';

    // Act
    SBlueprint newSBlueprint = sBluePrint.set(fieldName, fieldValue);

    // Assert
    Assert.areEqual('Test Account', newSBlueprint.fieldValues.get(fieldName).value, 'Field value should be set');
  }

  @isTest
  static void testSet_WhenAddWithStartAt_ThenReturnNewSBlueprintWithFieldValue() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    String fieldName = 'Name';
    String fieldValue = 'Test Account {#}';
    Integer startAt = 1;
    Integer times = 3;

    // Act
    SBlueprint newSBlueprint = sBluePrint.set(fieldName, fieldValue, startAt).times(times);
    
    // Assert
    SBlueprint.ValueDefinition valueDef = newSBlueprint.fieldValues.get(fieldName);
    Assert.areEqual(fieldValue, valueDef.value, 'Field value should be set');
    Assert.areEqual(startAt, valueDef.startAt, 'StartAt should be set');
    Assert.areEqual(1, valueDef.interval, 'Interval should be default 1');
  }

  @isTest
  static void testSet_WhendAddWithMinusStartAtValue_ThenThrowException() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    String fieldName = 'Name';
    String fieldValue = 'Test Account {#}';
    Integer startAt = -1;
    Integer times = 3;

    // Act & Assert
    try {
      SBlueprint newSBlueprint = sBluePrint.set(fieldName, fieldValue, startAt).times(times);
      Assert.fail('Exception should be thrown');
    } catch (DmlException e) {
      String actual = e.getMessage();
      System.debug(actual);
      String expected = 'startAt must be greater than 0';
      Assert.areEqual(expected, actual);
    }
  }

  @isTest
  static void testSet_WhenAddWithStartAtAndInterval_ThenReturnNewSBlueprintWithFieldValue() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    String fieldName = 'Name';
    String fieldValue = 'Test Account {#}';
    Integer startAt = 10;
    Integer interval = 2;
    Integer times = 3;

    // Act
    SBlueprint newSBlueprint = sBluePrint.set(fieldName, fieldValue, startAt, interval).times(times);
    
    // Assert
    SBlueprint.ValueDefinition valueDef = newSBlueprint.fieldValues.get(fieldName);
    Assert.areEqual(fieldValue, valueDef.value, 'Field value should be set');
    Assert.areEqual(startAt, valueDef.startAt, 'StartAt should be set');
    Assert.areEqual(interval, valueDef.interval, 'Interval should be set');
  }

  @isTest
  static void testSet_WhendAddWithMinusIntervalValue_ThenThrowException() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    String fieldName = 'Name';
    String fieldValue = 'Test Account {#}';
    Integer startAt = 1;
    Integer interval = -1;
    Integer times = 3;

    // Act & Assert
    try {
      SBlueprint newSBlueprint = sBluePrint.set(fieldName, fieldValue, startAt, interval).times(times);
      Assert.fail('Exception should be thrown');
    } catch (DmlException e) {
      String actual = e.getMessage();
      System.debug(actual);
      String expected = 'interval must be greater than 0';
      Assert.areEqual(expected, actual);
    }
  }

  @isTest
  static void testTemplate_WhenAddTemplate_ThenReturnNewSBlueprint() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    Map<String, Object> template = new Map<String, Object>{ 'Name' => 'Test Account', 'Industry' => 'Technology' };

    // Act
    SBlueprint newSBlueprint = sBluePrint.template(template);

    // Assert
    Assert.areEqual(
      'Test Account',
      newSBlueprint.fieldValues.get('Name').value,
      'Name should be set from template'
    );
    Assert.areEqual(
      'Technology',
      newSBlueprint.fieldValues.get('Industry').value,
      'Industry should be set from template'
    );
  }

  @isTest
  static void testTemplate_WhenAddTemplateAfterSet_ThenReturnNewInstanceWithTemplateValue() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    sBluePrint = sBluePrint.set('Name', 'Test Account');
    Map<String, Object> template = new Map<String, Object>{ 'Name' => 'Template Account'};

    // Act
    SBlueprint newSBlueprint = sBluePrint.template(template);

    // Assert
    Assert.areEqual('Template Account', newSBlueprint.fieldValues.get('Name').value, 'Name should be set from template');
  }

  @isTest
  static void testUse_WhenAddUseAlias_ThenReturnNewSBlueprintWithUseAlias() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Opportunity.class);
    String alias = 'parentAccount';
    String fromField = 'Id';
    String toField = 'AccountId';

    // Act
    SBlueprint newSBlueprint = sBluePrint.use(alias, fromField, toField);

    // Assert
    Assert.areEqual(1, newSBlueprint.getDependencies().size(), 'UseAlias should be added');
    List<SbluePrint.Dependency> dependencies = newSBlueprint.getDependencies(); 
    SBlueprint.Dependency dependency = dependencies[0];
    Assert.areEqual(alias, dependency.alias, 'Alias should be set');
    Assert.areEqual(fromField, dependency.fromField, 'FromField should be set');
    Assert.areEqual(toField, dependency.toField, 'ToField should be set');
  }

  @isTest
  static void testUse_WhenAddUseAliasWithStartAt_ThenReturnNewSBlueprintWithUseAlias() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Opportunity.class);
    String alias = 'parentAccount';
    String fromField = 'Id';
    String toField = 'AccountId';
    Integer startAt = 1;
    Integer times = 3;

    // Act
    SBlueprint newSBlueprint = sBluePrint.use(alias, fromField, toField, startAt).times(times);

    // Assert
    Assert.areEqual(1, newSBlueprint.getDependencies().size(), 'UseAlias should be added');
    List<SbluePrint.Dependency> dependencies = newSBlueprint.getDependencies(); 
    SBlueprint.Dependency dependency = dependencies[0];
    Assert.areEqual(alias, dependency.alias, 'Alias should be set');
    Assert.areEqual(fromField, dependency.fromField, 'FromField should be set');
    Assert.areEqual(toField, dependency.toField, 'ToField should be set');
    Assert.areEqual(startAt, dependency.startAt, 'StartAt should be set');
    Assert.areEqual(1, dependency.interval, 'Interval should be default 1');
  }

  @isTest
  static void testUse_WhenAddUseAliasWIthStartAtAndInterval_ThenReturnNewSBlueprintWithUseAlias() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Opportunity.class);
    String alias = 'parentAccount';
    String fromField = 'Id';
    String toField = 'AccountId';
    Integer startAt = 10;
    Integer interval = 2;
    Integer times = 3;

    // Act
    SBlueprint newSBlueprint = sBluePrint.use(alias, fromField, toField, startAt, interval).times(times);

    // Assert
    Assert.areEqual(1, newSBlueprint.getDependencies().size(), 'UseAlias should be added');
    List<SbluePrint.Dependency> dependencies = newSBlueprint.getDependencies(); 
    SBlueprint.Dependency dependency = dependencies[0];
    Assert.areEqual(alias, dependency.alias, 'Alias should be set');
    Assert.areEqual(fromField, dependency.fromField, 'FromField should be set');
    Assert.areEqual(toField, dependency.toField, 'ToField should be set');
    Assert.areEqual(startAt, dependency.startAt, 'StartAt should be set');
    Assert.areEqual(interval, dependency.interval, 'Interval should be set');
  }

  @isTest
  static void testUse_WhenAliasIsNull_ThenThrowException() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Opportunity.class);
    String alias = null;
    String fromField = 'Id';
    String toField = 'AccountId';

    // Act & Assert
    try {
      SBlueprint newSBlueprint = sBluePrint.use(alias, fromField, toField);
      Assert.fail('Exception should be thrown');
    } catch (DmlException e) {
      String actual = e.getMessage();
      System.debug(actual);
      String expected = 'alias must not be null';
      Assert.areEqual(expected, actual);
    }
  }

  @isTest
  static void testUse_WhenFromFieldIsNull_ThenThrowException() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Opportunity.class);
    String alias = 'parentAccount';
    String fromField = null;
    String toField = 'AccountId';

    // Act & Assert
    try {
      SBlueprint newSBlueprint = sBluePrint.use(alias, fromField, toField);
      Assert.fail('Exception should be thrown');
    } catch (DmlException e) {
      String actual = e.getMessage();
      System.debug(actual);
      String expected = 'fromField must not be null';
      Assert.areEqual(expected, actual);
    }
  }

  @isTest
  static void testUse_WhenToFieldIsNull_ThenThrowException() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Opportunity.class);
    String alias = 'parentAccount';
    String fromField = 'Id';
    String toField = null;

    // Act & Assert
    try {
      SBlueprint newSBlueprint = sBluePrint.use(alias, fromField, toField);
      Assert.fail('Exception should be thrown');
    } catch (DmlException e) {
      String actual = e.getMessage();
      System.debug(actual);
      String expected = 'toField must not be null';
      Assert.areEqual(expected, actual);
    }
  }

  @isTest
  static void testUse_WhenAddUseAliasWithMinusStartAtValue_ThenThrowException() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Opportunity.class);
    String alias = 'parentAccount';
    String fromField = 'Id';
    String toField = 'AccountId';
    Integer startAt = -1;
    Integer times = 3;
    // Act & Assert
    try {
      SBlueprint newSBlueprint = sBluePrint.use(alias, fromField, toField, startAt).times(times);
      Assert.fail('Exception should be thrown');
    } catch (DmlException e) {
      String actual = e.getMessage();
      System.debug(actual);
      String expected = 'startAt must be greater than 0';
      Assert.areEqual(expected, actual);
    }
  }

  @isTest
  static void testUse_WhenAddUseAliasWithMinusIntervalValue_ThenThrowException() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Opportunity.class);
    String alias = 'parentAccount';
    String fromField = 'Id';
    String toField = 'AccountId';
    Integer startAt = 1;
    Integer interval = -1;
    Integer times = 3;

    // Act & Assert
    try {
      SBlueprint newSBlueprint = sBluePrint.use(alias, fromField, toField, startAt, interval).times(times);
      Assert.fail('Exception should be thrown');
    } catch (DmlException e) {
      String actual = e.getMessage();
      System.debug(actual);
      String expected = 'interval must be greater than 0';
      Assert.areEqual(expected, actual);
    }
  }

  @isTest
  static void testAlias_WhenAddAlias_ThenReturnNewSBlueprintWithAlias() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    String alias = 'acc';

    // Act
    SBlueprint newSBlueprint = sBluePrint.alias(alias);

    // Assert

    Assert.areEqual(alias, newSBlueprint.getAlias(), 'Alias should be set');
  }

  @isTest
  static void testAlias_WhenAddAliasWithStartAt_ThenReturnNewSBlueprintWithAlias() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    String alias = 'acc';
    Integer startAt = 1;
    Integer times = 3;

    // Act
    SBlueprint newSBlueprint = sBluePrint.alias(alias, startAt).times(times);

    // Assert
    SBlueprint.AliasDefinition aliasDef = newSBlueprint.getAliasDefinition();
    Assert.areEqual(alias, aliasDef.alias, 'Alias should be set');
    Assert.areEqual(startAt, aliasDef.startAt, 'AliasStartAt should be set');
    Assert.areEqual(1, aliasDef.interval, 'AliasInterval should be default 1');
  }

  @isTest
  static void testAlias_WhenAddAliasWithStartAtAndInterval_ThenReturnNewSBlueprintWithAlias() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    String alias = 'acc';
    Integer startAt = 10;
    Integer interval = 2;
    Integer times = 3;

    // Act
    SBlueprint newSBlueprint = sBluePrint.alias(alias, startAt, interval).times(times);

    // Assert
    SBlueprint.AliasDefinition aliasDef = newSBlueprint.getAliasDefinition();
    Assert.areEqual(alias, aliasDef.alias, 'Alias should be set');
    Assert.areEqual(startAt, aliasDef.startAt, 'AliasStartAt should be set');
    Assert.areEqual(interval, aliasDef.interval, 'AliasInterval should be set');
  }

  @isTest
  static void testAlias_WhenAliasIsNull_ThenThrowException() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    String alias = null;
    // Act & Assert
    try {
      SBlueprint newSBlueprint = sBluePrint.alias(alias);
      Assert.fail('Exception should be thrown');
    } catch (DmlException e) {
      String actual = e.getMessage();
      System.debug(actual);
      String expected = 'alias must not be null';
      Assert.areEqual(expected, actual);
    }
  }

  @isTest
  static void testAlias_WhenAddAliasWithMinusStartAtValue_ThenThrowException() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    String alias = 'acc';
    Integer startAt = -1;
    Integer times = 3;
    // Act & Assert
    try {
      SBlueprint newSBlueprint = sBluePrint.alias(alias, startAt).times(times);
      Assert.fail('Exception should be thrown');
    } catch (DmlException e) {
      String actual = e.getMessage();
      System.debug(actual);
      String expected = 'startAt must be greater than 0';
      Assert.areEqual(expected, actual);
    }
  }

  @isTest
  static void testAlias_WhenAddAliasWithMinusIntervalValue_ThenThrowException() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    String alias = 'acc';
    Integer startAt = 1;
    Integer interval = -1;
    Integer times = 3;

    // Act & Assert
    try {
      SBlueprint newSBlueprint = sBluePrint.alias(alias, startAt, interval).times(times);
      Assert.fail('Exception should be thrown');
    } catch (DmlException e) {
      String actual = e.getMessage();
      System.debug(actual);
      String expected = 'interval must be greater than 0';
      Assert.areEqual(expected, actual);
    }
  }

  @isTest
  static void testTimes_WhenAddTimes_ThenReturnNewSBlueprintWithInsertNumber() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Account.class);
    Integer times = 5;

    // Act
    SBlueprint newSBlueprint = sBluePrint.times(times);

    // Assert
    Assert.areEqual(times, newSBlueprint.insertNumber, 'InsertNumber should be set');
  }

  @isTest
  static void testParentIdField_WhenAddParentIdField_ThenReturnNewSBlueprintWithParentIdField() {
    // Arrange
    SBlueprint sBluePrint = SBlueprint.of(Contact.class);
    String parentIdField = 'AccountId';

    // Act
    SBlueprint newSBlueprint = sBluePrint.parentIdField(parentIdField);

    // Assert
    Assert.areEqual(parentIdField, newSBlueprint.parentIdField, 'ParentIdField should be set');
  }

  @isTest
  static void testAddChildren_WhenAddChild_ThenReturnNewSBlueprintWithChild() {
    // Arrange
    SBlueprint parent = SBlueprint.of(Account.class);
    SBlueprint child = SBlueprint.of(Contact.class);

    // Act
    SBlueprint newSBlueprint = parent.withChildren(child);

    // Assert
    Assert.areEqual(1, newSBlueprint.children.size(), 'Child should be added');
    Assert.areEqual(Contact.class, newSBlueprint.children[0].recordType, 'Child recordType should be Contact');
  }
}
