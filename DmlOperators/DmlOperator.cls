/**
 * @directory ApexBlueprint/DmlOperators
 */
public with sharing class DmlOperator implements IDmlOperator {
  public void doInsert(List<SObject> records){
    System.debug('Inserting ' + records.size() + ' records.');
    insert records;
  }
  public void doUpdate(List<SObject> records){
    update records;
  }
  public void doDelete(List<SObject> records) {
    delete records;
  }
}
