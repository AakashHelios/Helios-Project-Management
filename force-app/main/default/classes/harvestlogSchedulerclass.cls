global class harvestlogSchedulerclass implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, First_Name__c, Last_Name__c, Project__c, Project_Member_id__c
            FROM Harvest_logs__c
            WHERE Project_Member_id__c = null
        ]);
    }

   global void execute(Database.BatchableContext BC, List<Harvest_logs__c> scope) {
    // Iterate through the records and populate Project_Member_id__c where necessary
    for (Harvest_logs__c record : scope) {
        String expertFirstName = record.First_Name__c;
        String expertLastName = record.Last_Name__c;
        String projectName = record.Project__c;

        // Query Project_Member__c to find matching Project Member with partial matches on first name and last name
        List<Project_Member__c> projectMembers = [
            SELECT Id
            FROM Project_Member__c 
            WHERE Expert__r.FirstName LIKE :expertFirstName + '%'
            AND Expert__r.LastName = :expertLastName
            AND Project__r.Name = :projectName 
            LIMIT 1
        ];

        // Check if any matching Project Member exists, populate Project_Member_id__c
        if (!projectMembers.isEmpty()) {
            record.Project_Member_id__c = projectMembers[0].Id;
        }
    }
    update scope;
}


    global void finish(Database.BatchableContext BC) {
        // Optional: Implement any post-processing logic here
    }
}