/**
 * @description Centralized error logging service for the Manufacturing CRM application.
 * Provides methods to log errors with different severity levels and contexts.
 * @author Manufacturing CRM Team
 * @since API Version 64.0
 */
public with sharing class ErrorLogService {
    
    /**
     * @description Enum for error severity levels
     */
    public enum Severity {
        CRITICAL, HIGH, MEDIUM, LOW, INFO
    }
    
    /**
     * @description Enum for error types
     */
    public enum ErrorType {
        ERROR_EXCEPTION, DML_ERROR, SOQL_ERROR, VALIDATION_ERROR, 
        INTEGRATION_ERROR, BUSINESS_LOGIC_ERROR, SYSTEM_ERROR
    }
    
    /**
     * @description Logs an exception with full context information.
     * @param ex The exception to log
     * @param className The class where the exception occurred
     * @param methodName The method where the exception occurred
     * @param severity The severity level of the error
     * @param recordContext Optional record ID for context
     * @example
     * try {
     *     // Some operation
     * } catch (Exception ex) {
     *     ErrorLogService.logException(ex, 'MyClass', 'myMethod', ErrorLogService.Severity.HIGH, recordId);
     * }
     */
    public static void logException(Exception ex, String className, String methodName, 
                                   Severity severity, String recordContext) {
        try {
            Error_Log__c errorLog = new Error_Log__c(
                Error_Message__c = ex.getMessage(),
                Error_Type__c = getErrorTypeFromException(ex),
                Severity__c = severity.name(),
                Class_Name__c = className,
                Method_Name__c = methodName,
                Stack_Trace__c = ex.getStackTraceString(),
                User_Context__c = UserInfo.getUserId(),
                Record_Context__c = recordContext
            );
            
            insert errorLog;
        } catch (Exception logEx) {
            // Silent fail to prevent infinite loops
            System.debug(LoggingLevel.ERROR, 'Failed to log error: ' + logEx.getMessage());
        }
    }
    
    /**
     * @description Logs an exception with default severity (HIGH).
     * @param ex The exception to log
     * @param className The class where the exception occurred
     * @param methodName The method where the exception occurred
     * @param recordContext Optional record ID for context
     */
    public static void logException(Exception ex, String className, String methodName, String recordContext) {
        logException(ex, className, methodName, Severity.HIGH, recordContext);
    }
    
    /**
     * @description Logs an exception with minimal context.
     * @param ex The exception to log
     * @param className The class where the exception occurred
     * @param methodName The method where the exception occurred
     */
    public static void logException(Exception ex, String className, String methodName) {
        logException(ex, className, methodName, Severity.HIGH, null);
    }
    
    /**
     * @description Logs a custom error message with specified details.
     * @param message The error message to log
     * @param errorType The type of error
     * @param severity The severity level of the error
     * @param className The class where the error occurred
     * @param methodName The method where the error occurred
     * @param recordContext Optional record ID for context
     * @example
     * ErrorLogService.logError('Invalid status transition', ErrorLogService.ErrorType.BUSINESS_LOGIC_ERROR, 
     *                         ErrorLogService.Severity.MEDIUM, 'CaseController', 'updateStatus', caseId);
     */
    public static void logError(String message, ErrorType errorType, Severity severity, 
                               String className, String methodName, String recordContext) {
        try {
            Error_Log__c errorLog = new Error_Log__c(
                Error_Message__c = message,
                Error_Type__c = errorType.name().replace('_', ' '),
                Severity__c = severity.name(),
                Class_Name__c = className,
                Method_Name__c = methodName,
                User_Context__c = UserInfo.getUserId(),
                Record_Context__c = recordContext
            );
            
            insert errorLog;
        } catch (Exception logEx) {
            // Silent fail to prevent infinite loops
            System.debug(LoggingLevel.ERROR, 'Failed to log error: ' + logEx.getMessage());
        }
    }
    
    /**
     * @description Logs an informational message.
     * @param message The message to log
     * @param className The class where the log occurred
     * @param methodName The method where the log occurred
     * @param recordContext Optional record ID for context
     */
    public static void logInfo(String message, String className, String methodName, String recordContext) {
        logError(message, ErrorType.SYSTEM_ERROR, Severity.INFO, className, methodName, recordContext);
    }
    
    /**
     * @description Logs multiple exceptions in a bulk operation for better performance.
     * @param exceptions List of exception contexts to log
     * @example
     * List<ErrorLogService.ExceptionContext> exceptions = new List<ErrorLogService.ExceptionContext>();
     * exceptions.add(new ErrorLogService.ExceptionContext(ex, 'Class1', 'method1', ErrorLogService.Severity.HIGH));
     * ErrorLogService.logExceptionsBulk(exceptions);
     */
    public static void logExceptionsBulk(List<ExceptionContext> exceptions) {
        if (exceptions == null || exceptions.isEmpty()) {
            return;
        }
        
        try {
            List<Error_Log__c> errorLogs = new List<Error_Log__c>();
            
            for (ExceptionContext ctx : exceptions) {
                Error_Log__c errorLog = new Error_Log__c(
                    Error_Message__c = ctx.errorException.getMessage(),
                    Error_Type__c = getErrorTypeFromException(ctx.errorException),
                    Severity__c = ctx.severity.name(),
                    Class_Name__c = ctx.className,
                    Method_Name__c = ctx.methodName,
                    Stack_Trace__c = ctx.errorException.getStackTraceString(),
                    User_Context__c = UserInfo.getUserId(),
                    Record_Context__c = ctx.recordContext
                );
                errorLogs.add(errorLog);
            }
            
            insert errorLogs;
        } catch (Exception logEx) {
            // Silent fail to prevent infinite loops
            System.debug(LoggingLevel.ERROR, 'Failed to log bulk errors: ' + logEx.getMessage());
        }
    }
    
    /**
     * @description Retrieves error logs with filtering options.
     * @param severity Filter by severity level (optional)
     * @param errorType Filter by error type (optional)
     * @param className Filter by class name (optional)
     * @param limitCount Number of records to return (default 100, max 200)
     * @return List<Error_Log__c> List of error logs matching criteria
     */
    @AuraEnabled(cacheable=true)
    public static List<Error_Log__c> getErrorLogs(String severity, String errorType, 
                                                  String className, Integer limitCount) {
        if (limitCount == null || limitCount <= 0 || limitCount > 200) {
            limitCount = 100;
        }
        
        String query = 'SELECT Id, Name, Error_Message__c, Error_Type__c, Severity__c, ' +
                      'Class_Name__c, Method_Name__c, User_Context__r.Name, Record_Context__c, ' +
                      'CreatedDate FROM Error_Log__c WHERE Id != null';
        
        List<String> conditions = new List<String>();
        
        if (String.isNotBlank(severity)) {
            conditions.add('Severity__c = :severity');
        }
        if (String.isNotBlank(errorType)) {
            conditions.add('Error_Type__c = :errorType');
        }
        if (String.isNotBlank(className)) {
            conditions.add('Class_Name__c LIKE \'%' + String.escapeSingleQuotes(className) + '%\'');
        }
        
        if (!conditions.isEmpty()) {
            query += ' AND ' + String.join(conditions, ' AND ');
        }
        
        query += ' ORDER BY CreatedDate DESC LIMIT ' + limitCount;
        
        return Database.query(query);
    }
    
    /**
     * @description Gets error statistics for dashboard display.
     * @return ErrorStats Statistics about error logs
     */
    @AuraEnabled(cacheable=true)
    public static ErrorStats getErrorStatistics() {
        ErrorStats stats = new ErrorStats();
        
        // Total errors in last 30 days
        stats.totalErrors = [SELECT COUNT() FROM Error_Log__c 
                            WHERE CreatedDate >= :Date.today().addDays(-30)];
        
        // Critical errors in last 30 days
        stats.criticalErrors = [SELECT COUNT() FROM Error_Log__c 
                               WHERE Severity__c = 'Critical' 
                               AND CreatedDate >= :Date.today().addDays(-30)];
        
        // Errors by severity
        List<AggregateResult> severityResults = [
            SELECT Severity__c, COUNT(Id) cnt
            FROM Error_Log__c
            WHERE CreatedDate >= :Date.today().addDays(-30)
            GROUP BY Severity__c
        ];
        
        stats.errorsBySeverity = new Map<String, Integer>();
        for (AggregateResult ar : severityResults) {
            stats.errorsBySeverity.put((String)ar.get('Severity__c'), (Integer)ar.get('cnt'));
        }
        
        // Top error classes
        List<AggregateResult> classResults = [
            SELECT Class_Name__c, COUNT(Id) cnt
            FROM Error_Log__c
            WHERE CreatedDate >= :Date.today().addDays(-30)
            AND Class_Name__c != null
            GROUP BY Class_Name__c
            ORDER BY COUNT(Id) DESC
            LIMIT 5
        ];
        
        stats.topErrorClasses = new Map<String, Integer>();
        for (AggregateResult ar : classResults) {
            stats.topErrorClasses.put((String)ar.get('Class_Name__c'), (Integer)ar.get('cnt'));
        }
        
        return stats;
    }
    
    /**
     * @description Determines error type from exception class name.
     * @param ex The exception to analyze
     * @return String The error type as string
     */
    private static String getErrorTypeFromException(Exception ex) {
        String exceptionType = ex.getTypeName();
        
        if (exceptionType.contains('DmlException')) {
            return 'DML Error';
        } else if (exceptionType.contains('QueryException')) {
            return 'SOQL Error';
        } else if (exceptionType.contains('ValidationException')) {
            return 'Validation Error';
        } else if (exceptionType.contains('CalloutException') || exceptionType.contains('Integration')) {
            return 'Integration Error';
        } else {
            return 'Exception';
        }
    }
    
    /**
     * @description Wrapper class for exception context in bulk operations.
     */
    public class ExceptionContext {
        public Exception errorException;
        public String className;
        public String methodName;
        public Severity severity;
        public String recordContext;
        
        public ExceptionContext(Exception ex, String cls, String method, Severity sev) {
            this.errorException = ex;
            this.className = cls;
            this.methodName = method;
            this.severity = sev;
            this.recordContext = null;
        }
        
        public ExceptionContext(Exception ex, String cls, String method, Severity sev, String context) {
            this.errorException = ex;
            this.className = cls;
            this.methodName = method;
            this.severity = sev;
            this.recordContext = context;
        }
    }
    
    /**
     * @description Wrapper class for error statistics.
     */
    public class ErrorStats {
        @AuraEnabled public Integer totalErrors = 0;
        @AuraEnabled public Integer criticalErrors = 0;
        @AuraEnabled public Map<String, Integer> errorsBySeverity = new Map<String, Integer>();
        @AuraEnabled public Map<String, Integer> topErrorClasses = new Map<String, Integer>();
    }
}
