@SuppressWarnings('PMD.ApexDoc')
public with sharing class EngineerDashboardController {

    // -----------------------------
    // Read-only methods (cacheable)
    // -----------------------------
    @AuraEnabled(cacheable=true)
    public static Engineer__c getEngineerInfo() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<Engineer__c> engineers = [
            SELECT Id, Name, Engineer_Email__c, Available__c, Skills__c, Location__c
            FROM Engineer__c
            WHERE Id IN (
                SELECT Engineer_Assigned__c 
                FROM Service_Case__c 
                WHERE Engineer_Assigned__c != null
            )
            LIMIT 1
        ];
        return engineers.isEmpty() ? null : engineers[0];
    }

    @AuraEnabled(cacheable=true)
    public static List<Service_Case__c> getAssignedJobs() {
        Engineer__c engineer = getEngineerInfo();
        if (engineer == null) return new List<Service_Case__c>();

        return [
            SELECT Id, Name, Subject__c, Status__c, Priority__c, SLA_Deadline__c,
                   Registered_Product__c, Customer_Name__c, Customer_Email__c,
                   CreatedDate, LastModifiedDate
            FROM Service_Case__c
            WHERE Engineer_Assigned__c = :engineer.Id
            AND Status__c != 'Closed'
            ORDER BY SLA_Deadline__c ASC NULLS LAST
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Dispatch__c> getDispatchJobs() {
        Engineer__c engineer = getEngineerInfo();
        if (engineer == null) return new List<Dispatch__c>();

        return [
            SELECT Id, Name, Service_Date__c,
                   Service_Case__c, Service_Case__r.Name, Service_Case__r.Subject__c
            FROM Dispatch__c
            WHERE Engineer_Assigned__c = :engineer.Id
            ORDER BY Service_Date__c DESC
        ];
    }

    // -----------------------------
    // DML method (non-cacheable)
    // -----------------------------
    @AuraEnabled
    public static String updateJobStatus(String caseId, String newStatus, String comments) {
        try {
            Service_Case__c caseToUpdate = [
                SELECT Id, Status__c, Engineer_Feedback__c
                FROM Service_Case__c
                WHERE Id = :caseId
                LIMIT 1
            ];

            Map<String, String> validTransitions = new Map<String, String>{
                'Engineer Dispatched' => 'In Progress',
                'In Progress' => 'Resolved'
            };

            String currentStatus = caseToUpdate.Status__c;

            if (!validTransitions.containsKey(currentStatus) ||
                validTransitions.get(currentStatus) != newStatus) {
                throw new AuraHandledException(
                    'Invalid status change. Allowed flow: Engineer Dispatched → In Progress → Resolved.'
                );
            }

            caseToUpdate.Status__c = newStatus;

            if (String.isNotBlank(comments)) {
                if (String.isBlank(caseToUpdate.Engineer_Feedback__c)) {
                    caseToUpdate.Engineer_Feedback__c = comments;
                } else {
                    caseToUpdate.Engineer_Feedback__c += '\n---\n' + comments;
                }
            }

            update caseToUpdate; // Single DML, allowed now

            return 'Case status updated to ' + newStatus;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating job status: ' + e.getMessage());
        }
    }
}