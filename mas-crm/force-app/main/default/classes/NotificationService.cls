@SuppressWarnings('PMD.ApexDoc')
@SupperssWarnings('PMD.ApexCRUDViolation')

/**
 * Service class for handling notification sending functionality.
 * This class provides methods to send email notifications to engineers assigned to service cases and dispatches.
 */
public with sharing class NotificationService {
    /**
     * Sends an email to the Engineer assigned on Service_Case__c.
     * Uses Engineer__c.Engineer_Email__c as the recipient address.
     */
    public static void sendEngineerNotificationForCase(Set<Id> serviceCaseIds) {
        if (serviceCaseIds == null || serviceCaseIds.isEmpty()) {
            return;
        }

        List<Service_Case__c> cases = [
            SELECT Id,
                   Name,
                   Subject__c,
                   Status__c,
                   Priority__c,
                   Registered_Product__c,
                   Engineer_Assigned__c,
                   Registered_Product__r.Name,
                   Engineer_Assigned__r.Name,
                   Engineer_Assigned__r.Engineer_Email__c
            FROM Service_Case__c
            WHERE Id IN :serviceCaseIds
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Service_Case__c sc : cases) {
            String toAddress = (sc.Engineer_Assigned__r == null) ? null : sc.Engineer_Assigned__r.Engineer_Email__c;
            if (String.isBlank(toAddress)) {
                continue;
            }

            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setToAddresses(new String[] { toAddress });
            msg.setSaveAsActivity(true);

            String subject = 'New Service Case Assigned: ' + (sc.Subject__c == null ? sc.Name : sc.Subject__c);
            msg.setSubject(subject);

            String body = buildCaseEmailBody(sc);
            msg.setHtmlBody(body);

            emails.add(msg);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    /**
     * Sends an email to the Engineer assigned on Dispatch__c records.
     */
    public static void sendEngineerNotificationForDispatch(Set<Id> dispatchIds) {
        if (dispatchIds == null || dispatchIds.isEmpty()) {
            return;
        }

        List<Dispatch__c> jobs = [
            SELECT Id,
                   Name,
                   Engineer_Assigned__c,
                   Engineer_Assigned__r.Name,
                   Engineer_Assigned__r.Engineer_Email__c,
                   Service_Case__c,
                   Service_Case__r.Subject__c,
                   Service_Case__r.Name
            FROM Dispatch__c
            WHERE Id IN :dispatchIds
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Dispatch__c d : jobs) {
            String toAddress = (d.Engineer_Assigned__r == null) ? null : d.Engineer_Assigned__r.Engineer_Email__c;
            if (String.isBlank(toAddress)) {
                continue;
            }

            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setToAddresses(new String[] { toAddress });
            msg.setSaveAsActivity(true);

            String subject = 'Dispatch Assigned: ' + d.Name;
            msg.setSubject(subject);

            String body = buildDispatchEmailBody(d);
            msg.setHtmlBody(body);

            emails.add(msg);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    private static String buildCaseEmailBody(Service_Case__c sc) {
        String productName = (sc.Registered_Product__r == null) ? '' : sc.Registered_Product__r.Name;
        String caseSubject = String.isBlank(sc.Subject__c) ? 'N/A' : sc.Subject__c;
        String caseStatus = String.isBlank(sc.Status__c) ? 'N/A' : sc.Status__c;
        String casePriority = String.isBlank(sc.Priority__c) ? 'N/A' : sc.Priority__c;

        String body =
        '<div style="font-family: Arial, sans-serif; color: #333;">' +
            '<h2 style="color: #2E86C1;">Hello ' + ((sc.Engineer_Assigned__r == null) ? 'Engineer' : sc.Engineer_Assigned__r.Name) + ',</h2>' +
            '<p>You have been assigned a new <strong>Service Case</strong>. Please review the details below:</p>' +
            '<table style="width:100%; border-collapse: collapse;">' +
                '<tr style="background-color: #D6EAF8;"><th style="padding:10px; text-align:left;">Field</th><th style="padding:10px; text-align:left;">Details</th></tr>' +
                '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Case Name</td><td style="padding:8px;">' + escapeHtml(sc.Name) + '</td></tr>' +
                '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Subject</td><td style="padding:8px;">' + escapeHtml(caseSubject) + '</td></tr>' +
                '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Status</td><td style="padding:8px;">' + escapeHtml(caseStatus) + '</td></tr>' +
                '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Priority</td><td style="padding:8px;">' + escapeHtml(casePriority) + '</td></tr>' +
                '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Product</td><td style="padding:8px;">' + escapeHtml(productName) + '</td></tr>' +
            '</table>' +
            '<p style="margin-top:20px;">Please log in to Salesforce to view full details and take necessary action.</p>' +
        '   <p style="font-size:12px; color:#888;">This is an automated email. Do not reply.</p>' +
        '</div>';

        return body;
    }


    private static String buildDispatchEmailBody(Dispatch__c d) {
        String caseDisplay = (d.Service_Case__r == null) ? 'N/A' :
                         (String.isBlank(d.Service_Case__r.Subject__c) ? d.Service_Case__r.Name : d.Service_Case__r.Subject__c);

        String body =
        '<div style="font-family: Arial, sans-serif; color: #333;">' +
            '<h2 style="color: #28B463;">Hello ' + ((d.Engineer_Assigned__r == null) ? 'Engineer' : d.Engineer_Assigned__r.Name) + ',</h2>' +
            '<p>You have a new <strong>Dispatch Assignment</strong>. Please review the details below:</p>' +
            '<table style="width:100%; border-collapse: collapse;">' +
                '<tr style="background-color: #D1F2EB;"><th style="padding:10px; text-align:left;">Field</th><th style="padding:10px; text-align:left;">Details</th></tr>' +
                '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Dispatch Name</td><td style="padding:8px;">' + escapeHtml(d.Name) + '</td></tr>' +
                '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Related Case</td><td style="padding:8px;">' + escapeHtml(caseDisplay) + '</td></tr>' +
            '</table>' +
            '<p style="margin-top:20px;">Please log in to Salesforce to view full details and update the dispatch status.</p>' +
            '<p style="font-size:12px; color:#888;">This is an automated email. Do not reply.</p>' +
        '</div>';

        return body;
    }

    public static void sendAgentNotificationForCase(Set<Id> serviceCaseIds) {
        if (serviceCaseIds == null || serviceCaseIds.isEmpty()) return;

        List<Service_Case__c> cases = [
            SELECT Id, Name, Subject__c, Status__c, Priority__c, Registered_Product__c,
                   Assigned_Agent__c, Assigned_Agent__r.Name, Assigned_Agent__r.Email_ID__c,
                   Registered_Product__r.Name
            FROM Service_Case__c
            WHERE Id IN :serviceCaseIds
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Service_Case__c sc : cases) {
            String toAddress = (sc.Assigned_Agent__r == null) ? null : sc.Assigned_Agent__r.Email_ID__c;
            if (String.isBlank(toAddress)) continue;

            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setToAddresses(new String[] { toAddress });
            msg.setSaveAsActivity(true);

            msg.setSubject('New Service Case Assigned: ' + (sc.Subject__c == null ? sc.Name : sc.Subject__c));
            msg.setHtmlBody(buildAgentCaseEmailBody(sc));

            emails.add(msg);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    /**
     * Sends email to Service Agent assigned on Dispatches
     */
    public static void sendAgentNotificationForDispatch(Set<Id> dispatchIds) {
        if (dispatchIds == null || dispatchIds.isEmpty()) return;

        List<Dispatch__c> jobs = [
            SELECT Id, Name, Service_Case__c, Service_Case__r.Subject__c, 
                   Agent_Dispatched__c, Agent_Dispatched__r.Name, Agent_Dispatched__r.Email_ID__c
            FROM Dispatch__c
            WHERE Id IN :dispatchIds
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Dispatch__c d : jobs) {
            String toAddress = (d.Agent_Dispatched__r == null) ? null : d.Agent_Dispatched__r.Email_ID__c;
            if (String.isBlank(toAddress)) continue;

            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setToAddresses(new String[] { toAddress });
            msg.setSaveAsActivity(true);

            msg.setSubject('New Dispatch Assigned: ' + d.Name);
            msg.setHtmlBody(buildAgentDispatchEmailBody(d));

            emails.add(msg);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    // --- Email body builders ---
    private static String buildAgentCaseEmailBody(Service_Case__c sc) {
        String productName = (sc.Registered_Product__r == null) ? '' : sc.Registered_Product__r.Name;
        String caseSubject = String.isBlank(sc.Subject__c) ? 'N/A' : sc.Subject__c;
        String caseStatus = String.isBlank(sc.Status__c) ? 'N/A' : sc.Status__c;
        String casePriority = String.isBlank(sc.Priority__c) ? 'N/A' : sc.Priority__c;

        String body = 
        '<div style="font-family: Arial, sans-serif; color: #333;">' +
            '<h2 style="color: #2E86C1;">Hello ' + ((sc.Assigned_Agent__r == null) ? 'Agent' : sc.Assigned_Agent__r.Name) + ',</h2>' +
            '<p>You have a new <strong>Service Case</strong> assigned. Please review the details below:</p>' +
            '<table style="width:100%; border-collapse: collapse;">' +
                '<tr style="background-color: #D6EAF8;"><th style="padding:10px; text-align:left;">Field</th><th style="padding:10px; text-align:left;">Details</th></tr>' +
                '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Case Name</td><td style="padding:8px;">' + escapeHtml(sc.Name) + '</td></tr>' +
                '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Subject</td><td style="padding:8px;">' + escapeHtml(caseSubject) + '</td></tr>' +
                '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Status</td><td style="padding:8px;">' + escapeHtml(caseStatus) + '</td></tr>' +
                '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Priority</td><td style="padding:8px;">' + escapeHtml(casePriority) + '</td></tr>' +
                '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Product</td><td style="padding:8px;">' + escapeHtml(productName) + '</td></tr>' +
            '</table>' +
            '<p style="margin-top:20px;">Please log in to Salesforce to view the full details and take necessary action.</p>' +
        '   <p style="font-size:12px; color:#888;">This is an automated email. Do not reply.</p>' +
        '</div>';
        return body;
    }


    private static String buildAgentDispatchEmailBody(Dispatch__c d) {
        String caseDisplay = (d.Service_Case__r == null) ? 'N/A' : 
                            (String.isBlank(d.Service_Case__r.Subject__c) ? d.Service_Case__r.Name : d.Service_Case__r.Subject__c);

        String body =
        '<div style="font-family: Arial, sans-serif; color: #333;">' +
            '<h2 style="color: #28B463;">Hello ' + ((d.Agent_Dispatched__r == null) ? 'Agent' : d.Agent_Dispatched__r.Name) + ',</h2>' +
            '<p>This is mail regarding the <strong>Dispatch Assignment</strong>. Please review the details below:</p>' +
            '<table style="width:100%; border-collapse: collapse;">' +
                '<tr style="background-color: #D1F2EB;"><th style="padding:10px; text-align:left;">Field</th><th style="padding:10px; text-align:left;">Details</th></tr>' +
            '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Dispatch Name</td><td style="padding:8px;">' + escapeHtml(d.Name) + '</td></tr>' +
            '<tr style="border-bottom:1px solid #ccc;"><td style="padding:8px;">Related Case</td><td style="padding:8px;">' + escapeHtml(caseDisplay) + '</td></tr>' +
        '</table>' +
        '<p style="margin-top:20px;">Please log in to Salesforce to view the full details.</p>' +
        '<p style="font-size:12px; color:#888;">This is an automated email. Do not reply.</p>' +
    '</div>';

    return body;
}

    private static String escapeHtml(String input) {
        if (input == null) {
            return '';
        }
        // Basic escaping to avoid malformed HTML in emails
        String out = input.replace('&', '&amp;');
        out = out.replace('<', '&lt;');
        out = out.replace('>', '&gt;');
        return out;
    }
}