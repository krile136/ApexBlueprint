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

public with sharing class ApexBlueprintException extends Exception {
  private static final String LINE_1 = '====== APEX BLUEPRINT EXCEPTION ======';

  private String className;
  private String methodName;
  private String error;
  private String reason;
  private String action;
  private Map<String, Object> params = new Map<String, Object>();
  private Exception originalException;

  private static String LABEL_LOCATION = 'Location';
  private static String LABEL_ERROR = 'Error';
  private static String LABEL_REASON = 'Reason';
  private static String LABEL_ACTION = 'Action';
  private static String LABEL_PROVIDED = 'Provided';

  private static Integer PAD_SIZE = LABEL_LOCATION.length();

  // -------------- builder --------------

  public static ApexBlueprintException at(String className) {
    ApexBlueprintException e = new ApexBlueprintException();
    e.className = className;
    return e;
  }

  public ApexBlueprintException overrideClassName(String className) {
    ApexBlueprintException e = this.cloneError();
    e.className = className;
    return e;
  }

  public ApexBlueprintException method(String methodName) {
    ApexBlueprintException e = this.cloneError();
    e.methodName = methodName;
    return e;
  }

  public ApexBlueprintException error(String error) {
    ApexBlueprintException e = this.cloneError();
    e.error = error;
    return e;
  }

  public ApexBlueprintException reason(String reason) {
    ApexBlueprintException e = this.cloneError();
    e.reason = reason;
    return e;
  }

  public ApexBlueprintException action(String action) {
    ApexBlueprintException e = this.cloneError();
    e.action = action;
    return e;
  }

  public ApexBlueprintException param(String paramName, Object provided) {
    ApexBlueprintException e = this.cloneError();
    e.params.put(paramName, provided);
    return e;
  }

  public ApexBlueprintException causedBy(Exception originalException) {
    ApexBlueprintException e = this.cloneError();
    e.originalException = originalException;
    return e;
  }

  public ApexBlueprintException build() {
    List<String> lines = new List<String>{};
    lines.add('====== APEX BLUEPRINT EXCEPTION ======');
    String location = 'Location'.rightPad(PAD_SIZE) + ': ' + this.className;
    if(this.methodName != null) {
      location += '.' + this.methodName + '()';
    }
    lines.add(location);
    if (this.error != null) {
      lines.add('Error'.rightPad(PAD_SIZE) + ': ' + this.error);
    }
    if (this.reason != null) {
      lines.add('Reason'.rightPad(PAD_SIZE) + ': ' + this.reason);
    }
    if (this.action != null) {
      lines.add('Action'.rightPad(PAD_SIZE) + ': ' + this.action);
    }
    if (!this.params.isEmpty()) {
      lines.add('Provided'.rightPad(PAD_SIZE) + ': ' + this.buildProvidedValueString());
    }

    String errorMessage = mergeLines(lines);

    if (this.originalException != null) {
      return new ApexBlueprintException(errorMessage, this.originalException);
    }
    return new ApexBlueprintException(errorMessage);
  }

  public void fire() {
    throw this.build();
  }

  private ApexBlueprintException cloneError() {
    ApexBlueprintException e = new ApexBlueprintException();
    e.className = this.className;
    e.methodName = this.methodName;
    e.error = this.error;
    e.reason = this.reason;
    e.action = this.action;
    e.params = this.params.clone();
    e.originalException = this.originalException;
    return e;
  }

  // -------------- message --------------
  public static ApexBlueprintException message(String className, String methodName, String err, String action) {
    ApexBlueprintException ex = ApexBlueprintException.at(className).method(methodName).error(err).action(action);

    return ex;
  }

  public static ApexBlueprintException message(
    String className,
    String methodName,
    String err,
    String action,
    Exception e
  ) {
    ApexBlueprintException ex = ApexBlueprintException.at(className)
      .method(methodName)
      .error(err)
      .action(action)
      .causedBy(e);

    return ex;
  }

  // -------------- invalidArgument --------------

  public static ApexBlueprintException invalidArgument(
    String className,
    String methodName,
    String reason,
    String action,
    String param,
    Object provided
  ) {
    Map<String, Object> paramToProvided = new Map<String, Object>{ param => provided };
    String argPhase = createArgPhase(paramToProvided);
    ApexBlueprintException invalidArgExceptioin = ApexBlueprintException.at(className)
      .method(methodName)
      .error(argPhase)
      .reason(reason)
      .action(action);
    for (String paramName : paramToProvided.keySet()) {
      invalidArgExceptioin = invalidArgExceptioin.param(paramName, paramToProvided.get(paramName));
    }
    return invalidArgExceptioin;
  }

  public static ApexBlueprintException invalidArgument(
    String className,
    String methodName,
    String reason,
    String action,
    String param,
    Object provided,
    Exception e
  ) {
    Map<String, Object> paramToProvided = new Map<String, Object>{ param => provided };
    String argPhase = createArgPhase(paramToProvided);
    ApexBlueprintException invalidArgExceptioin = ApexBlueprintException.at(className)
      .method(methodName)
      .error(argPhase)
      .reason(reason)
      .action(action)
      .causedBy(e);
    for (String paramName : paramToProvided.keySet()) {
      invalidArgExceptioin = invalidArgExceptioin.param(paramName, paramToProvided.get(paramName));
    }
    return invalidArgExceptioin;
  }

  public static ApexBlueprintException invalidArgument(
    String className,
    String methodName,
    String reason,
    String action,
    Map<String, Object> paramToProvided
  ) {
    String argPhase = createArgPhase(paramToProvided);
    ApexBlueprintException invalidArgExceptioin = ApexBlueprintException.at(className)
      .method(methodName)
      .error(argPhase)
      .reason(reason)
      .action(action);
    for (String paramName : paramToProvided.keySet()) {
      invalidArgExceptioin = invalidArgExceptioin.param(paramName, paramToProvided.get(paramName));
    }
    return invalidArgExceptioin;
  }

  public static ApexBlueprintException invalidArgument(
    String className,
    String methodName,
    String reason,
    String action,
    Map<String, Object> paramToProvided,
    Exception e
  ) {
    String argPhase = createArgPhase(paramToProvided);
    ApexBlueprintException invalidArgExceptioin = ApexBlueprintException.at(className)
      .method(methodName)
      .error(argPhase)
      .reason(reason)
      .action(action)
      .causedBy(e);
    for (String paramName : paramToProvided.keySet()) {
      invalidArgExceptioin = invalidArgExceptioin.param(paramName, paramToProvided.get(paramName));
    }
    return invalidArgExceptioin;
  }

  private static String createArgPhase(Map<String, Object> paramToProvided) {
    if (paramToProvided.size() == 1) {
      return 'The `' + new List<String>(paramToProvided.keySet())[0] + '` argument is Invalid.';
    }
    return 'The provided arguments are Invalid.';
  }

  // -------------- invalidOperation --------------

  public static ApexBlueprintException invalidOperation(String className, String methodName, String reason) {
    string error = 'Invalid operation';
    ApexBlueprintException ex = ApexBlueprintException.at(className).method(methodName).error(error).reason(reason);

    return ex;
  }

  public static ApexBlueprintException invalidOperation(
    String className,
    String methodName,
    String reason,
    Exception e
  ) {
    string error = 'Invalid operation';
    ApexBlueprintException ex = ApexBlueprintException.at(className)
      .method(methodName)
      .error(error)
      .reason(reason)
      .causedBy(e);

    return ex;
  }

  // -------------- required --------------

  public static ApexBlueprintException required(
    String className,
    String methodName,
    String param,
    Object provided
  ) {
    String error = 'The `' + param + '` argument is required';
    String reason = 'Missing required parameter';
    ApexBlueprintException ex = ApexBlueprintException.at(className)
      .method(methodName)
      .error(error)
      .reason(reason)
      .param(param, provided);
    return ex;
  }

  public static ApexBlueprintException required(
    String className,
    String methodName,
    String param,
    Object provided,
    Exception e
  ) {
    String error = 'The `' + param + '` argument is required';
    String reason = 'Missing required parameter';
    ApexBlueprintException ex = ApexBlueprintException.at(className)
      .method(methodName)
      .error(error)
      .reason(reason)
      .param(param, provided)
      .causedBy(e);
    return ex;
  }

  // -------------- helper --------------

  private static String mergeLines(List<String> lines) {
    return '\n' + String.join(lines, '\n');
  }

  private String buildProvidedValueString() {
    List<String> providedValueStrings = new List<String>();
    for (String paramName : this.params.keySet()) {
      String providedValueString = '[' + paramName + ' => ';
      Object providedValue = this.params.get(paramName);
      if (providedValue == null) {
        providedValueString += 'null';
      } else if (providedValue instanceof String && String.isBlank((String) providedValue)) {
        providedValueString += 'empty string';
      } else {
        String valueStr = String.valueOf(providedValue);
        if (providedValue instanceof String) {
          valueStr = '\'' + valueStr + '\'';
        }
        providedValueString += valueStr;
      }
      providedValueString += ']';
      providedValueStrings.add(providedValueString);
    }

    return String.join(providedValueStrings, ', ');
  }
}
