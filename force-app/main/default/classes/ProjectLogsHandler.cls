public class ProjectLogsHandler {

    @future
    public static void updateProjectMemberIds(Set<Id> projectLogsIds) {
        List<Project_Logs__c> projectLogsToUpdate = [SELECT Id, Project__c, Expert__c, Project_Member_id__c FROM Project_Logs__c 
             WHERE Id IN :projectLogsIds AND Project_Member_id__c = null];

        Map<String, Id> mapPM = new Map<String, Id>();
        for (Project_Logs__c pml : projectLogsToUpdate) {
            String strC = pml.Project__c + pml.Expert__c;
            
            Project_Member__c pm = [SELECT Id FROM Project_Member__c WHERE Expert__c = :pml.Expert__c AND Project__c = :pml.Project__c LIMIT 1];
            if (pm != null) {
                mapPM.put(strC, pm.Id);
            }
        }

        List<Project_Logs__c> recordsToUpdate = new List<Project_Logs__c>();
        for (Project_Logs__c pml : projectLogsToUpdate) {
            String strC = pml.Project__c + pml.Expert__c;
            if (mapPM.containsKey(strC)) {
                pml.Project_Member_id__c = mapPM.get(strC);
                recordsToUpdate.add(pml);
            }
        }
        
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }
}