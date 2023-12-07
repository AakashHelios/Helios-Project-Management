trigger HarvestlogTrigger on Harvest_logs__c (before insert, before update) {

        Map<String, String> LastName = new Map<String, String>();
        Set<String> projectName = new Set<String>();
    
        for (Harvest_logs__c pml : Trigger.new) {
        if (pml.Last_Name__c != null && pml.First_Name__c != null) {
            String fullName = pml.First_Name__c + ' ' + pml.Last_Name__c  ;
            LastName.put(fullName, fullName);
        }
        System.debug('LastName'+LastName);
        if (pml.Project__c != null) {
            projectName.add(pml.Project__c);
        }
    }

        System.debug('LastName'+LastName);
          // Query existing experts and projects
        Map<String, Id> existingLastName = new Map<String, Id>();
        Map<String, Id> existingprojectName = new Map<String, Id>();
       
         // Map to store processed combinations of project and expert names
        Map<String, Boolean> processedCombinations = new Map<String, Boolean>();
        
       Set<String> lastNamesSet = LastName.keySet();
    System.debug('lastNamesSet'+lastNamesSet);
    
        for (Contact expert : [SELECT Id, LastName, AccountId FROM Contact WHERE LastName IN :lastNamesSet]) {
        existingLastName.put(expert.LastName, expert.Id);
    }
    
        for (Project__c project : [SELECT Id, Name, Client__c FROM Project__c WHERE Name IN :projectName]) {
            existingprojectName.put(project.Name, project.Id);
        }
       

                
        List<Project_Member__c> newProjectMembers = new List<Project_Member__c>();
        
        // Create last name and Project records if they don't exist
for (Harvest_logs__c pml : Trigger.new) {
    if (pml.Last_Name__c != null && !existingLastName.containsKey(pml.Last_Name__c)) {
        // Check if a contact with the same last name already exists
        Contact[] existingContacts = [SELECT Id FROM Contact WHERE LastName = :pml.Last_Name__c LIMIT 1];
        if (existingContacts.isEmpty()) {
            // If no existing contact found, create a new one
            Contact newExpert = new Contact(LastName = pml.Last_Name__c, FirstName = pml.First_Name__c, AccountId = '0015i000010n9oWAAQ');
            insert newExpert;
            existingLastName.put(newExpert.LastName, newExpert.Id);
        }  else {
            // If contact already exists, use its Id
            existingLastName.put(pml.Last_Name__c, existingContacts[0].Id);
        }
       if (pml.Project__c != null) {
            Id projectId;
            // Check if the project already exists
            if (existingprojectName.containsKey(pml.Project__c)) {
                projectId = existingprojectName.get(pml.Project__c);
            } else {
                Project__c newProject = new Project__c(Name = pml.Project__c, Client__c = '0015i000010n9oWAAQ');
                insert newProject;
                projectId = newProject.Id;
                existingprojectName.put(newProject.Name, projectId);
            }
        }
      
    }

         
        }
        /////////////////////////////////////////////////////////////////////////////////////////////////////////
       
         system.debug('projectName-'+projectName+',LastName-'+LastName);
        
       
  		 Set<String> lastNames = LastName.keySet();
    
        List<Project_Member__c> relatedPM = [SELECT Id,Expert__r.Name,Project__r.Name FROM Project_Member__c
                                             WHERE Expert__r.Name IN :lastNames and Project__r.Name in:projectName];
       
 
        map<String,Id> mapPM=new map<String,Id>();
        for (Project_Member__c pm: relatedPM) {
            String strPM=pm.Project__r.Name+pm.Expert__r.Name;
            if(!mapPM.containsKey(strPM)){
                mapPM.put(strPM,pm.Id);
                
            }
        }
     
           Map<String, Project_Member__c> projectMemberMap = new Map<String, Project_Member__c>();
    
 	   for (Harvest_logs__c pmy : Trigger.new) {
        
    
        if (pmy.Last_Name__c != null  && pmy.Project__c != null && pmy.Project_Member_id__c == null ) {
        
            String strC = pmy.Project__c + pmy.First_Name__c +' '+ pmy.Last_Name__c;
			 // Check if a Project_Member__c record exists for the current combination.
            if (mapPM.containsKey(strC)) {
             // If already exists use the existing one.
             pmy.Project_Member_id__c = mapPM.get(strC);
            } else {
                // If not, create a new Project_Member__c record.
        	 Project_Member__c projectMember = new Project_Member__c(
                    Client__c = '0015i000010n9oWAAQ',
                    Expert__c = existingLastName.get(pmy.Last_Name__c),
                    Project__c = existingprojectName.get(pmy.Project__c)
                );
                insert projectMember;
                // Add the new record to the map for future reference.
                mapPM.put(strC, projectMember.Id);
                pmy.Project_Member_id__c = projectMember.Id;
            }
        }
    }
    
    
    
    
    
    
    
}