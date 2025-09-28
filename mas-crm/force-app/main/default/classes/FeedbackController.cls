public with sharing class FeedbackController {
    @AuraEnabled(cacheable=true)
    public static List<Service_Case__c> getAvailableCases() {
        // Get cases that are resolved or closed and don't have feedback yet
        return [
            SELECT Id, Name, Subject__c, Status__c, Priority__c, 
                   Engineer_Assigned__r.Name, CreatedDate
            FROM Service_Case__c
            WHERE Status__c IN ('Resolved', 'Closed')
            AND Id NOT IN (
                SELECT Service_Case__c 
                FROM Feedback__c 
                WHERE Service_Case__c != null
            )
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }

    @AuraEnabled
    public static String submitFeedbackRecord(String caseId, Integer rating, String comments) {
        try {
            // Validate inputs
            if (String.isBlank(caseId)) {
                throw new AuraHandledException('Case ID is required');
            }
            
            if (rating == null || rating < 1 || rating > 5) {
                throw new AuraHandledException('Rating must be between 1 and 5');
            }

            // Check if feedback already exists for this case
            List<Feedback__c> existingFeedback = [
                SELECT Id FROM Feedback__c 
                WHERE Service_Case__c = :caseId 
                LIMIT 1
            ];
            
            if (!existingFeedback.isEmpty()) {
                throw new AuraHandledException('Feedback already exists for this case');
            }

            // Verify the case exists and is in the right status
            List<Service_Case__c> cases = [
                SELECT Id, Status__c 
                FROM Service_Case__c 
                WHERE Id = :caseId 
                AND Status__c IN ('Resolved', 'Closed')
                LIMIT 1
            ];
            
            if (cases.isEmpty()) {
                throw new AuraHandledException('Case not found or not in a feedback-eligible status');
            }

            // Create feedback record
            Feedback__c feedback = new Feedback__c();
            feedback.Service_Case__c = caseId;
            feedback.Rating__c = rating;
            feedback.Comments__c = comments;
            
            insert feedback;
            
            return feedback.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting feedback: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String validateAndCreateFeedback(String serviceCaseId, String customerName, String customerEmail, Integer rating, String comments) {
        List<Service_Case__c> cases = [
            SELECT Id FROM Service_Case__c
            WHERE Id = :serviceCaseId
            AND Customer_Name__c = :customerName
            AND Customer_Email__c = :customerEmail
            LIMIT 1
        ];
        if (cases.isEmpty()) {
            throw new AuraHandledException('No matching Service Case found for the provided details.');
        }
        Feedback__c fb = new Feedback__c(
            Service_Case__c = cases[0].Id,
            Rating__c = rating,
            Comments__c = comments
        );
        insert fb;
        return fb.Id;
    }
}
