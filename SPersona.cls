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
 * A fluent builder for test users ("personas") used in runAs audit tests.
 *
 * Creating a restricted user for a System.runAs block involves a pile of subtle
 * mechanics that are easy to get slightly wrong when hand-rolled per project:
 *
 * - mixed DML avoidance (User / PermissionSetAssignment are setup objects, so the
 *   inserts are wrapped in System.runAs(current user))
 * - unique Username generation that is safe under parallel test execution
 * - required User field defaults (TimeZone / Locale / Language / Email encoding / Alias)
 * - Profile name resolution with a static cache
 * - PermissionSet assignment
 *
 * SPersona centralizes the one correct implementation. Project-specific archetypes
 * should be collected in a project-side `Personas` class (mirroring `Blueprints`):
 *
 * <pre>
 * User rep = SPersona.of('sales-rep')
 *   .profile('Standard User')
 *   .permissionSets('InvoiceReadOnly')
 *   .create();
 * </pre>
 *
 * Locale-related defaults are taken from the running user (overridable via set()).
 * This class is test-context only: create() relies on System.runAs.
 * Like SBlueprint, the builder is immutable — each method returns a new instance.
 * @directory ApexBlueprint
 */
public with sharing class SPersona {
  private static final String CLASS_NAME = 'SPersona';

  /**
   * Cache of Profile name to Id, shared across the whole test run.
   */
  private static Map<String, Id> profileIdCache = new Map<String, Id>();

  private String name;
  private String profileName;
  private List<String> permissionSetNames = new List<String>();
  private Map<String, Object> fieldValues = new Map<String, Object>();

  /**
   * Private constructor to enforce creation via the `of` factory method.
   *
   * @param name The persona name.
   */
  private SPersona(String name) {
    this.name = name;
  }

  /**
   * Creates a new SPersona. This is the entry point for defining a persona.
   *
   * @param name A short persona name (e.g. 'sales-rep'). Used for LastName and
   *             as the seed of the generated Alias / Username.
   * @return A new SPersona instance.
   */
  public static SPersona of(String name) {
    if (name == null || String.isBlank(name)) {
      ApexBlueprintException.required(CLASS_NAME, 'of(String name)', 'name', name).fire();
    }
    return new SPersona(name);
  }

  /**
   * Sets the Profile by name (resolved and cached at create()).
   *
   * @param profileName The Profile Name (e.g. 'Standard User', 'Minimum Access - Salesforce').
   * @return A new SPersona instance.
   */
  public SPersona profile(String profileName) {
    if (profileName == null || String.isBlank(profileName)) {
      ApexBlueprintException.required(CLASS_NAME, 'profile(String profileName)', 'profileName', profileName).fire();
    }
    SPersona copy = this.deepCopy();
    copy.profileName = profileName;
    return copy;
  }

  /**
   * Adds a PermissionSet (by Name) to assign to the created user.
   *
   * @param permissionSetName The PermissionSet Name (API name, not the label).
   * @return A new SPersona instance.
   */
  public SPersona permissionSets(String permissionSetName) {
    if (permissionSetName == null || String.isBlank(permissionSetName)) {
      ApexBlueprintException.required(CLASS_NAME, 'permissionSets(String permissionSetName)', 'permissionSetName', permissionSetName)
        .fire();
    }
    return this.permissionSets(new List<String>{ permissionSetName });
  }

  /**
   * Adds multiple PermissionSets (by Name) to assign to the created user.
   *
   * @param permissionSetNames The PermissionSet Names (API names).
   * @return A new SPersona instance.
   */
  public SPersona permissionSets(List<String> permissionSetNames) {
    if (permissionSetNames == null) {
      ApexBlueprintException.required(CLASS_NAME, 'permissionSets(List<String> permissionSetNames)', 'permissionSetNames', permissionSetNames)
        .fire();
    }
    SPersona copy = this.deepCopy();
    copy.permissionSetNames.addAll(permissionSetNames);
    return copy;
  }

  /**
   * Overrides an arbitrary User field (same last-wins semantics as SBlueprint.set()).
   *
   * @param fieldName The User field API name.
   * @param value The value to set.
   * @return A new SPersona instance.
   */
  public SPersona set(String fieldName, Object value) {
    if (fieldName == null || String.isBlank(fieldName)) {
      ApexBlueprintException.required(CLASS_NAME, 'set(String fieldName, Object value)', 'fieldName', fieldName).fire();
    }
    SPersona copy = this.deepCopy();
    copy.fieldValues.put(fieldName, value);
    return copy;
  }

  /**
   * Resolves the profile, builds the User with safe defaults, inserts it together
   * with its PermissionSetAssignments (wrapped in System.runAs to avoid mixed DML),
   * and returns the inserted User.
   *
   * @return The inserted User (Id populated).
   */
  public User create() {
    String method = 'create()';
    if (!Test.isRunningTest()) {
      String reason = 'SPersona can only be used in a test context (create() relies on System.runAs).';
      ApexBlueprintException.invalidOperation(CLASS_NAME, method, reason).fire();
    }

    Id profileId = this.resolveProfileId(method);
    List<Id> permissionSetIds = this.resolvePermissionSetIds(method);

    User newUser = this.buildUser(profileId, method);

    List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

    // Setup-object DML is wrapped in runAs(current user) so callers can freely mix
    // persona creation with regular-object DML in the same test transaction.
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert newUser;
      for (Id permissionSetId : permissionSetIds) {
        assignments.add(new PermissionSetAssignment(AssigneeId = newUser.Id, PermissionSetId = permissionSetId));
      }
      if (!assignments.isEmpty()) {
        insert assignments;
      }
    }
    return newUser;
  }

  // =================================================================================
  // Private Helper Methods
  // =================================================================================

  /**
   * Creates a deep copy of the SPersona instance (immutability).
   *
   * @return A new SPersona instance with the same configuration.
   */
  private SPersona deepCopy() {
    SPersona copy = new SPersona(this.name);
    copy.profileName = this.profileName;
    copy.permissionSetNames = new List<String>(this.permissionSetNames);
    copy.fieldValues = this.fieldValues.clone();
    return copy;
  }

  /**
   * Resolves the Profile Id from profile() or a direct set('ProfileId', ...) override.
   *
   * @param method The calling method (for error location).
   * @return The resolved Profile Id.
   */
  private Id resolveProfileId(String method) {
    for (String fieldName : this.fieldValues.keySet()) {
      if (fieldName.equalsIgnoreCase('ProfileId')) {
        return (Id) this.fieldValues.get(fieldName);
      }
    }
    if (this.profileName == null) {
      String reason = 'No profile specified for persona \'' + this.name + '\'.';
      String action = 'Call profile(\'<Profile Name>\') or set(\'ProfileId\', <id>) before create().';
      ApexBlueprintException.message(CLASS_NAME, method, reason, action).fire();
    }
    if (!profileIdCache.containsKey(this.profileName)) {
      List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :this.profileName LIMIT 1];
      if (profiles.isEmpty()) {
        String reason = 'Profile \'' + this.profileName + '\' was not found.';
        String action = 'Use the exact Profile Name as shown in Setup (it is locale-dependent, e.g. \'Standard User\' vs \'標準ユーザー\').';
        ApexBlueprintException.invalidArgument(CLASS_NAME, method, reason, action, 'profileName', this.profileName).fire();
      }
      profileIdCache.put(this.profileName, profiles[0].Id);
    }
    return profileIdCache.get(this.profileName);
  }

  /**
   * Resolves the PermissionSet Ids and fails fast when any name does not exist.
   *
   * @param method The calling method (for error location).
   * @return The resolved PermissionSet Ids.
   */
  private List<Id> resolvePermissionSetIds(String method) {
    List<Id> permissionSetIds = new List<Id>();
    if (this.permissionSetNames.isEmpty()) {
      return permissionSetIds;
    }

    Map<String, Id> nameToId = new Map<String, Id>();
    for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :this.permissionSetNames]) {
      nameToId.put(ps.Name, ps.Id);
    }
    List<String> missing = new List<String>();
    for (String permissionSetName : this.permissionSetNames) {
      if (nameToId.containsKey(permissionSetName)) {
        permissionSetIds.add(nameToId.get(permissionSetName));
      } else {
        missing.add(permissionSetName);
      }
    }
    if (!missing.isEmpty()) {
      String reason = 'PermissionSet(s) not found: ' + String.join(missing, ', ');
      String action = 'Use the PermissionSet API Name (Name), not the Label.';
      ApexBlueprintException.invalidArgument(CLASS_NAME, method, reason, action, 'permissionSetNames', String.join(missing, ', '))
        .fire();
    }
    return permissionSetIds;
  }

  /**
   * Builds the User record with parallel-safe unique Username, sensible defaults
   * taken from the running user, and any set() overrides applied on top.
   *
   * @param profileId The resolved Profile Id.
   * @param method The calling method (for error location).
   * @return The built (not yet inserted) User.
   */
  private User buildUser(Id profileId, String method) {
    String seed = this.name.replaceAll('[^a-zA-Z0-9]', '');
    if (String.isBlank(seed)) {
      seed = 'persona';
    }
    seed = seed.toLowerCase();
    String uniq = UUID.randomUUID().toString().replace('-', '').left(12);

    User newUser = new User(
      LastName = this.name,
      Alias = seed.left(8),
      Username = seed + '.' + uniq + '@apexblueprint.test',
      Email = seed + '@example.com',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = UserInfo.getLanguage(),
      LocaleSidKey = UserInfo.getLocale(),
      TimeZoneSidKey = UserInfo.getTimeZone().getID(),
      ProfileId = profileId
    );

    for (String fieldName : this.fieldValues.keySet()) {
      try {
        newUser.put(fieldName, this.fieldValues.get(fieldName));
      } catch (Exception e) {
        String reason = 'The field could not be applied to User.';
        String action = 'Check that \'' + fieldName + '\' exists on User and the value type matches.';
        ApexBlueprintException.invalidArgument(CLASS_NAME, method, reason, action, fieldName, this.fieldValues.get(fieldName), e)
          .fire();
      }
    }
    return newUser;
  }
}
