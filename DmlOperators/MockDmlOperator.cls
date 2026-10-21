/**
 * @directory ApexBlueprint/DmlOperators
 */
public with sharing class MockDmlOperator implements IDmlOperator {
  // Static so that two mocks in one test never hand out the same Id (issue #13).
  private static Integer insertCount = 0;

  public void doInsert(List<SObject> records){
    System.debug('Mock inserting ' + records.size() + ' records.');
    for(SObject record : records){
      record.Id = genereteId(record);
    }
  }
  public void doUpdate(List<SObject> records){
    // do nothing
  }
  public void doDelete(List<SObject> records) {
    // do nothing
  }

  /**
   * generate a mock Id for the record
   *
   * @param record SObject to be inserted
   * @return generated Id
   */
  private String genereteId(SObject record) {
    String prefix = record.getSObjectType().getDescribe().getKeyPrefix();
    String generatedId = prefix + String.valueOf(insertCount).leftPad(12, '0');
    insertCount++;
    return generatedId;
  }
}
