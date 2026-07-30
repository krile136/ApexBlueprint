@isTest
public with sharing class SBlueprintShareTest {
  /**
   * Returns a User reference for the running user (no DML needed).
   */
  private static User currentUser() {
    return new User(Id = UserInfo.getUserId());
  }

  @isTest
  static void testCreate_WhenSharedWith_ThenShareRecordGenerated() {
    // Arrange
    User grantee = currentUser();
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Hostile').alias('acc').sharedWith(grantee, 'Read'));

    // Act
    orchestrator.create();

    // Assert - the sibling AccountShare is generated, wired to the parent, and inserted after it
    Account acc = (Account) orchestrator.getByAlias('acc');
    AccountShare share = (AccountShare) orchestrator.getByAlias('acc__share_1');
    Assert.isNotNull(share, 'Share blueprint should be generated with alias acc__share_1');
    Assert.areEqual(acc.Id, share.AccountId);
    Assert.areEqual(grantee.Id, share.UserOrGroupId);
    Assert.areEqual('Read', share.AccountAccessLevel);
    Assert.areEqual('None', share.OpportunityAccessLevel);
    Assert.areEqual('Manual', share.RowCause);
  }

  @isTest
  static void testCreate_WhenSharedWithMultipleUsers_ThenOneSharePerTarget() {
    // Arrange
    User grantee = currentUser();
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Hostile')
          .alias('acc')
          .sharedWith(grantee, 'Read')
          .sharedWith(grantee, 'Edit')
      );

    // Act
    orchestrator.create();

    // Assert
    AccountShare first = (AccountShare) orchestrator.getByAlias('acc__share_1');
    AccountShare second = (AccountShare) orchestrator.getByAlias('acc__share_2');
    Assert.areEqual('Read', first.AccountAccessLevel);
    Assert.areEqual('Edit', second.AccountAccessLevel);
  }

  @isTest
  static void testCreate_WhenParentHasTimes_ThenSharePerRecord() {
    // Arrange
    User grantee = currentUser();
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Acc-{#}')
          .alias('acc_{#}')
          .times(2)
          .sharedWith(grantee, 'Read')
      );

    // Act
    orchestrator.create();

    // Assert - each generated record gets its own share row
    for (Integer i = 1; i <= 2; i++) {
      Account acc = (Account) orchestrator.getByAlias('acc_' + i);
      AccountShare share = (AccountShare) orchestrator.getByAlias('acc_' + i + '__share_1');
      Assert.areEqual(acc.Id, share.AccountId, 'Share ' + i + ' should point at its own record');
    }
  }

  @isTest
  static void testCreate_WhenChildSharedWith_ThenShareGeneratedForChild() {
    // Arrange
    User grantee = currentUser();
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Parent')
          .alias('acc')
          .withChildren(
            SBlueprint.of(Opportunity.class)
              .set('Name', 'Child Opp')
              .alias('opp')
              .sharedWith(grantee, 'Read')
          )
      );

    // Act
    orchestrator.create();

    // Assert
    Opportunity opp = (Opportunity) orchestrator.getByAlias('opp');
    OpportunityShare share = (OpportunityShare) orchestrator.getByAlias('opp__share_1');
    Assert.areEqual(opp.Id, share.OpportunityId);
    Assert.areEqual('Read', share.OpportunityAccessLevel);
  }

  @isTest
  static void testOwner_WhenGiven_ThenOwnerIdSet() {
    // Arrange
    User ownerUser = currentUser();
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Owned').alias('acc').owner(ownerUser));

    // Act
    orchestrator.create();

    // Assert
    Account acc = (Account) orchestrator.getByAlias('acc');
    Assert.areEqual(ownerUser.Id, acc.OwnerId);
  }

  @isTest
  static void testOwner_WhenUserHasNoId_ThenThrowException() {
    // Act & Assert
    try {
      SBlueprint.of(Account.class).owner(new User());
      Assert.fail('Exception should be thrown');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('The `user` argument is required'), e.getMessage());
    }
  }

  @isTest
  static void testSharedWith_WhenInvalidAccessLevel_ThenThrowException() {
    // Act & Assert
    try {
      SBlueprint.of(Account.class).sharedWith(currentUser(), 'All');
      Assert.fail('Exception should be thrown');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('accessLevel must be \'Read\' or \'Edit\''), e.getMessage());
    }
  }

  @isTest
  static void testSharedWith_WhenUserIsNull_ThenThrowException() {
    // Act & Assert
    try {
      SBlueprint.of(Account.class).sharedWith(null, 'Read');
      Assert.fail('Exception should be thrown');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('The `user` argument is required'), e.getMessage());
    }
  }

  @isTest
  static void testCreate_WhenShareTargetIsDeclaredOwner_ThenThrowException() {
    // Arrange - sharing to the record owner is rejected by Salesforce, so fail fast
    User sameUser = currentUser();
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).alias('acc').owner(sameUser).sharedWith(sameUser, 'Read'));

    // Act & Assert
    try {
      orchestrator.create();
      Assert.fail('Exception should be thrown');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('share target is the declared owner'), e.getMessage());
    }
  }

  @isTest
  static void testDeriveShareTypeName_WhenCustomAndStandard_ThenCorrectNames() {
    // Act / Assert
    Assert.areEqual('Invoice__Share', SBlueprint.deriveShareTypeName('Invoice__c'));
    Assert.areEqual('AccountShare', SBlueprint.deriveShareTypeName('Account'));
    Assert.areEqual('OpportunityShare', SBlueprint.deriveShareTypeName('Opportunity'));
  }
}
