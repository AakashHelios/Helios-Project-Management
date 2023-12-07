@isTest
private class testing {
    
    @isTest
    static void testBatchProcessing() {
        // Create test data for Project_Logs__c and Project_Member__c objects
        Project__c testProject = new Project__c(
            Name = 'a025i00000VhUtfAAF');
        insert testProject;
        
        Contact testExpert = new Contact(FirstName='son',LastName = 'don');
        insert testExpert;
        
        // Create a Harvest_logs__c record with specific First_Name__c, Last_Name__c, and Project__c values
        Harvest_logs__c harvestLog = new Harvest_logs__c(
            First_Name__c = 'Don',
            Last_Name__c = 'Doe',
            Project__c = 'a025i00000VhUtfAAF'
        );
        insert harvestLog;
        System.debug('Test harvestLog'+harvestLog);
        
        // Create test data for Project_Member__c object with Expert__c field as a reference to the Contact record
        Project_Member__c projectMember = new Project_Member__c(
            Expert__c = testExpert.Id,
            Project__c = testProject.Id
        );
        insert projectMember;
        System.debug('Test class projectMember ='+projectMember);
        
        // Start the batch job
        Test.startTest();
        harvestlogSchedulerclass batchJob = new harvestlogSchedulerclass();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
        // Retrieve the updated Harvest_logs__c record
        Harvest_logs__c updatedHarvestLog = [SELECT Id, Project_Member_id__c FROM Harvest_logs__c WHERE Id = :harvestLog.Id LIMIT 1];
        
        System.debug(' test class -updatedHarvestLog--'+updatedHarvestLog);
        
        System.debug('Project Member ID: ' + projectMember.Id);
        System.debug(' test class Project_Member_id__c: ' + updatedHarvestLog.Project_Member_id__c);
        System.assertNotEquals(null, updatedHarvestLog.Project_Member_id__c, 'Project_Member_id__c should not be null');
        System.assertEquals(projectMember.Id, updatedHarvestLog.Project_Member_id__c, 'Project Member Id should be populated');
    }
}