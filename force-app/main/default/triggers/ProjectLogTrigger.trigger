trigger ProjectLogTrigger on Project_Logs__c (before insert, before update) {
    Set<String> pName = new Set<String>();
    Set<String> pExpert = new Set<String>();
    Set<String> pRoles = new Set<String>();
    
    
    // Check if Project and Expert records exist, if not, create them
    for (Project_Logs__c pml : Trigger.new) {
        if (pml.Expert__c != null) {
            pExpert.add(pml.Expert__c);
        }
        if (pml.Project__c != null) {
            pName.add(pml.Project__c);
        }
        if (pml.Role__c != null) {
            pRoles.add(pml.Role__c);
        }
        
        
    }
    
    // Query existing experts and projects
    Map<String, Id> existingPExperts = new Map<String, Id>();
    Map<String, Id> existingPName = new Map<String, Id>();
    Map<String, Id> existingRoles = new Map<String, Id>();
    
    
    
    
    // Map to store processed combinations of project and expert names
    Map<String, Boolean> processedCombinations = new Map<String, Boolean>();
    
    for (Contact expert : [SELECT Id, LastName, AccountId FROM Contact WHERE LastName IN :pExpert]) {
        existingPExperts.put(expert.LastName, expert.Id);
    }
    for (Project__c project : [SELECT Id, Name, Client__c FROM Project__c WHERE Name IN :pName]) {
        existingPName.put(project.Name, project.Id);
    }
    for (Project_Role__c role : [SELECT Id, Name FROM Project_Role__c WHERE Name IN :pRoles]) {
        existingRoles.put(role.Name, role.Id);
    }
    
    
    
    List<Project_Member__c> newProjectMembers = new List<Project_Member__c>();
    
    // Create Expert and Project records if they don't exist
    for (Project_Logs__c pml : Trigger.new) {
        
        if (pml.Expert__c != null && !existingPExperts.containsKey(pml.Expert__c)) {
            Contact newExpert = new Contact(LastName = pml.Expert__c, AccountId = '0015i00000yQM2EAAW');
            insert newExpert;
            existingPExperts.put(newExpert.LastName, newExpert.Id);
        }
        if (pml.Project__c != null) {
            Id projectId;
            // Check if the project already exists
            if (existingPName.containsKey(pml.Project__c)) {
                projectId = existingPName.get(pml.Project__c);
            } else {
                Project__c newProject = new Project__c(Name = pml.Project__c, Client__c = '0015i00000yQM2EAAW');
                insert newProject;
                projectId = newProject.Id;
                existingPName.put(newProject.Name, projectId);
            }
        }
        
    }
    
    
    system.debug('pName-'+pName+',pExpert-'+pExpert);
    List<Project_Member__c> relatedPM = [SELECT Id,Expert__r.Name,Project__r.Name FROM Project_Member__c
                                         WHERE Expert__r.Name IN :pExpert and Project__r.Name in:pName];
    system.debug('relatedPM-'+relatedPM);
    
    map<String,Id> mapPM=new map<String,Id>();
    for (Project_Member__c pm: relatedPM) {
        String strPM=pm.Project__r.Name+pm.Expert__r.Name;
        if(!mapPM.containsKey(strPM)){
            mapPM.put(strPM,pm.Id);
            
        }
    }
    
    system.debug('mapPM-' + mapPM);
    Map<String, Project_Member__c> projectMemberMap = new Map<String, Project_Member__c>();
    
    for (Project_Logs__c pmy : Trigger.new) {
        
        if (pmy.Expert__c != null && pmy.Project__c != null && pmy.Project_Member_id__c == null && pmy.Role__c != null) {
            String strC = pmy.Project__c + pmy.Expert__c ; 
            
            // Check if a Project_Member__c record exists for the current combination.
            if (mapPM.containsKey(strC)) {
                // If already exists use the existing one.
                pmy.Project_Member_id__c = mapPM.get(strC);
            } else {
                // If not, create a new Project_Member__c record.
                Id roleId = existingRoles.get(pmy.Role__c);
                Project_Member__c projectMember = new Project_Member__c(
                    Client__c = '0015i00000yQM2EAAW',
                    Project_role__c = roleId, 
                    Expert__c = existingPExperts.get(pmy.Expert__c),
                    Project__c = existingPName.get(pmy.Project__c)
                );
                insert projectMember;
                // Add the new record to the map for future reference.
                mapPM.put(strC, projectMember.Id);
                pmy.Project_Member_id__c = projectMember.Id;
            }
        }
    }
}