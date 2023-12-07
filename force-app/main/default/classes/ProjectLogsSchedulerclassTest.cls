@isTest
private class ProjectLogsSchedulerclassTest {
    @isTest
    static void testBatchProcessing() {
        // Create test data for Project_Logs__c and Project_Member__c objects
        Project__c testProject = new Project__c(
          Name = 'a025i00000Vh57FAAR');
        insert testProject;

        Contact testExpert = new Contact(LastName = '0035i000085ZQnTAAW');
        insert testExpert;

        Project_Logs__c projectLog = new Project_Logs__c(
            Project__c = 'a025i00000Vh57FAAR', 
            Expert__c = '0035i000085ZQnTAAW');
        insert projectLog;
        System.debug('projectLog'+projectLog);

        Project_Member__c projectMember = new Project_Member__c(Expert__c = testExpert.Id, Project__c = testProject.Id);
        insert projectMember;
        System.debug('projectMember'+projectMember);

        // Start the batch job
        Test.startTest();
        ProjectLogsSchedulerclass batchJob = new ProjectLogsSchedulerclass();
        Database.executeBatch(batchJob);
        Test.stopTest();

        // Retrieve the updated Project_Logs__c record
        Project_Logs__c updatedProjectLog = [SELECT Id, Project_Member_id__c FROM Project_Logs__c WHERE Id = :projectLog.Id LIMIT 1];
		System.debug('updatedProjectLog'+updatedProjectLog);
        System.debug('Project_Member_id__c'+updatedProjectLog.Project_Member_id__c);
        // Assert that the Project_Member_id__c field is populated correctly
        System.assertNotEquals(null, updatedProjectLog.Project_Member_id__c, 'Project_Member_id__c should not be null');
        System.assertEquals(projectMember.Id, updatedProjectLog.Project_Member_id__c, 'Project_Member_id__c should match the inserted Project Member Id');
    }
}