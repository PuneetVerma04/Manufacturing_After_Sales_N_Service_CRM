@SuppressWarnings('PMD.ApexDoc')
@SupperssWarnings('PMD.ApexCRUDViolation')

global with sharing class SLAScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        SLAService.notifySLABreaches();
    }
}