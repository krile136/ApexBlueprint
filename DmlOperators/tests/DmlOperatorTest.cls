@isTest
public with sharing class DmlOperatorTest {
  @isTest
  static void testDoInsertUpdateDelete_WhenExecute_ThenSuccess() {
    // Arrange
    // Document is used because it supports no triggers, validation rules, record
    // types, or custom fields — the DML can never be broken by org customization.
    List<Document> docList = new List<Document>{
      new Document(Name = 'Test Document', FolderId = UserInfo.getUserId())
    };
    DmlOperator dmlOperator = new DmlOperator();

    // Act
    try {
      dmlOperator.doInsert(docList);
      docList[0].Name = 'Updated Document';
      dmlOperator.doUpdate(docList);
      dmlOperator.doDelete(docList);
    } catch (Exception e) {
      // Assert
      Assert.fail('例外が発生しました。' + e.getMessage());
    }
  }
}
