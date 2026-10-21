/**
 * Copyright 2025 Hiroyuki Matsuoka
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * The main orchestrator for building and creating test data from a collection of SBlueprints.
 * It manages the analysis of dependencies, the ordering of creation, and the final DML operations.
 * @directory ApexBlueprint
 */
public with sharing class SOrchestrator {
  private static final String CLASS_NAME = 'SOrchestrator';

  // =================================================================================
  // Properties
  // =================================================================================

  @TestVisible
  private List<SBlueprint> sBlueprints;
  private Map<String, SObject> aliasToSObject = new Map<String, SObject>();
  private IDmlOperator dmlOperator;

  // =================================================================================
  // Constructors & Factory Methods
  // =================================================================================

  /**
   * Private constructor. Use `start()` factory methods for instantiation.
   * Initializes with the default DML operator.
   */
  private SOrchestrator() {
    this.sBlueprints = new List<SBlueprint>();
    this.dmlOperator = new DmlOperator();
  }

  /**
   * Private constructor for dependency injection.
   *
   * @param dmlOperator The DML operator strategy to use (e.g., a mock for testing).
   */
  private SOrchestrator(IDmlOperator dmlOperator) {
    this.sBlueprints = new List<SBlueprint>();
    this.dmlOperator = dmlOperator;
  }

  /**
   * Starts the orchestrator build chain.
   *
   * @return A new SOrchestrator instance.
   */
  public static SOrchestrator start() {
    return new SOrchestrator();
  }

  /**
   * Starts the orchestrator build chain with a custom DML operator.
   *
   * @param dmlOperator The DML operator strategy to use.
   * @return A new SOrchestrator instance configured with the custom operator.
   */
  public static SOrchestrator start(IDmlOperator dmlOperator) {
    return new SOrchestrator(dmlOperator);
  }

  // =================================================================================
  // Public API (Fluent Interface)
  // =================================================================================

  /**
   * Adds an SBlueprint to the orchestration queue.
   *
   * @param sBlueprint The blueprint to add.
   * @return A new SOrchestrator instance with the blueprint added.
   * @throws ApexBlueprintException if the provided sBlueprint is null.
   */
  public SOrchestrator add(SBlueprint sBlueprint) {
    if (sBlueprint == null) {
      ApexBlueprintException.required(CLASS_NAME, 'add(SBlueprint sBlueprint)', 'sBlueprint', sBlueprint).fire();
    }
    SOrchestrator newSOrchestrator = this.deepCopy();
    newSOrchestrator.sBlueprints.add(sBlueprint);
    return newSOrchestrator;
  }

  // =================================================================================
  // Public API (Execution & Access)
  // =================================================================================

  /**
   * Analyzes dependencies, realizes all SBlueprints into SObjects, and inserts them in the correct order.
   * This is the final execution method.
   */
  public void create() {
    BuildLayers buildLayers = (new SBlueprintAnalyzer(this.sBlueprints)).analyze();
    buildLayers.realizeAll(this.aliasToSObject, buildLayers.getMaxDepth(), this.dmlOperator);
  }

  /**
   * Retrieves a created SObject record by its alias.
   * This should be called after `create()` has been executed.
   *
   * Every record has its Id and the fields the blueprint set; a field not set reads as null.
   * A record that a later use() copied a non-Id field from also holds the saved values of the
   * fields read back for it (the copied fields and the fields the blueprint set, except
   * Base64 fields, which keep the in-memory value). Other
   * values Salesforce fills in on save are not there as a rule (a value that SOQL returns
   * without being asked may be); query the record when you need those.
   *
   * @param alias The alias of the record to retrieve.
   * @return The SObject record, or null if the alias is not found.
   */
  public SObject getByAlias(String alias) {
    return this.aliasToSObject.get(alias);
  }

  // =================================================================================
  // Private Helper Methods
  // =================================================================================

  /**
   * Creates a deep copy of the orchestrator to maintain immutability.
   *
   * @return A new SOrchestrator instance.
   */
  private SOrchestrator deepCopy() {
    SOrchestrator newSOrchestrator = new SOrchestrator(this.dmlOperator);
    newSOrchestrator.sBlueprints = this.sBlueprints.clone();
    newSOrchestrator.aliasToSObject = this.aliasToSObject.clone();
    return newSOrchestrator;
  }

  // =================================================================================
  // Inner Classes for Data Structure
  // =================================================================================

  /**
   * Represents a single layer in the build process, containing blueprints with the same dependency depth.
   */
  public class BuildLayer {
    private List<SBlueprint> sBlueprints = new List<SBlueprint>();

    /**
     * Adds a blueprint to this layer.
     *
     * @param sBlueprint The blueprint to add.
     */
    public void addSBlueprint(SBlueprint sBlueprint) {
      this.sBlueprints.add(sBlueprint);
    }

    /**
     * Gets all blueprints in this layer.
     *
     * @return A list of SBlueprints.
     */
    public List<SBlueprint> getSBlueprints() {
      return this.sBlueprints;
    }

    /**
     * Realizes all blueprints in this layer and inserts the resulting SObjects.
     *
     * @param aliasToSObject The master map of all created records, which gets updated.
     * @param dmlOperator The strategy for performing the DML operation.
     */
    public void realizeLayer(Map<String, SObject> aliasToSObject, IDmlOperator dmlOperator) {
      Map<String, SObject> layerAliasToSObject = new Map<String, SObject>();
      List<SBlueprintRealizer.DeferredCopy> deferredCopies = new List<SBlueprintRealizer.DeferredCopy>();
      for (SBlueprint sBlueprint : this.sBlueprints) {
        SBlueprintRealizer realizer = new SBlueprintRealizer(
          sBlueprint,
          aliasToSObject,
          new Map<String, String>(),
          0,
          deferredCopies
        );
        Map<String, SObject> newAliasToSObject = realizer.realize();

        for (String alias : newAliasToSObject.keySet()) {
          if (layerAliasToSObject.containsKey(alias)) {
            String errorMessage = String.format(
              'Duplicate alias detected: {0}\nAliases must be unique across all SBlueprint definitions to ensure records can be correctly identified. Please provide a unique alias.',
              new List<String>{ alias }
            );
            ApexBlueprintException.invalidOperation(CLASS_NAME, 'realizeLayer()', errorMessage).fire();
          }
          layerAliasToSObject.put(alias, newAliasToSObject.get(alias));
        }
      }

      if (!(dmlOperator instanceof MockDmlOperator)) {
        applySavedValues(deferredCopies, aliasToSObject);
      }
      insertKeepingOrder(layerAliasToSObject.values(), dmlOperator);

      for (String alias : layerAliasToSObject.keySet()) {
        if (aliasToSObject.containsKey(alias)) {
          String errorMessage = String.format(
            'Duplicate alias detected: {0}\nAliases must be unique across all SBlueprint definitions to ensure records can be correctly identified. Please provide a unique alias.',
            new List<String>{ alias }
          );
          ApexBlueprintException.invalidOperation(CLASS_NAME, 'realizeLayer()', errorMessage).fire();
        }
        aliasToSObject.put(alias, layerAliasToSObject.get(alias));
      }
    }
  }

  /**
   * Redoes the use() copies of non-Id fields from the values saved in the database.
   *
   * The source records in aliasToSObject are the ones built in memory; insert only writes
   * their Id back. A field Salesforce fills in on save (a default, an auto number, a formula,
   * a value set by a trigger or flow) is still null there, and use() copied that null without
   * any error (measured on API v67.0: Opportunity.Probability is 10 in the database and null
   * in memory, issue #11).
   *
   * Only the records a use() actually reads are queried, with only the fields it reads plus
   * the fields already set in memory: one query per source type, so a layer with no such
   * use() costs nothing. The record getByAlias() returns for it then holds the saved values
   * of the queried fields (which can differ from what the blueprint set, for example after
   * rounding or a trigger) on top of the in-memory ones (see mergeSaved). Base64 fields are
   * never queried, even when a use() reads one; the in-memory value is carried over, so file
   * bodies are not read back into the heap.
   *
   * Changed behaviour: a use() between fields of different types used to copy the in-memory
   * null without complaint; it now fails when the saved value cannot be put.
   *
   * The query runs without sharing: test data created under System.runAs and owned by
   * another user must still be readable. A source record that still cannot be read fails
   * loudly instead of leaving the in-memory null in place.
   *
   * Rejected alternatives: re-reading every earlier record of every type that has a field
   * with the requested name (queries and getByAlias changed for records no use() reads), and
   * refusing a use() whose in-memory value is null (a field filled in on save could then not
   * be copied at all).
   *
   * @param deferredCopies The copies recorded by the realizers of this layer
   * @param aliasToSObject The records of the earlier layers, by alias (updated in place)
   */
  private static void applySavedValues(
    List<SBlueprintRealizer.DeferredCopy> deferredCopies,
    Map<String, SObject> aliasToSObject
  ) {
    if (deferredCopies.isEmpty()) {
      return;
    }
    Map<Schema.SObjectType, Set<String>> fieldsByType = new Map<Schema.SObjectType, Set<String>>();
    Map<Schema.SObjectType, Set<String>> aliasesByType = new Map<Schema.SObjectType, Set<String>>();
    for (SBlueprintRealizer.DeferredCopy deferredCopy : deferredCopies) {
      SObject source = aliasToSObject.get(deferredCopy.sourceAlias);
      Schema.SObjectType sourceType = source.getSObjectType();
      if (!fieldsByType.containsKey(sourceType)) {
        fieldsByType.put(sourceType, new Set<String>{ 'id' });
        aliasesByType.put(sourceType, new Set<String>());
      }
      Schema.SObjectField fromField = sourceType.getDescribe().fields.getMap().get(deferredCopy.fromField.toLowerCase());
      if (fromField != null && fromField.getDescribe().getType() != Schema.DisplayType.BASE64) {
        fieldsByType.get(sourceType).add(deferredCopy.fromField.toLowerCase());
      }
      aliasesByType.get(sourceType).add(deferredCopy.sourceAlias);
    }

    for (Schema.SObjectType sourceType : fieldsByType.keySet()) {
      Map<String, Schema.SObjectField> fieldMap = sourceType.getDescribe().fields.getMap();
      Set<String> selectFields = fieldsByType.get(sourceType);
      Set<Id> ids = new Set<Id>();
      for (String alias : aliasesByType.get(sourceType)) {
        SObject source = aliasToSObject.get(alias);
        ids.add(source.Id);
        for (String populated : source.getPopulatedFieldsAsMap().keySet()) {
          Schema.SObjectField field = fieldMap.get(populated.toLowerCase());
          if (field != null && field.getDescribe().getType() != Schema.DisplayType.BASE64) {
            selectFields.add(populated.toLowerCase());
          }
        }
      }
      String soql =
        'SELECT ' + String.join(new List<String>(selectFields), ', ') +
        ' FROM ' + sourceType.getDescribe().getName() + ' WHERE Id IN :ids';
      Map<Id, SObject> saved = new Map<Id, SObject>(new SavedRecordReader().read(soql, ids));

      for (String alias : aliasesByType.get(sourceType)) {
        SObject source = aliasToSObject.get(alias);
        SObject savedRecord = saved.get(source.Id);
        if (savedRecord == null) {
          String reason = 'The record of alias \'' + alias + '\' could not be read back to copy its saved values.';
          ApexBlueprintException.invalidOperation(CLASS_NAME, 'applySavedValues()', reason)
            .action(
              'Check that the record was not deleted by a trigger or flow before the next layer. ' +
              'With a custom IDmlOperator that does not write to the database, use MockDmlOperator, ' +
              'or copy only Id with use().'
            )
            .fire();
        }
        aliasToSObject.put(alias, mergeSaved(source, savedRecord));
      }
    }

    for (SBlueprintRealizer.DeferredCopy deferredCopy : deferredCopies) {
      try {
        Object value = aliasToSObject.get(deferredCopy.sourceAlias).get(deferredCopy.fromField);
        deferredCopy.target.put(deferredCopy.toField, value);
      } catch (Exception e) {
        String reason = 'The saved value of \'' + deferredCopy.fromField + '\' on alias \'' + deferredCopy.sourceAlias +
          '\' could not be copied to \'' + deferredCopy.toField + '\': ' + e.getMessage();
        ApexBlueprintException.invalidOperation(CLASS_NAME, 'applySavedValues()', reason)
          .action('Check that use(\'' + deferredCopy.declaredAlias + '\', ...) copies between fields of compatible types.')
          .fire();
      }
    }
  }

  /**
   * Builds the record getByAlias() returns: the fields set in memory, overlaid with the
   * fields read back from the database.
   *
   * The queried record itself is not returned: reading a field it did not select throws
   * (`SObject row was retrieved via SOQL without querying the requested field`), while the
   * in-memory record returned null for any field not set. Going through JSON keeps that:
   * a field neither set nor queried reads as null (measured on API v67.0), and fields that
   * cannot be put in Apex, such as formulas, still carry their saved value.
   *
   * Base64 values stay out of the JSON and are put back on the result afterwards: JSON
   * cannot turn them back into a field (`Cannot deserialize instance of base64`, measured on
   * ContentVersion.VersionData), and passing a file body through a string would hold it in
   * the heap several times over. Putting the original Blob back passes a reference.
   *
   * @param inMemory The record built by the realizer and inserted
   * @param saved The same record as read back from the database
   * @return A record with both sets of values
   */
  private static SObject mergeSaved(SObject inMemory, SObject saved) {
    Map<String, Object> fields = new Map<String, Object>(inMemory.getPopulatedFieldsAsMap());
    fields.putAll(saved.getPopulatedFieldsAsMap());
    Map<String, Schema.SObjectField> fieldMap = inMemory.getSObjectType().getDescribe().fields.getMap();
    Map<String, Object> base64Values = new Map<String, Object>();
    for (String name : new List<String>(fields.keySet())) {
      Schema.SObjectField field = fieldMap.get(name.toLowerCase());
      if (field != null && field.getDescribe().getType() == Schema.DisplayType.BASE64) {
        base64Values.put(name, fields.remove(name));
      }
    }
    String typeName = inMemory.getSObjectType().getDescribe().getName();
    System.Type apexType = Type.forName(typeName);
    if (apexType == null) {
      String reason = 'The SObject type \'' + typeName + '\' could not be resolved to rebuild the saved record.';
      ApexBlueprintException.invalidOperation(CLASS_NAME, 'mergeSaved()', reason).fire();
    }
    fields.put('attributes', new Map<String, Object>{ 'type' => typeName });
    SObject merged = (SObject) JSON.deserialize(JSON.serialize(fields), apexType);
    for (String name : base64Values.keySet()) {
      merged.put(name, base64Values.get(name));
    }
    return merged;
  }

  /**
   * Reads saved records regardless of sharing, for applySavedValues().
   */
  private without sharing class SavedRecordReader {
    /**
     * @param soql The query, binding the Ids as :ids
     * @param ids The record Ids
     * @return The records found
     */
    public List<SObject> read(String soql, Set<Id> ids) {
      return Database.queryWithBinds(soql, new Map<String, Object>{ 'ids' => ids }, AccessLevel.SYSTEM_MODE);
    }
  }

  /**
   * The most SObject types, and the most chunks, Salesforce accepts in one save operation.
   */
  private static final Integer MAX_TYPES_PER_INSERT = 10;

  /**
   * The most records of one type that Salesforce counts as one chunk, in a list that mixes types.
   */
  private static final Integer MAX_RECORDS_PER_CHUNK = 200;

  /**
   * Inserts the records in the order they were added, splitting the insert only where one
   * more record would pass ten types or ten chunks.
   *
   * One save operation refuses more than ten types, and more than ten chunks. In a list that
   * mixes types, a chunk ends wherever the type changes, and also after every 200 records of
   * one type: six types of 201 records each made twelve chunks, and 2001 Accounts with one
   * Contact were refused. A list of one type has no chunk limit (2001 Accounts went in one
   * insert), so a layer of one type is never split. Inserting the layer in one go failed
   * with eleven independent types, with only two types added in turns, and with that
   * 201-record layer (all measured on API v67.0, issue #12).
   * Rejected alternative: grouping the records by type. It needs fewer inserts, but it
   * reorders records across types, which changes what triggers see for input that already
   * worked. With this split, any layer that used to succeed is still one insert in the same
   * order.
   *
   * @param records The records of one layer, in the order they were added
   * @param dmlOperator The operator that performs the insert
   */
  private static void insertKeepingOrder(List<SObject> records, IDmlOperator dmlOperator) {
    Set<Schema.SObjectType> layerTypes = new Set<Schema.SObjectType>();
    for (SObject record : records) {
      layerTypes.add(record.getSObjectType());
    }
    if (layerTypes.size() <= 1) {
      // A list of one type has no chunk limit: 2001 Accounts go in one insert (measured).
      if (!records.isEmpty()) {
        dmlOperator.doInsert(records);
      }
      return;
    }
    List<SObject> batch = new List<SObject>();
    Set<Schema.SObjectType> typesInBatch = new Set<Schema.SObjectType>();
    Integer chunksInBatch = 0;
    Integer recordsInChunk = 0;
    Schema.SObjectType previousType = null;
    for (SObject record : records) {
      Schema.SObjectType recordType = record.getSObjectType();
      Boolean startsChunk = recordType != previousType || recordsInChunk == MAX_RECORDS_PER_CHUNK;
      Boolean addsType = !typesInBatch.contains(recordType);
      if (
        !batch.isEmpty() &&
        ((startsChunk && chunksInBatch == MAX_TYPES_PER_INSERT) || (addsType && typesInBatch.size() == MAX_TYPES_PER_INSERT))
      ) {
        dmlOperator.doInsert(batch);
        batch = new List<SObject>();
        typesInBatch = new Set<Schema.SObjectType>();
        chunksInBatch = 0;
        startsChunk = true;
      }
      if (startsChunk) {
        chunksInBatch++;
        recordsInChunk = 0;
      }
      recordsInChunk++;
      typesInBatch.add(recordType);
      batch.add(record);
      previousType = recordType;
    }
    if (!batch.isEmpty()) {
      dmlOperator.doInsert(batch);
    }
  }

  /**
   * Represents all ordered layers of the build process.
   */
  public class BuildLayers {
    private Map<String, BuildLayer> layers = new Map<String, BuildLayer>();

    /**
     * Gets the maximum depth of the build layers.
     * @return The highest layer number.
     */
    public Integer getMaxDepth() {
      Integer maxDepth = 0;
      for (String layerKey : this.layers.keySet()) {
        Integer layerNum = Integer.valueOf(layerKey);
        if (layerNum > maxDepth) {
          maxDepth = layerNum;
        }
      }
      return maxDepth;
    }

    /**
     * Adds a blueprint to a specific layer.
     *
     * @param layerNumber The layer to add the blueprint to.
     * @param sBlueprint The blueprint to add.
     */
    public void addSBlueprint(Integer layerNumber, SBlueprint sBlueprint) {
      String layerKey = String.valueOf(layerNumber);
      if (!this.layers.containsKey(layerKey)) {
        this.layers.put(layerKey, new BuildLayer());
      }
      this.layers.get(layerKey).addSBlueprint(sBlueprint);
    }

    /**
     * A convenience method to add a blueprint to the root layer (layer 0).
     *
     * @param sBlueprint The blueprint to add.
     */
    public void addRoot(SBlueprint sBlueprint) {
      this.addSBlueprint(0, sBlueprint);
    }

    /**
     * Gets all blueprints for a specific layer.
     *
     * @param layerNumber The layer number to retrieve.
     * @return A list of SBlueprints.
     */
    public List<SBlueprint> getSBlueprintsByLayer(Integer layerNumber) {
      String layerKey = String.valueOf(layerNumber);
      return this.layers.containsKey(layerKey)
        ? this.layers.get(layerKey).getSBlueprints()
        : new List<SBlueprint>();
    }

    /**
     * Gets all blueprints in the root layer (layer 0).
     *
     * @return A list of root SBlueprints.
     */
    public List<SBlueprint> getRoots() {
      return this.getSBlueprintsByLayer(0);
    }

    /**
     * Realizes all layers in order, from layer 0 to the max layer.
     *
     * @param aliasToSObject The master map of aliases to SObjects.
     * @param maxLayer The maximum layer depth to process.
     * @param dmlOperator The strategy for performing DML operations.
     */
    public void realizeAll(Map<String, SObject> aliasToSObject, Integer maxLayer, IDmlOperator dmlOperator) {
      for (Integer i = 0; i <= maxLayer; i++) {
        String layerKey = String.valueOf(i);
        if (this.layers.containsKey(layerKey)) {
          this.layers.get(layerKey).realizeLayer(aliasToSObject, dmlOperator);
        }
      }
    }
  }
}
