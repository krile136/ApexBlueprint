/**
 * @directory ApexBlueprint/DmlOperators
 */
public interface IDmlOperator {
  void doInsert(List<SObject> records);
  void doUpdate(List<SObject> records);
  void doDelete(List<SObject> records);
}
