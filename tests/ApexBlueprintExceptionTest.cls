/**
 * @directory ApexBlueprint/tests
 */
@isTest
public with sharing class ApexBlueprintExceptionTest {
  @isTest
  static void testRequired_WhenBuilt_ThenMessageContainsLocationAndParam() {
    // Act
    ApexBlueprintException e = ApexBlueprintException.required('SBlueprint', 'of(System.Type recordType)', 'recordType', null).build();

    // Assert
    Assert.isTrue(e.getMessage().contains('====== APEX BLUEPRINT EXCEPTION ======'), e.getMessage());
    Assert.isTrue(e.getMessage().contains('SBlueprint.of(System.Type recordType)()'), e.getMessage());
    Assert.isTrue(e.getMessage().contains('The `recordType` argument is required'), e.getMessage());
    Assert.isTrue(e.getMessage().contains('[recordType => null]'), e.getMessage());
  }

  @isTest
  static void testInvalidArgument_WhenBuilt_ThenMessageContainsReasonActionAndProvided() {
    // Act
    ApexBlueprintException e = ApexBlueprintException.invalidArgument(
        'SBlueprint',
        'times(Integer times)',
        'times must be greater than 0.',
        'Pass a positive record count.',
        'times',
        0
      )
      .build();

    // Assert
    Assert.isTrue(e.getMessage().contains('times must be greater than 0.'), e.getMessage());
    Assert.isTrue(e.getMessage().contains('Pass a positive record count.'), e.getMessage());
    Assert.isTrue(e.getMessage().contains('[times => 0]'), e.getMessage());
  }

  @isTest
  static void testCausedBy_WhenBuilt_ThenOriginalExceptionIsChained() {
    // Arrange
    Exception original = new SObjectException('original failure');

    // Act
    ApexBlueprintException e = ApexBlueprintException.invalidOperation('SBlueprintRealizer', 'realizeBase()', 'something failed', original)
      .build();

    // Assert
    Assert.isNotNull(e.getCause());
    Assert.areEqual('original failure', e.getCause().getMessage());
  }

  @isTest
  static void testMessage_WhenBuiltWithAndWithoutCause_ThenBothFormatsWork() {
    // Act
    ApexBlueprintException plain = ApexBlueprintException.message('SBlueprint', 'template()', 'some error', 'do something').build();
    ApexBlueprintException chained = ApexBlueprintException.message('SBlueprint', 'template()', 'some error', 'do something', new SObjectException('root')).build();

    // Assert
    Assert.isTrue(plain.getMessage().contains('some error'), plain.getMessage());
    Assert.isTrue(plain.getMessage().contains('do something'), plain.getMessage());
    Assert.isNull(plain.getCause());
    Assert.areEqual('root', chained.getCause().getMessage());
  }

  @isTest
  static void testInvalidArgument_WhenMapOverloadsUsed_ThenAllParamsListed() {
    // Arrange
    Map<String, Object> params = new Map<String, Object>{ 'startAt' => 0, 'interval' => -1 };

    // Act
    ApexBlueprintException plain = ApexBlueprintException.invalidArgument('SBlueprint', 'set()', 'bad sequence', 'fix it', params).build();
    ApexBlueprintException chained = ApexBlueprintException.invalidArgument('SBlueprint', 'set()', 'bad sequence', 'fix it', params, new SObjectException('root')).build();

    // Assert
    Assert.isTrue(plain.getMessage().contains('The provided arguments are Invalid'), plain.getMessage());
    Assert.isTrue(plain.getMessage().contains('[startAt => 0]'), plain.getMessage());
    Assert.isTrue(plain.getMessage().contains('[interval => -1]'), plain.getMessage());
    Assert.areEqual('root', chained.getCause().getMessage());
  }

  @isTest
  static void testInvalidArgumentAndRequired_WhenCauseGiven_ThenChained() {
    // Act
    ApexBlueprintException arg = ApexBlueprintException.invalidArgument('C', 'm()', 'r', 'a', 'p', 'v', new SObjectException('argRoot')).build();
    ApexBlueprintException req = ApexBlueprintException.required('C', 'm()', 'p', null, new SObjectException('reqRoot')).build();

    // Assert
    Assert.areEqual('argRoot', arg.getCause().getMessage());
    Assert.areEqual('reqRoot', req.getCause().getMessage());
  }

  @isTest
  static void testBuilder_WhenEmptyStringParamAndOverrideClassName_ThenFormatted() {
    // Act
    ApexBlueprintException e = ApexBlueprintException.at('Original')
      .overrideClassName('Overridden')
      .method('m()')
      .error('err')
      .param('text', '')
      .build();

    // Assert
    Assert.isTrue(e.getMessage().contains('Overridden.m()'), e.getMessage());
    Assert.isTrue(e.getMessage().contains('[text => empty string]'), e.getMessage());
  }

  @isTest
  static void testFire_WhenCalled_ThenThrowsApexBlueprintException() {
    // Act / Assert
    try {
      ApexBlueprintException.invalidOperation('SOrchestrator', 'realizeLayer()', 'boom').fire();
      Assert.fail('Exception should be thrown');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('boom'), e.getMessage());
    }
  }
}
