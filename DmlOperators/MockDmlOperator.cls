/**
 * @directory ApexBlueprint/DmlOperators
 */
public with sharing class MockDmlOperator implements IDmlOperator {
  private Integer insertCount;

  public MockDmlOperator() {
    this.insertCount = 0;
  }

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
    String generatedId = prefix + String.valueOf(this.insertCount).leftPad(12, '0');
    this.insertCount++;
    return generatedId;
  }
}
