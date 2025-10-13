/**
 * @description Service class for managing service case status transitions using Custom Metadata Types.
 * Provides centralized validation and management of allowed status changes.
 * @author Manufacturing CRM Team
 * @since API Version 64.0
 */
public with sharing class CaseStatusTransitionService {
    
    /**
     * @description Cache for status transitions to improve performance
     */
    private static Map<String, Set<String>> transitionCache;
    
    /**
     * @description Validates if a status transition is allowed based on Custom Metadata configuration.
     * @param fromStatus The current status of the case
     * @param toStatus The desired new status for the case
     * @return Boolean True if transition is allowed, false otherwise
     * @example
     * Boolean isValid = CaseStatusTransitionService.isValidTransition('Engineer Dispatched', 'In Progress');
     */
    public static Boolean isValidTransition(String fromStatus, String toStatus) {
        if (String.isBlank(fromStatus) || String.isBlank(toStatus)) {
            return false;
        }
        
        Map<String, Set<String>> transitions = getValidTransitions();
        Set<String> allowedToStatuses = transitions.get(fromStatus);
        
        return allowedToStatuses != null && allowedToStatuses.contains(toStatus);
    }
    
    /**
     * @description Gets all valid next statuses for a given current status.
     * @param currentStatus The current status to get valid transitions for
     * @return Set<String> Set of valid next statuses, empty set if none found
     * @example
     * Set<String> nextStatuses = CaseStatusTransitionService.getValidNextStatuses('Engineer Dispatched');
     */
    public static Set<String> getValidNextStatuses(String currentStatus) {
        if (String.isBlank(currentStatus)) {
            return new Set<String>();
        }
        
        Map<String, Set<String>> transitions = getValidTransitions();
        Set<String> nextStatuses = transitions.get(currentStatus);
        
        return nextStatuses != null ? nextStatuses.clone() : new Set<String>();
    }
    
    /**
     * @description Gets all configured status transitions from Custom Metadata.
     * Uses caching to improve performance on subsequent calls.
     * @return Map<String, Set<String>> Map of from status to set of allowed to statuses
     */
    public static Map<String, Set<String>> getValidTransitions() {
        if (transitionCache == null) {
            loadTransitionsFromMetadata();
        }
        return transitionCache;
    }
    
    /**
     * @description Loads status transitions from Custom Metadata Type into cache.
     * Called automatically when cache is empty or can be called to refresh cache.
     */
    public static void loadTransitionsFromMetadata() {
        transitionCache = new Map<String, Set<String>>();
        
        List<Case_Status_Transition__mdt> transitions = [
            SELECT From_Status__c, To_Status__c, Is_Active__c, Description__c
            FROM Case_Status_Transition__mdt
            WHERE Is_Active__c = true
        ];
        
        for (Case_Status_Transition__mdt transition : transitions) {
            String fromStatus = transition.From_Status__c;
            String toStatus = transition.To_Status__c;
            
            if (!transitionCache.containsKey(fromStatus)) {
                transitionCache.put(fromStatus, new Set<String>());
            }
            transitionCache.get(fromStatus).add(toStatus);
        }
    }
    
    /**
     * @description Clears the transition cache to force reload from metadata.
     * Useful for testing or when metadata changes need to be picked up immediately.
     * @example
     * CaseStatusTransitionService.clearCache(); // Forces reload on next access
     */
    @TestVisible
    public static void clearCache() {
        transitionCache = null;
    }
    
    /**
     * @description Gets a user-friendly error message for invalid transitions.
     * @param fromStatus The current status attempting to transition from
     * @param toStatus The desired status attempting to transition to
     * @return String Descriptive error message explaining why transition is invalid
     * @example
     * String error = CaseStatusTransitionService.getTransitionErrorMessage('New', 'Closed');
     */
    public static String getTransitionErrorMessage(String fromStatus, String toStatus) {
        if (String.isBlank(fromStatus) || String.isBlank(toStatus)) {
            return 'Status values cannot be empty.';
        }
        
        Set<String> validNextStatuses = getValidNextStatuses(fromStatus);
        
        if (validNextStatuses.isEmpty()) {
            return 'No valid transitions are configured for status: ' + fromStatus;
        }
        
        String validOptions = String.join(new List<String>(validNextStatuses), ', ');
        return 'Invalid status transition from "' + fromStatus + '" to "' + toStatus + 
               '". Valid options are: ' + validOptions;
    }
    
    /**
     * @description Gets all configured status transitions with their descriptions.
     * Useful for administrative interfaces or debugging.
     * @return List<TransitionInfo> List of transition information objects
     */
    public static List<TransitionInfo> getAllTransitions() {
        List<TransitionInfo> transitionInfos = new List<TransitionInfo>();
        
        List<Case_Status_Transition__mdt> transitions = [
            SELECT From_Status__c, To_Status__c, Is_Active__c, Description__c, DeveloperName
            FROM Case_Status_Transition__mdt
            ORDER BY From_Status__c, To_Status__c
        ];
        
        for (Case_Status_Transition__mdt transition : transitions) {
            TransitionInfo info = new TransitionInfo();
            info.fromStatus = transition.From_Status__c;
            info.toStatus = transition.To_Status__c;
            info.isActive = transition.Is_Active__c;
            info.description = transition.Description__c;
            info.developerName = transition.DeveloperName;
            transitionInfos.add(info);
        }
        
        return transitionInfos;
    }
    
    /**
     * @description Wrapper class for transition information.
     */
    public class TransitionInfo {
        @AuraEnabled public String fromStatus;
        @AuraEnabled public String toStatus;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String description;
        @AuraEnabled public String developerName;
    }
}