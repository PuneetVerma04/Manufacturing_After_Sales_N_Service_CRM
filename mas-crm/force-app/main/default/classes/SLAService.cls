@SuppressWarnings('PMD.ApexDoc')
@SupperssWarnings('PMD.ApexCRUDViolation')

public with sharing class SLAService {

    @AuraEnabled(cacheable=true)
    public static List<Service_Case__c> findBreachedCases() {
        // NOTE: Including 'Resolved' status in the terminal statuses for accuracy
        Set<String> terminalStatuses = new Set<String>{'Closed', 'Resolved'}; 
        return [
            SELECT Id, Name, Subject__c, Priority__c, SLA_Deadline__c,
                   Engineer_Assigned__r.Name,
                   Registered_Product__r.Name
            FROM Service_Case__c
            WHERE Status__c NOT IN :terminalStatuses
              AND SLA_Deadline__c != null
              AND SLA_Deadline__c < :System.now()
            ORDER BY SLA_Deadline__c ASC
            LIMIT 200
        ];
    }

    public static void notifySLABreaches() {
        List<Service_Case__c> breachedCases = findBreachedCases();
        if (breachedCases.isEmpty()) return;

        // 1. Find the SLA Escalation Queue
        List<Group> queues = [SELECT Id FROM Group WHERE Name = 'SLAEscalationQueue' LIMIT 1];
        if (queues.isEmpty()) return;
        Id slaQueueId = queues[0].Id;

        // 2. BULKIFIED Resolution of all members (Users, Roles, Groups)
        // We query the GroupMember object to find all IDs related to the queue.
        List<GroupMember> members = [
            SELECT UserOrGroupId, Group.Type 
            FROM GroupMember 
            WHERE GroupId = :slaQueueId
        ];
        
        Set<Id> directUserIds = new Set<Id>();
        Set<Id> roleIds = new Set<Id>();

        for (GroupMember gm : members) {
            if (gm.Group.Type == 'Role' || gm.Group.Type == 'RoleAndSubordinates') {
                // If the member is a Role, collect the Role ID to query users later
                roleIds.add(gm.UserOrGroupId);
            } else {
                // Assume all other non-Role members are direct Users or other Groups 
                // The final User query will filter out non-User IDs
                directUserIds.add(gm.UserOrGroupId);
            }
        }

        // 3. BULKIFIED Resolution of Users from Roles
        // Query users based on the collected Role IDs.
        if (!roleIds.isEmpty()) {
            // Note: If the role in the queue is 'RoleAndSubordinates', this query will NOT automatically
            // include subordinates. You would need to use a more complex logic involving the UserRole hierarchy
            // for full recursion, but this handles the direct role assignment.
            for (User u : [SELECT Id FROM User WHERE UserRoleId IN :roleIds]) {
                directUserIds.add(u.Id);
            }
        }

        if (directUserIds.isEmpty()) return;

        // 4. Final BULKIFIED Query for all Managers
        // This query implicitly filters out any non-User IDs (like nested Group IDs)
        List<User> managers = [
            SELECT Id, Name, Email
            FROM User
            WHERE Id IN :directUserIds 
            AND Email != null
        ];

        if (managers.isEmpty()) return;

        // 5. Send Emails
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (User mgr : managers) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { mgr.Email });
            email.setSubject('SLA Breach Alert – ' + breachedCases.size() + ' case(s)');
            email.setHtmlBody(buildEmailBody(breachedCases));
            email.setSaveAsActivity(false);
            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    private static String buildEmailBody(List<Service_Case__c> cases) {
        String body = '<h2>The following Service Cases have breached SLA:</h2><ul>';
        for (Service_Case__c sc : cases) {
            body += '<li><b>' + escapeHtml(sc.Subject__c) + '</b> (Case ' + escapeHtml(sc.Name) + ')'
                 + ' – Priority: ' + escapeHtml(sc.Priority__c)
                 + ' – Product: ' + (sc.Registered_Product__r != null ? escapeHtml(sc.Registered_Product__r.Name) : '')
                 + ' – Engineer: ' + (sc.Engineer_Assigned__r != null ? escapeHtml(sc.Engineer_Assigned__r.Name) : '')
                 + ' – Deadline: ' + sc.SLA_Deadline__c.format() + '</li>';
        }
        body += '</ul><p>Please log in to Salesforce for details and escalation handling.</p>';
        return body;
    }

    private static String escapeHtml(String input) {
        if (input == null) return '';
        String out = input.replace('&', '&amp;');
        out = out.replace('<', '&lt;');
        out = out.replace('>', '&gt;');
        return out;
    }
}