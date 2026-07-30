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
