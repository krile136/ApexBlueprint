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
}
