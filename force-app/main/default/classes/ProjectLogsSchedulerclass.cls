global class ProjectLogsSchedulerclass implements Database.Batchable<SObject> {
    //for project_logs__c
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query Project_Logs__c where Project_Member_id__c is null
        System.debug('Batch Start');
        
        return Database.getQueryLocator([
            SELECT Id, Project__c, Expert__c, Project_Member_id__c FROM Project_Logs__c
            WHERE Project_Member_id__c = null  
            
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        // Iterate through the records and populate Project_Member_id__c where necessary
        for (SObject record : scope) {
            String expertName = (String) record.get('Expert__c');
            String projectName = (String) record.get('Project__c');
            
            System.debug('expertName'+expertName);
            System.debug('projectName'+projectName);
            
            // Query Project_Member__c to find matching Project Member
            Project_Member__c projectMember = [
                SELECT Id ,Expert__c,Project__c
                FROM Project_Member__c 
                
                WHERE Expert__r.Name = :expertName AND Project__r.Name = :projectName 
                
            ];
            System.debug('projectMember'+projectMember);
            
            // Check if matching Project Member exists, populate Project_Member_id__c
            if (projectMember != null) {
                record.put('Project_Member_id__c', projectMember.Id);
            } else {
                System.debug('No matching Project Member found for Expert: ' + expertName + ' and Project: ' + projectName);
    
            }
        }
        System.debug('scope'+scope);
        // Update the records with populated Project_Member_id__c
        update scope;
    }
    
    global void finish(Database.BatchableContext BC) {
         System.debug('finished');
        
    }
}