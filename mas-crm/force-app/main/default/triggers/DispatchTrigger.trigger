trigger DispatchTrigger on Dispatch__c (after insert, after update) {
    Set<Id> engineerNotify = new Set<Id>();
    Set<Id> agentNotify = new Set<Id>();

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            for(Dispatch__c d : Trigger.new){
                if(d.Engineer_Assigned__c != null) engineerNotify.add(d.Id);
                if(d.Agent_Dispatched__c != null) agentNotify.add(d.Id);
            }
        } else if(Trigger.isUpdate){
            for(Dispatch__c d : Trigger.new){
                Dispatch__c oldD = Trigger.oldMap.get(d.Id);
                // Notify engineer if assignment changed
                if(d.Engineer_Assigned__c != oldD.Engineer_Assigned__c && d.Engineer_Assigned__c != null)
                    engineerNotify.add(d.Id);
                // Notify agent if dispatched changed
                if(d.Agent_Dispatched__c != oldD.Agent_Dispatched__c && d.Agent_Dispatched__c != null)
                    agentNotify.add(d.Id);
            }
        }
    }

    if(!engineerNotify.isEmpty())
        NotificationService.sendEngineerNotificationForDispatch(engineerNotify);

    if(!agentNotify.isEmpty())
        NotificationService.sendAgentNotificationForDispatch(agentNotify);
}
