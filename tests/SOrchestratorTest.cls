/**
 * @directory ApexBlueprint/tests
 */
@isTest
public with sharing class SOrchestratorTest {
  @isTest
  static void testAdd_WhenAdd_ReturnNewSOrchestrator() {
    // Act
    SOrchestrator orchestrator = SOrchestrator.start();

    // Arrange
    SOrchestrator newSOrchestrator = orchestrator.add(SBlueprint.of(Account.class));

    // Assert
    Assert.areEqual(0, orchestrator.sBluePrints.size());
    Assert.areEqual(1, newSOrchestrator.sBluePrints.size());
  }

  @isTest
  static void testCreate_WhenAddSingleSBlueprint_ThenInsertOneRecord() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Test Account'));

    // Act
    orchestrator.create();

    // Assert
    Account acc = (Account) orchestrator.getByAlias('__Account_0_1__');
    Assert.areEqual('Test Account', acc.Name);
  }

  @isTest
  static void testCreate_WHenAddSingleSBlueprintWithAlias_ThenCanAccessByAlias() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Test Account').alias('acc'));

    // Act
    orchestrator.create();

    // Assert
    Account acc = (Account) orchestrator.getByAlias('acc');
    Assert.areEqual('Test Account', acc.Name);
  }

  @isTest
  static void testCreate_WhenAddParentAndChildren_ThenInsertInOrder() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account')
          .withChildren(SBlueprint.of(Contact.class).set('LastName', 'Test Contact'))
      );

    // Act
    orchestrator.create();

    // Assert
    Account acc = (Account) orchestrator.getByAlias('__Account_0_1__');
    Assert.areEqual('Test Account', acc.Name);
    Contact con = (Contact) orchestrator.getByAlias('__Account_0_1_____Contact_1_1__');
    Assert.areEqual('Test Contact', con.LastName);
    Assert.areEqual(acc.Id, con.AccountId);
  }

  @isTest
  static void testCreate_WhenAddParentAndChildrenWithAlias_ThenCanAccessByAlias() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account')
          .alias('acc')
          .withChildren(SBlueprint.of(Contact.class).set('LastName', 'Test Contact').alias('con'))
      );

    // Act
    orchestrator.create();

    // Assert
    Account acc = (Account) orchestrator.getByAlias('acc');
    Assert.areEqual('Test Account', acc.Name);
    Contact con = (Contact) orchestrator.getByAlias('con');
    Assert.areEqual('Test Contact', con.LastName);
    Assert.areEqual(acc.Id, con.AccountId);
  }

  @isTest
  static void testCreate_WhenAddParentAndChildrenWithAliasAndUse_ThenInsertInOrder() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account')
          .alias('acc')
          .withChildren(SBlueprint.of(Contact.class).use('acc', 'Name', 'LastName').alias('con'))
      );

    // Act
    orchestrator.create();

    // Assert
    Account acc = (Account) orchestrator.getByAlias('acc');
    Assert.areEqual('Test Account', acc.Name);
    Contact con = (Contact) orchestrator.getByAlias('con');
    Assert.areEqual('Test Account', con.LastName);
    Assert.areEqual(acc.Id, con.AccountId);
  }

  @isTest
  static void testCreate_WhenAddParentAndChildrenWithParentLayerAlias_ThenInsertInOrder() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account')
          .withChildren(SBlueprint.of(Contact.class).use('{P0}', 'Name', 'LastName').alias('con'))
      );

    // Act
    orchestrator.create();

    // Assert
    Account acc = (Account) orchestrator.getByAlias('__Account_0_1__');
    Assert.areEqual('Test Account', acc.Name);
    Contact con = (Contact) orchestrator.getByAlias('con');
    Assert.areEqual('Test Account', con.LastName);
    Assert.areEqual(acc.Id, con.AccountId);
  }

  @isTest
  static void testCreate_WhenAddParentAndChildrenWithParentLayerAlias_ThenInsertInOrder_2() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account')
          .withChildren(
            SBlueprint.of(Contact.class).use('{P0}', 'Name', 'LastName').alias('{P0}_con_{#}').times(2)
          )
      );

    // Act
    orchestrator.create();

    // Assert
    Account acc = (Account) orchestrator.getByAlias('__Account_0_1__');
    Assert.areEqual('Test Account', acc.Name);
    for (Integer i = 1; i <= 2; i++) {
      String contactAlias = '__Account_0_1__' + '_con_' + i;
      Contact con = (Contact) orchestrator.getByAlias(contactAlias);
      Assert.areEqual('Test Account', con.LastName);
      Assert.areEqual(acc.Id, con.AccountId);
    }
  }

  @isTest
  static void testCreate_WhenAddMultipleRoots_ThenInsertAllInOrder() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account 1')
          .alias('acc1')
          .withChildren(SBlueprint.of(Contact.class).set('LastName', 'Test Contact 1').alias('con1'))
      )
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account 2')
          .alias('acc2')
          .withChildren(SBlueprint.of(Contact.class).set('LastName', 'Test Contact 2').alias('con2'))
      );

    // Act
    orchestrator.create();

    // Assert
    Account acc1 = (Account) orchestrator.getByAlias('acc1');
    Assert.areEqual('Test Account 1', acc1.Name);
    Contact con1 = (Contact) orchestrator.getByAlias('con1');
    Assert.areEqual('Test Contact 1', con1.LastName);
    Assert.areEqual(acc1.Id, con1.AccountId);

    Account acc2 = (Account) orchestrator.getByAlias('acc2');
    Assert.areEqual('Test Account 2', acc2.Name);
    Contact con2 = (Contact) orchestrator.getByAlias('con2');
    Assert.areEqual('Test Contact 2', con2.LastName);
    Assert.areEqual(acc2.Id, con2.AccountId);
  }

  @isTest
  static void testCreate_WhenAddMulitipleParentWithChildren_ThenCreateChildrenToEachParent() {
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account {#}', 1, 1)
          .alias('acc_{#}')
          .times(2)
          .withChildren(
            SBlueprint.of(Contact.class).set('LastName', 'Test Contact {#}', 1, 1).alias('{P0}_con_{#}').times(2)
          )
      );

    // Act
    orchestrator.create();

    // Assert
    for (Integer i = 1; i <= 2; i++) {
      Account acc = (Account) orchestrator.getByAlias('acc_' + i);
      Assert.areEqual('Test Account ' + i, acc.Name);
      for (Integer j = 1; j <= 2; j++) {
        Contact con = (Contact) orchestrator.getByAlias('acc_' + i + '_con_' + j);
        Assert.areEqual('Test Contact ' + j, con.LastName);
        Assert.areEqual(acc.Id, con.AccountId);
      }
    }
  }

  @isTest
  static void testCreate_WhenAddMultipleParentWithChildrenWithoutAlias_ThenCreateChildrenToEachParent() {
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account {#}', 1)
          .times(2)
          .withChildren(SBlueprint.of(Contact.class).set('LastName', 'Test Contact {#}', 1).times(2))
      );

    // Act
    orchestrator.create();

    // Assert
    for (Integer i = 1; i <= 2; i++) {
      String accAlias = String.format('__Account_0_{0}__', new List<String>{ String.valueOf(i) });
      Account acc = (Account) orchestrator.getByAlias(accAlias);
      Assert.areEqual('Test Account ' + i, acc.Name);
      for (Integer j = 1; j <= 2; j++) {
        String conAlias =
          accAlias +
          '_' +
          String.format('__Contact_1_{0}__', new List<String>{ String.valueOf(j) });
        System.debug('conAlias: ' + conAlias);
        Contact con = (Contact) orchestrator.getByAlias(conAlias);
        Assert.areEqual('Test Contact ' + j, con.LastName);
        Assert.areEqual(acc.Id, con.AccountId);
      }
    }
  }

  @isTest
  static void testCreate_WhenAddNestedMultipleParentsWithChildren_ThenCreateChildrenToEachParent() {
    //Arrange
    Date today = Date.today();
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account {#}', 1, 1)
          .times(2)
          .withChildren(
            SBlueprint.of(Contact.class)
              .parentIdField('AccountId')
              .set('LastName', 'Test Contact {#}', 1, 1)
              .times(2)
              .withChildren(
                SBlueprint.of(Case.class)
                  .parentIdField('ContactId')
                  .set('Subject', 'Test Case {#}', 1, 1)
                  .times(2)
              )
          )
      );

    // Act
    orchestrator.create();

    // Assert
    for (Integer i = 1; i <= 2; i++) {
      String accAlias = String.format('__Account_0_{0}__', new List<String>{ String.valueOf(i) });
      Account acc = (Account) orchestrator.getByAlias(accAlias);
      Assert.areEqual('Test Account ' + i, acc.Name);
      for (Integer j = 1; j <= 2; j++) {
        String conAlias =
          accAlias +
          '_' +
          String.format('__Contact_1_{0}__', new List<String>{ String.valueOf(j) });
        Contact con = (Contact) orchestrator.getByAlias(conAlias);
        Assert.areEqual(acc.Id, con.AccountId);
        Assert.areEqual('Test Contact ' + j, con.LastName);
        for (Integer k = 1; k <= 2; k++) {
          String caseAlias =
            conAlias +
            '_' +
            String.format('__Case_2_{0}__', new List<String>{ String.valueOf(k) });
          Case cas = (Case) orchestrator.getByAlias(caseAlias);
          Assert.areEqual(con.Id, cas.ContactId);
          Assert.areEqual('Test Case ' + k, cas.Subject);
        }
      }
    }
  }

  @isTest
  static void testCreate_WhenAddNestedMultipleParentsWithChildren_ThenCreateChildrenToEachParent_2() {
    //Arrange
    Date today = Date.today();
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account {#}', 1, 1)
          .times(2)
          .withChildren(
            SBlueprint.of(Contact.class)
              .parentIdField('AccountId')
              .set('LastName', 'Test Contact {#}', 1, 1)
              .alias('{P0}_con_{#}')
              .times(2)
              .withChildren(
                SBlueprint.of(Case.class)
                  .parentIdField('ContactId')
                  .set('Subject', 'Test Case {#}', 1, 1)
                  .times(2)
              )
          )
      );

    // Act
    orchestrator.create();

    // Assert
    for (Integer i = 1; i <= 2; i++) {
      String accAlias = String.format('__Account_0_{0}__', new List<String>{ String.valueOf(i) });
      Account acc = (Account) orchestrator.getByAlias(accAlias);
      Assert.areEqual('Test Account ' + i, acc.Name);
      for (Integer j = 1; j <= 2; j++) {
        String conAlias = accAlias + '_con_' + j;
        Contact con = (Contact) orchestrator.getByAlias(conAlias);
        Assert.areEqual(acc.Id, con.AccountId);
        Assert.areEqual('Test Contact ' + j, con.LastName);
        for (Integer k = 1; k <= 2; k++) {
          String caseAlias =
            conAlias +
            '_' +
            String.format('__Case_1_{0}__', new List<String>{ String.valueOf(k) });
          System.debug('caseAlias: ' + caseAlias);
          Case cas = (Case) orchestrator.getByAlias(caseAlias);
          Assert.areEqual(con.Id, cas.ContactId);
          Assert.areEqual('Test Case ' + k, cas.Subject);
        }
      }
    }
  }

  @isTest
  static void testCreate_WhenAddNestedMultipleParentsWithChildren_ThenCreateChildrenToEachParent_3() {
    //Arrange
    Date today = Date.today();
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account {#}', 1, 1)
          .times(2)
          .withChildren(
            SBlueprint.of(Contact.class)
              .parentIdField('AccountId')
              .set('LastName', 'Test Contact {#}', 1, 1)
              .times(2)
              .withChildren(
                SBlueprint.of(Case.class)
                  .parentIdField('ContactId')
                  .set('Subject', 'Test Case {#}', 1, 1)
                  .times(2)
                  .withChildren(
                    SBlueprint.of(Case.class)
                      .parentIdField('ParentId')
                      .use('prod_{#}', 'Name', 'Description')
                      .set('Subject', 'Child Case')
                      .times(2)
                  )
              )
          )
      )
      .add(SBlueprint.of(Product2.class).set('Name', 'Test Product {#}', 1, 1).times(2).alias('prod_{#}'));

    // Act
    orchestrator.create();

    // Assert
    for (Integer i = 1; i <= 2; i++) {
      String accAlias = String.format('__Account_0_{0}__', new List<String>{ String.valueOf(i) });
      Account acc = (Account) orchestrator.getByAlias(accAlias);
      Assert.areEqual('Test Account ' + i, acc.Name);
      for (Integer j = 1; j <= 2; j++) {
        String conAlias =
          accAlias +
          '_' +
          String.format('__Contact_1_{0}__', new List<String>{ String.valueOf(j) });
        Contact con = (Contact) orchestrator.getByAlias(conAlias);
        Assert.areEqual(acc.Id, con.AccountId);
        Assert.areEqual('Test Contact ' + j, con.LastName);
        for (Integer k = 1; k <= 2; k++) {
          String caseAlias =
            conAlias +
            '_' +
            String.format('__Case_2_{0}__', new List<String>{ String.valueOf(k) });
          Case cas = (Case) orchestrator.getByAlias(caseAlias);
          Assert.areEqual(con.Id, cas.ContactId);
          Assert.areEqual('Test Case ' + k, cas.Subject);
        }
      }
    }
  }

  @isTest
  static void testCreate_WhenAddNestedMultipleParentsWithChildren_ThenCreateChildrenToEachParent_4() {
    //Arrange
    Date today = Date.today();
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account')
          .withChildren(
            SBlueprint.of(Contact.class)
              .parentIdField('AccountId')
              .set('LastName', 'Test Contact {#}', 1, 1)
              .times(2)
              .withChildren(
                SBlueprint.of(Case.class)
                  .parentIdField('ContactId')
                  .set('Subject', 'Test Case {#}', 1, 1)
                  .times(2)
                  .withChildren(
                    SBlueprint.of(Case.class)
                      .parentIdField('ParentId')
                      .use('prod_{#}', 'Name', 'Description')
                      .use('{P0}', 'Name', 'Subject')
                      .times(2)
                  )
              )
          )
      )
      .add(SBlueprint.of(Product2.class).set('Name', 'Test Product {#}', 1, 1).times(2).alias('prod_{#}'));

    // Act
    orchestrator.create();

    // Assert
    String accAlias = '__Account_0_1__';
    Account acc = (Account) orchestrator.getByAlias(accAlias);
    Assert.areEqual('Test Account', acc.Name);
    for (Integer i = 1; i <= 2; i++) {
      String conAlias =
        accAlias +
        '_' +
        String.format('__Contact_1_{0}__', new List<String>{ String.valueOf(i) });
      Contact con = (Contact) orchestrator.getByAlias(conAlias);
      Assert.areEqual(acc.Id, con.AccountId);
      Assert.areEqual('Test Contact ' + i, con.LastName);
      for (Integer j = 1; j <= 2; j++) {
        String caseAlias =
          conAlias +
          '_' +
          String.format('__Case_2_{0}__', new List<String>{ String.valueOf(j) });
        Case cas = (Case) orchestrator.getByAlias(caseAlias);
        Assert.areEqual(con.Id, cas.ContactId);
        Assert.areEqual('Test Case ' + j, cas.Subject);
        for (Integer k = 1; k <= 2; k++) {
          String childCaseAlias =
            caseAlias +
            '_' +
            String.format('__Case_3_{0}__', new List<String>{ String.valueOf(k) });
          Case childCase = (Case) orchestrator.getByAlias(childCaseAlias);
          Assert.areEqual(cas.Id, childCase.ParentId);
          Assert.areEqual('Test Account', childCase.Subject);
          Product2 prod = (Product2) orchestrator.getByAlias('prod_' + k);
          Assert.areEqual(prod.Name, childCase.Description);
        }
      }
    }
  }

  @isTest
  static void testCreate_WhenAddNestedMultipleParentsWithChildren_ThenCreateChildrenToEachParent_5() {
    //Arrange
    Date today = Date.today();
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account {#}', 1, 1)
          .times(2)
          .withChildren(
            SBlueprint.of(Contact.class)
              .parentIdField('AccountId')
              .set('LastName', 'Test Contact')
              .withChildren(
                SBlueprint.of(Case.class)
                  .parentIdField('ContactId')
                  .set('Subject', 'Test Case {#}', 1, 1)
                  .times(2)
                  .withChildren(
                    SBlueprint.of(Case.class)
                      .parentIdField('ParentId')
                      .use('{P1}', 'LastName', 'Subject')
                      .times(2)
                  )
              )
          )
      );

    // Act
    orchestrator.create();

    // Assert
    for (Integer i = 1; i <= 2; i++) {
      String accAlias = String.format('__Account_0_{0}__', new List<String>{ String.valueOf(i) });
      Account acc = (Account) orchestrator.getByAlias(accAlias);
      Assert.areEqual('Test Account ' + i, acc.Name);
      String conAlias = accAlias + '_' + '__Contact_1_1__';
      Contact con = (Contact) orchestrator.getByAlias(conAlias);
      Assert.areEqual(acc.Id, con.AccountId);
      Assert.areEqual('Test Contact', con.LastName);
      for (Integer j = 1; j <= 2; j++) {
        String caseAlias =
          conAlias +
          '_' +
          String.format('__Case_2_{0}__', new List<String>{ String.valueOf(j) });
        Case cas = (Case) orchestrator.getByAlias(caseAlias);
        Assert.areEqual(con.Id, cas.ContactId);
        Assert.areEqual('Test Case ' + j, cas.Subject);
        for (Integer k = 1; k <= 2; k++) {
          String childCaseAlias =
            caseAlias +
            '_' +
            String.format('__Case_3_{0}__', new List<String>{ String.valueOf(k) });
          Case childCase = (Case) orchestrator.getByAlias(childCaseAlias);
          Assert.areEqual(cas.Id, childCase.ParentId);
          Assert.areEqual('Test Contact', childCase.Subject);
        }
      }
    }
  }

  @isTest
  static void testCreate_WhenAddChildrenBeforeParent_ThenInsertInOrder() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Contact.class).use('acc', 'Id', 'AccountId').set('LastName', 'Test Contact').alias('con'))
      .add(SBlueprint.of(Account.class).set('Name', 'Test Account').alias('acc'));

    // Act
    orchestrator.create();

    // Assert
    Account acc = (Account) orchestrator.getByAlias('acc');
    Assert.areEqual('Test Account', acc.Name);
    Contact con = (Contact) orchestrator.getByAlias('con');
    Assert.areEqual('Test Contact', con.LastName);
    Assert.areEqual(acc.Id, con.AccountId);
  }

  @isTest
  static void testCreate_WhenAddMultipleChildrenWithTimes_ThenInsertAllInOrder() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account')
          .alias('acc')
          .withChildren(
            SBlueprint.of(Contact.class).set('LastName', 'Test Contact {#}', 1, 1).alias('con_{#}').times(3)
          )
      );

    // Act
    orchestrator.create();

    // Assert
    Account acc = (Account) orchestrator.getByAlias('acc');
    Assert.areEqual('Test Account', acc.Name);
    for (Integer i = 1; i <= 3; i++) {
      Contact con = (Contact) orchestrator.getByAlias('con_' + i);
      Assert.areEqual('Test Contact ' + i, con.LastName);
      Assert.areEqual(acc.Id, con.AccountId);
    }
  }

  @isTest
  static void testCreate_WhenAddMultiParentAndMultiChildrenWithTimes_ThenInsertAllInOrder_1() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Test Account {#}', 1, 1).alias('acc_{#}').times(2))
      .add(
        SBlueprint.of(Contact.class)
          .set('LastName', 'Test Contact {#}', 1, 1)
          .use('acc_{#}', 'Id', 'AccountId')
          .alias('con_{#}')
          .times(2)
      );

    // Act
    orchestrator.create();

    // Assert
    for (Integer i = 1; i <= 2; i++) {
      Account acc = (Account) orchestrator.getByAlias('acc_' + i);
      Assert.areEqual('Test Account ' + i, acc.Name);
      Contact con = (Contact) orchestrator.getByAlias('con_' + i);
      Assert.areEqual('Test Contact ' + i, con.LastName);
      Assert.areEqual(acc.Id, con.AccountId);
    }
  }

  @isTest
  static void testCreate_WhenAddMultiParentAndMultiChildrenWithTimes_ThenInsertAllInOrder_2() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Test Account {#}', 1, 1).alias('acc_{#}').times(2))
      .add(
        SBlueprint.of(Contact.class)
          .set('LastName', 'Test Contact {#}', 1, 1)
          .use('acc_1', 'Id', 'AccountId')
          .alias('con_{#}')
          .times(2)
      )
      .add(
        SBlueprint.of(Contact.class)
          .set('LastName', 'Test Contact {#}', 3, 1)
          .use('acc_2', 'Id', 'AccountId')
          .alias('con_{#}', 3, 1)
          .times(2)
      );

    // Act
    orchestrator.create();

    // Assert
    for (Integer i = 1; i <= 2; i++) {
      Account acc = (Account) orchestrator.getByAlias('acc_' + i);
      Assert.areEqual('Test Account ' + i, acc.Name);
    }
    for (Integer i = 1; i <= 4; i++) {
      Contact con = (Contact) orchestrator.getByAlias('con_' + i);
      Assert.areEqual('Test Contact ' + i, con.LastName);
      Integer accIndex = (i <= 2) ? 1 : 2;
      Account acc = (Account) orchestrator.getByAlias('acc_' + accIndex);
      Assert.areEqual(acc.Id, con.AccountId);
    }
  }

  @isTest
  static void testCreate_WhenAddUseWithOffset_ThenInsertInOrder_1() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Test Account {#}', 1).alias('acc_{#}').times(2))
      .add(
        SBlueprint.of(Contact.class)
          .set('LastName', 'Test Contact {#}', 1)
          .use('acc_{#}', 'Id', 'AccountId', 1)
          .alias('con_{#}')
          .times(2)
      );

    // Act
    orchestrator.create();

    // Assert
    for (Integer i = 1; i <= 2; i++) {
      Account acc = (Account) orchestrator.getByAlias('acc_' + i);
      Assert.areEqual('Test Account ' + i, acc.Name);

      Contact con = (Contact) orchestrator.getByAlias('con_' + i);
      Assert.areEqual('Test Contact ' + i, con.LastName);
      Assert.areEqual(acc.Id, con.AccountId);
    }
  }

  @isTest
  static void testCreate_WhenAddUseWithOffset_ThenInsertInORder_2() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Test Account {#}', 1).alias('acc_{#}').times(10))
      .add(
        SBlueprint.of(Contact.class)
          .set('LastName', 'Test Contact {#}', 6)
          .use('acc_{#}', 'Id', 'AccountId', 6)
          .alias('con_{#}', 6)
          .times(5)
      );

    // Act
    orchestrator.create();

    // Assert
    for (Integer i = 1; i <= 10; i++) {
      Account acc = (Account) orchestrator.getByAlias('acc_' + i);
      Assert.areEqual('Test Account ' + i, acc.Name);

      Contact con = (Contact) orchestrator.getByAlias('con_' + i);
      if (i <= 5) {
        Assert.areEqual(null, con);
      } else {
        Assert.areEqual(acc.Id, con.AccountId);
      }
    }
  }

  @isTest
  static void testCreate_WhenAddCircularReference_ThenThrowException() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Test Account').alias('acc'))
      .add(
        SBlueprint.of(Contact.class)
          .use('con2', 'AccountId', 'AccountId')
          .set('LastName', 'Test Contact 1')
          .alias('con1')
      )
      .add(
        SBlueprint.of(Contact.class)
          .use('con1', 'AccountId', 'AccountId')
          .set('LastName', 'Test Contact 2')
          .alias('con2')
      );

    // Act / Assert
    try {
      orchestrator.create();
      Assert.fail();
    } catch (Exception e) {
      System.debug(e.getMessage());
      Assert.isTrue(e.getMessage().contains('Circular or invalid reference detected below aliases'));
    }
  }

  @isTest
  static void testCreate_WhenAddInvalidReference_ThenThrowException() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Test Account').alias('acc'))
      .add(
        SBlueprint.of(Contact.class)
          .use('non_exist', 'AccountId', 'AccountId')
          .set('LastName', 'Test Contact')
          .alias('con')
      );

    // Act / Assert
    try {
      orchestrator.create();
      Assert.fail();
    } catch (Exception e) {
      System.debug(e.getMessage());
      Assert.isTrue(e.getMessage().contains('Circular or invalid reference detected below aliases'));
    }
  }

  @isTest
  static void testCreate_WhenSameAliasInSameBluePrint_ThenThrowException() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(Account.class)
          .set('Name', 'Test Account')
          .alias('acc')
          .withChildren(SBlueprint.of(Contact.class).set('LastName', 'Test Contact {#}').alias('con').times(2))
      );

    // Act / Assert
    try {
      orchestrator.create();
      Assert.fail();
    } catch (Exception e) {
      System.debug(e.getMessage());
      Assert.isTrue(e.getMessage().contains('Duplicate alias detected: con'));
    }
  }

  @isTest
  static void testCreate_WhenSameAliasInDifferentBluePrint_ThenThrowException() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Test Account 1').alias('acc'))
      .add(SBlueprint.of(Account.class).set('Name', 'Test Account 2').alias('acc'));

    // Act / Assert
    try {
      orchestrator.create();
      Assert.fail();
    } catch (Exception e) {
      System.debug(e.getMessage());
      Assert.isTrue(e.getMessage().contains('Duplicate alias detected: acc'));
    }
  }

  @isTest
  static void testCreate_WhenAfterDeclared_ThenInsertedInLaterLayer() {
    // Arrange - the dependent blueprint is added FIRST to prove ordering comes from after(), not add order
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Second').alias('second').after('first'))
      .add(SBlueprint.of(Account.class).set('Name', 'First').alias('first'));

    // Act
    orchestrator.create();

    // Assert - MockDmlOperator assigns sequential ids across layers, so a later layer means a greater id
    Account first = (Account) orchestrator.getByAlias('first');
    Account second = (Account) orchestrator.getByAlias('second');
    Assert.isNotNull(first.Id);
    Assert.isNotNull(second.Id);
    Assert.isTrue(String.valueOf(first.Id) < String.valueOf(second.Id), 'after() must place the dependent in a later layer');
  }

  @isTest
  static void testCreate_WhenAfterGroupAlias_ThenInsertedAfterWholeGroup() {
    // Arrange - after() accepts the same {#} pattern as use()
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'Grp-{#}').alias('grp_{#}').times(2))
      .add(SBlueprint.of(Account.class).set('Name', 'Late').alias('late').after('grp_{#}'));

    // Act
    orchestrator.create();

    // Assert
    Account late = (Account) orchestrator.getByAlias('late');
    Assert.isTrue(String.valueOf(orchestrator.getByAlias('grp_1').Id) < String.valueOf(late.Id));
    Assert.isTrue(String.valueOf(orchestrator.getByAlias('grp_2').Id) < String.valueOf(late.Id));
  }

  @isTest
  static void testCreate_WhenAfterCombinedWithUse_ThenBothConstraintsHold() {
    // Arrange - C copies a value from A and must also come after B (no field relation to B)
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Contact.class).set('LastName', 'C').alias('c').use('a', 'Id', 'AccountId').after('b'))
      .add(SBlueprint.of(Account.class).set('Name', 'A').alias('a'))
      .add(SBlueprint.of(Account.class).set('Name', 'B').alias('b'));

    // Act
    orchestrator.create();

    // Assert - value copied from A, and C inserted after B
    // (compare the sequential part of the mock ids: chars 3-14, skipping the key prefix)
    Contact c = (Contact) orchestrator.getByAlias('c');
    Assert.areEqual(orchestrator.getByAlias('a').Id, c.AccountId);
    String bSeq = String.valueOf(orchestrator.getByAlias('b').Id).substring(3, 15);
    String cSeq = String.valueOf(c.Id).substring(3, 15);
    Assert.isTrue(bSeq < cSeq, 'C (seq ' + cSeq + ') must be inserted after B (seq ' + bSeq + ')');
  }

  @isTest
  static void testAfter_WhenAliasIsNull_ThenThrowException() {
    // Act / Assert
    try {
      SBlueprint.of(Account.class).after(null);
      Assert.fail();
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('The `alias` argument is required'), e.getMessage());
    }
  }

  @isTest
  static void testCreate_WhenAfterUnknownAlias_ThenThrowCircularReferenceException() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'A').alias('a').after('nonexistent'));

    // Act / Assert
    try {
      orchestrator.create();
      Assert.fail();
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('Circular or invalid reference detected'));
    }
  }

  @isTest
  static void testCreate_WhenFieldDoesNotExist_ThenErrorExplainsIt() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('NoSuchField__c', 'x').alias('acc'));

    // Act / Assert
    try {
      orchestrator.create();
      Assert.fail();
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('NoSuchField__c'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('does not exist on Account'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('acc'), e.getMessage());
    }
  }

  @isTest
  static void testCreate_WhenFieldIsNotCreateable_ThenErrorExplainsIt() {
    // Arrange - Opportunity.ExpectedRevenue is a standard non-createable field
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Opportunity.class).set('ExpectedRevenue', 100).alias('opp'));

    // Act / Assert
    try {
      orchestrator.create();
      Assert.fail();
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('not createable'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('opp'), e.getMessage());
    }
  }

  @isTest
  static void testCreate_WhenFieldIsAutoNumber_ThenErrorExplainsIt() {
    // Arrange - Case.CaseNumber is a standard auto number field
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Case.class).set('CaseNumber', '00001').alias('cs'));

    // Act / Assert
    try {
      orchestrator.create();
      Assert.fail();
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('auto number'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('cs'), e.getMessage());
    }
  }

  @isTest
  static void testCreate_WhenValueTypeMismatch_ThenErrorExplainsFieldType() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('NumberOfEmployees', 'not-a-number').alias('acc'));

    // Act / Assert
    try {
      orchestrator.create();
      Assert.fail();
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('field type is'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('not-a-number'), e.getMessage());
    }
  }

  @isTest
  static void testCreate_WhenUseFromFieldDoesNotExist_ThenErrorExplainsIt() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'A').alias('acc'))
      .add(SBlueprint.of(Contact.class).set('LastName', 'C').alias('con').use('acc', 'NoSuchField__c', 'LastName'));

    // Act / Assert
    try {
      orchestrator.create();
      Assert.fail();
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('fromField'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('NoSuchField__c'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('does not exist on Account'), e.getMessage());
    }
  }

  @isTest
  static void testCreate_WhenUseToFieldDoesNotExist_ThenErrorExplainsIt() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(SBlueprint.of(Account.class).set('Name', 'A').alias('acc'))
      .add(SBlueprint.of(Contact.class).set('LastName', 'C').alias('con').use('acc', 'Id', 'NoSuchField__c'));

    // Act / Assert
    try {
      orchestrator.create();
      Assert.fail();
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('toField'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('NoSuchField__c'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('does not exist on Contact'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('con'), e.getMessage());
    }
  }

  @isTest
  static void testCreate_WhenAmbiousRelationship_ThenThrowException() {
    // Arrange
    SOrchestrator orchestrator = SOrchestrator.start(new MockDmlOperator())
      .add(
        SBlueprint.of(User.class)
          .set('LastName', 'Test User')
          .alias('usr')
          .withChildren(SBlueprint.of(Account.class).set('Name', 'Test Account').alias('acc'))
      );
    // Act / Assert
    try {
      orchestrator.create();
      Assert.fail();
    } catch (Exception e) {
      System.debug(e.getMessage());
      String expectedMessage = String.format(
        'The child object has multiple parent relationships with the same parent object. object name: {0}, parent object name: {1}',
        new List<String>{ 'Account', 'User' }
      );
      Assert.isTrue(e.getMessage().contains(expectedMessage));
    }
  }

  // ---------------------------------------------------------------------------------------------
  // Real DML: values filled in on save, and insert limits
  // ---------------------------------------------------------------------------------------------

  @isTest
  static void testCreate_WhenUseCopiesAFieldFilledInOnSave_ThenTheSavedValueIsCopied() {
    // Arrange: Probability is filled in from StageName on save; it used to be copied as null (issue #11)
    SOrchestrator orchestrator = SOrchestrator.start()
      .add(
        SBlueprint.of(Opportunity.class)
          .set('Name', 'src')
          .set('StageName', 'Prospecting')
          .set('CloseDate', Date.today())
          .alias('src')
      )
      .add(
        SBlueprint.of(Opportunity.class)
          .set('Name', 'dst')
          .set('StageName', 'Prospecting')
          .set('CloseDate', Date.today())
          .use('src', 'Probability', 'Amount')
          .alias('dst')
      );

    // Act
    orchestrator.create();

    // Assert
    Opportunity src = [SELECT Probability FROM Opportunity WHERE Id = :orchestrator.getByAlias('src').Id];
    Opportunity dst = [SELECT Amount FROM Opportunity WHERE Id = :orchestrator.getByAlias('dst').Id];
    Assert.isNotNull(src.Probability);
    Assert.areEqual(src.Probability, dst.Amount);
    Assert.areEqual(src.Probability, orchestrator.getByAlias('src').get('Probability'), 'getByAlias returns the saved value');
    Assert.areEqual('src', orchestrator.getByAlias('src').get('Name'), 'fields set by the blueprint are kept');
    Assert.isNull(orchestrator.getByAlias('src').get('Description'), 'a field neither set nor read back is null, not an error');
  }

  @isTest
  static void testCreate_WhenElevenTypesShareALayer_ThenAllAreInserted() {
    // Arrange: one save operation refuses more than ten types (issue #12)
    SOrchestrator orchestrator = SOrchestrator.start()
      .add(SBlueprint.of(Account.class).set('Name', 'a').alias('t1'))
      .add(SBlueprint.of(Contact.class).set('LastName', 'c').alias('t2'))
      .add(SBlueprint.of(Lead.class).set('LastName', 'l').set('Company', 'x').alias('t3'))
      .add(SBlueprint.of(Case.class).set('Subject', 's').alias('t4'))
      .add(SBlueprint.of(Campaign.class).set('Name', 'c').alias('t5'))
      .add(SBlueprint.of(Product2.class).set('Name', 'p').alias('t6'))
      .add(SBlueprint.of(Task.class).set('Subject', 't').alias('t7'))
      .add(SBlueprint.of(Pricebook2.class).set('Name', 'pb').alias('t8'))
      .add(SBlueprint.of(Solution.class).set('SolutionName', 's').alias('t9'))
      .add(SBlueprint.of(Topic.class).set('Name', 'apexblueprint-topic').alias('t10'))
      .add(
        SBlueprint.of(Opportunity.class)
          .set('Name', 'o')
          .set('StageName', 'Prospecting')
          .set('CloseDate', Date.today())
          .alias('t11')
      );

    // Act
    orchestrator.create();

    // Assert
    for (Integer i = 1; i <= 11; i++) {
      Assert.isNotNull(orchestrator.getByAlias('t' + i).Id, 't' + i + ' must be inserted');
    }
  }

  @isTest
  static void testCreate_WhenTwoTypesAreAddedInTurns_ThenTheInsertIsSplitAtTenChunks() {
    // Arrange: two types added in turns made twelve chunks, over the limit of ten (issue #12)
    SOrchestrator orchestrator = SOrchestrator.start();
    for (Integer i = 0; i < 6; i++) {
      orchestrator = orchestrator.add(SBlueprint.of(Account.class).set('Name', 'a' + i).alias('a' + i))
        .add(SBlueprint.of(Contact.class).set('LastName', 'c' + i).alias('c' + i));
    }

    // Act
    Integer dmlBefore = Limits.getDmlStatements();
    orchestrator.create();
    Integer dmlUsed = Limits.getDmlStatements() - dmlBefore;

    // Assert
    for (Integer i = 0; i < 6; i++) {
      Assert.isNotNull(orchestrator.getByAlias('a' + i).Id);
      Assert.isNotNull(orchestrator.getByAlias('c' + i).Id);
    }
    Assert.areEqual(2, dmlUsed, 'Twelve chunks are split into ten and two, keeping the order');
  }

  @isTest
  static void testCreate_WhenChildBlueprintIsReused_ThenTheCallersBlueprintIsUnchanged() {
    // Arrange: the analyzer and the realizer used to write into the caller's child blueprint (issue #7)
    SBlueprint contact = SBlueprint.of(Contact.class).set('LastName', 'c{#}').alias('{P0}_c{#}').times(2);
    SBlueprint account = SBlueprint.of(Account.class).set('Name', 'acc{#}').alias('acc{#}').times(2).withChildren(contact);
    String childAliasBefore = contact.getAlias();
    Integer childPlansBefore = contact.getParentBuildPlans().size();

    // Act
    SOrchestrator first = SOrchestrator.start().add(account);
    first.create();
    SOrchestrator second = SOrchestrator.start().add(account);
    second.create();

    // Assert
    Assert.areEqual(childAliasBefore, contact.getAlias());
    Assert.areEqual(childPlansBefore, contact.getParentBuildPlans().size());
    Assert.areEqual(0, contact.getDependencies().size());
    Assert.areEqual(second.getByAlias('acc2').Id, ((Contact) [SELECT AccountId FROM Contact WHERE Id = :second.getByAlias('acc2_c1').Id]).AccountId);
  }

  @isTest
  static void testDeepCopy_WhenTheCopysDependencyChanges_ThenTheOriginalIsUntouched() {
    // Arrange
    SBlueprint original = SBlueprint.of(Contact.class).use('acc', 'Id', 'AccountId').alias('con');

    // Act
    SBlueprint copy = original.deepCopy();
    copy.getDependencies()[0].alias = 'changed';
    copy.getAliasDefinition().alias = 'changed';

    // Assert
    Assert.areEqual('acc', original.getDependencies()[0].alias);
    Assert.areEqual('con', original.getAlias());
  }

  @isTest
  static void testTimesAndTemplate_WhenNull_ThenRequiredError() {
    try {
      SBlueprint.of(Account.class).times(null);
      Assert.fail('times(null) must be refused');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('times'), e.getMessage());
    }
    try {
      SBlueprint.of(Account.class).template(null);
      Assert.fail('template(null) must be refused');
    } catch (ApexBlueprintException e) {
      Assert.isTrue(e.getMessage().contains('template'), e.getMessage());
    }
  }

  @isTest
  static void testMockDmlOperator_WhenTwoMocksInsert_ThenIdsDoNotCollide() {
    // Arrange
    Account first = new Account(Name = 'a');
    Account second = new Account(Name = 'b');

    // Act
    new MockDmlOperator().doInsert(new List<SObject>{ first });
    new MockDmlOperator().doInsert(new List<SObject>{ second });

    // Assert
    Assert.areNotEqual(first.Id, second.Id);
  }

  @isTest
  static void testCreate_WhenALayerFitsInOneInsert_ThenOneDml() {
    // Arrange: ten types in one layer, each added once
    SOrchestrator orchestrator = SOrchestrator.start()
      .add(SBlueprint.of(Account.class).set('Name', 'a').alias('t1'))
      .add(SBlueprint.of(Contact.class).set('LastName', 'c').alias('t2'))
      .add(SBlueprint.of(Lead.class).set('LastName', 'l').set('Company', 'x').alias('t3'))
      .add(SBlueprint.of(Case.class).set('Subject', 's').alias('t4'))
      .add(SBlueprint.of(Campaign.class).set('Name', 'c').alias('t5'))
      .add(SBlueprint.of(Product2.class).set('Name', 'p').alias('t6'))
      .add(SBlueprint.of(Task.class).set('Subject', 't').alias('t7'))
      .add(SBlueprint.of(Pricebook2.class).set('Name', 'pb').alias('t8'))
      .add(SBlueprint.of(Solution.class).set('SolutionName', 's').alias('t9'))
      .add(SBlueprint.of(Topic.class).set('Name', 'apexblueprint-topic').alias('t10'));

    // Act
    Integer dmlBefore = Limits.getDmlStatements();
    orchestrator.create();

    // Assert
    Assert.areEqual(1, Limits.getDmlStatements() - dmlBefore, 'A layer that used to succeed is still one insert');
  }

  @isTest
  static void testCreate_WhenOneUseReadsAField_ThenOnlyItsSourceIsQueried() {
    // Arrange: earlier records of five types have a Name; only one use() reads one of them
    SOrchestrator orchestrator = SOrchestrator.start()
      .add(SBlueprint.of(Account.class).set('Name', 'acc').alias('acc'))
      .add(SBlueprint.of(Campaign.class).set('Name', 'cmp').alias('cmp'))
      .add(SBlueprint.of(Product2.class).set('Name', 'prd').alias('prd'))
      .add(SBlueprint.of(Pricebook2.class).set('Name', 'pb').alias('pb'))
      .add(SBlueprint.of(Topic.class).set('Name', 'apexblueprint-topic').alias('topic'))
      .add(SBlueprint.of(Contact.class).set('LastName', 'c').use('acc', 'Name', 'Description').alias('con'));

    // Act
    Integer queriesBefore = Limits.getQueries();
    orchestrator.create();
    Integer queriesUsed = Limits.getQueries() - queriesBefore;

    // Assert
    Assert.areEqual(1, queriesUsed, 'Only the Account that the use() reads is queried');
    Assert.areEqual('acc', ((Contact) [SELECT Description FROM Contact WHERE Id = :orchestrator.getByAlias('con').Id]).Description);
  }

  @isTest
  static void testCreate_WhenOnlyIdIsUsed_ThenNothingIsQueried() {
    // Arrange: insert already writes the Id back, so a use() of Id needs no query
    SOrchestrator orchestrator = SOrchestrator.start()
      .add(SBlueprint.of(Account.class).set('Name', 'acc').alias('acc'))
      .add(SBlueprint.of(Contact.class).set('LastName', 'c').use('acc', 'Id', 'AccountId').alias('con'));

    // Act
    Integer queriesBefore = Limits.getQueries();
    orchestrator.create();

    // Assert
    Assert.areEqual(0, Limits.getQueries() - queriesBefore);
  }

  @isTest
  static void testCreate_WhenChildCopiesAParentFieldFilledInOnSave_ThenEachChildGetsItsParentsValue() {
    // Arrange: NumberOfLeads is filled in as 0 on save; the copy is recorded inside the per-parent recursion
    SBlueprint parent = SBlueprint.of(Campaign.class)
      .set('Name', 'cmp{#}')
      .alias('cmp{#}')
      .times(2)
      .withChildren(
        SBlueprint.of(Opportunity.class)
          .set('Name', 'child{#}')
          .set('StageName', 'Prospecting')
          .set('CloseDate', Date.today())
          .use('{P0}', 'NumberOfLeads', 'TotalOpportunityQuantity')
          .use('{P0}', 'BudgetedCost', 'Amount')
          .alias('{P0}_opp')
      )
      .set('BudgetedCost', '{#}');

    // Act
    SOrchestrator orchestrator = SOrchestrator.start().add(parent);
    orchestrator.create();

    // Assert: each child holds the saved value of its own parent, not the in-memory null
    for (Integer i = 1; i <= 2; i++) {
      String parentAlias = 'cmp' + i;
      Opportunity child = [
        SELECT CampaignId, TotalOpportunityQuantity, Amount
        FROM Opportunity
        WHERE Id = :orchestrator.getByAlias(parentAlias + '_opp').Id
      ];
      Assert.areEqual(orchestrator.getByAlias(parentAlias).Id, child.CampaignId);
      Assert.areEqual(0, child.TotalOpportunityQuantity);
      Assert.areEqual(i, child.Amount, 'Each child copies its own parent, not another one');
    }
  }

  /**
   * Records the order of the types handed to each insert, and inserts for real.
   */
  private class RecordingDmlOperator implements IDmlOperator {
    public List<List<String>> typesPerInsert = new List<List<String>>();

    public void doInsert(List<SObject> records) {
      List<String> types = new List<String>();
      for (SObject record : records) {
        types.add(record.getSObjectType().getDescribe().getName());
      }
      this.typesPerInsert.add(types);
      insert records;
    }

    public void doUpdate(List<SObject> records) {
      update records;
    }

    public void doDelete(List<SObject> records) {
      delete records;
    }
  }

  @isTest
  static void testCreate_WhenTypesAlternateWithinTheLimit_ThenTheOrderIsKept() {
    // Arrange
    RecordingDmlOperator recorder = new RecordingDmlOperator();
    SOrchestrator orchestrator = SOrchestrator.start(recorder)
      .add(SBlueprint.of(Account.class).set('Name', 'a1').alias('a1'))
      .add(SBlueprint.of(Contact.class).set('LastName', 'c1').alias('c1'))
      .add(SBlueprint.of(Account.class).set('Name', 'a2').alias('a2'));

    // Act
    orchestrator.create();

    // Assert
    Assert.areEqual(1, recorder.typesPerInsert.size());
    Assert.areEqual(new List<String>{ 'Account', 'Contact', 'Account' }, recorder.typesPerInsert[0]);
  }

  @isTest
  static void testCreate_WhenSixTypesHave201RecordsEach_ThenTheInsertIsSplitAtTenChunks() {
    // Arrange: every 200 records of one type is a chunk, so this layer is twelve chunks
    RecordingDmlOperator recorder = new RecordingDmlOperator();
    SOrchestrator orchestrator = SOrchestrator.start(recorder)
      .add(SBlueprint.of(Account.class).set('Name', 'a{#}').alias('a{#}').times(201))
      .add(SBlueprint.of(Contact.class).set('LastName', 'c{#}').alias('c{#}').times(201))
      .add(SBlueprint.of(Lead.class).set('LastName', 'l{#}').set('Company', 'x').alias('l{#}').times(201))
      .add(SBlueprint.of(Case.class).set('Subject', 's{#}').alias('s{#}').times(201))
      .add(SBlueprint.of(Campaign.class).set('Name', 'm{#}').alias('m{#}').times(201))
      .add(SBlueprint.of(Product2.class).set('Name', 'p{#}').alias('p{#}').times(201));

    // Act
    orchestrator.create();

    // Assert
    Assert.areEqual(2, recorder.typesPerInsert.size());
    Assert.areEqual(1206, recorder.typesPerInsert[0].size() + recorder.typesPerInsert[1].size());
    Assert.isNotNull(orchestrator.getByAlias('p201').Id);
  }

  @isTest
  static void testCreate_WhenALayerHasOneTypeOver2000Records_ThenOneInsert() {
    // Arrange: a list of one type has no chunk limit, so it must not be split
    RecordingDmlOperator recorder = new RecordingDmlOperator();
    SOrchestrator orchestrator = SOrchestrator.start(recorder)
      .add(SBlueprint.of(Account.class).set('Name', 'a{#}').alias('a{#}').times(2001));

    // Act
    orchestrator.create();

    // Assert
    Assert.areEqual(1, recorder.typesPerInsert.size());
    Assert.areEqual(2001, recorder.typesPerInsert[0].size());
  }

  @isTest
  static void testCreate_WhenUseCopiesContentDocumentId_ThenTheFileIsLinked() {
    // Arrange: ContentDocumentId is filled in on save, and the source record carries a Base64 body
    SOrchestrator orchestrator = SOrchestrator.start()
      .add(
        SBlueprint.of(ContentVersion.class)
          .set('Title', 't')
          .set('PathOnClient', 't.txt')
          .set('VersionData', Blob.valueOf('body'))
          .alias('cv')
      )
      .add(SBlueprint.of(Account.class).set('Name', 'a').alias('acc'))
      .add(
        SBlueprint.of(ContentDocumentLink.class)
          .use('cv', 'ContentDocumentId', 'ContentDocumentId')
          .use('acc', 'Id', 'LinkedEntityId')
          .alias('cdl')
      );

    // Act
    orchestrator.create();

    // Assert
    ContentVersion saved = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :orchestrator.getByAlias('cv').Id];
    Assert.areEqual(saved.ContentDocumentId, orchestrator.getByAlias('cdl').get('ContentDocumentId'));
    Assert.areEqual('body', ((Blob) orchestrator.getByAlias('cv').get('VersionData')).toString(), 'the body comes from memory');
  }
}
