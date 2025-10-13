trigger ServiceCaseTrigger on Service_Case__c (before update, after insert, after update) {


    if (Trigger.isBefore && Trigger.isUpdate) {
        for (Service_Case__c sc : Trigger.new) {
            Service_Case__c oldSc = Trigger.oldMap.get(sc.Id);

            // Set Closed_Date__c when Status changes to "Closed"
            if (sc.Status__c == 'Closed' && oldSc.Status__c != 'Closed') {
                sc.Closed_Date__c = System.now();
            }
        }
    }


    Set<Id> engineerNotify = new Set<Id>();
    Set<Id> agentNotify = new Set<Id>();

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            for(Service_Case__c sc : Trigger.new){
                if(sc.Engineer_Assigned__c != null) engineerNotify.add(sc.Id);
                if(sc.Assigned_Agent__c != null) agentNotify.add(sc.Id);
            }
        } else if(Trigger.isUpdate){
            for(Service_Case__c sc : Trigger.new){
                Service_Case__c oldSc = Trigger.oldMap.get(sc.Id);
                // Notify engineer if assignment changed
                if(sc.Engineer_Assigned__c != oldSc.Engineer_Assigned__c && sc.Engineer_Assigned__c != null)
                    engineerNotify.add(sc.Id);
                // Notify service agent if assignment changed
                if(sc.Assigned_Agent__c != oldSc.Assigned_Agent__c && sc.Assigned_Agent__c != null)
                    agentNotify.add(sc.Id);
            }
        }
    }

    if(!engineerNotify.isEmpty())
        NotificationService.sendEngineerNotificationForCase(engineerNotify);

    if(!agentNotify.isEmpty())
        NotificationService.sendAgentNotificationForCase(agentNotify);
}