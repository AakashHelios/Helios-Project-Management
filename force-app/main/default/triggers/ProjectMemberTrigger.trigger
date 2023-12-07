trigger ProjectMemberTrigger on Project_Member__c (after insert, after update) {
    Set<Id> newProjectMemberIds = new Set<Id>();
    for (Project_Member__c pm : Trigger.new) {
        newProjectMemberIds.add(pm.Id);
    }
    
    Map<Id, Project_Member__c> objMap = new Map<Id, Project_Member__c>([
        SELECT Id, Name, project__r.Name, Client__c, Expert__c, Hourly_Rate__c, Project_role__c
        FROM Project_Member__c
        WHERE Id IN :newProjectMemberIds
    ]);

    List<Task> tasksToInsert = new List<Task>();
    Account acc = new Account();

    for (Project_Member__c pm : Trigger.new) {
        Project_Member__c relatedProjectMember = objMap.get(pm.Id);
        
         //if hourly rate is null and role is not null..
        if (relatedProjectMember.Hourly_Rate__c == null && relatedProjectMember.Project_role__c != null) {
            Task newTask = new Task();
            newTask.Project_Member__c = relatedProjectMember.Id;
            newTask.WhatId = relatedProjectMember.Client__c;
            newTask.WhoId = relatedProjectMember.Expert__c;
            newTask.Subject = 'Please Fill Hourly Rate';
            newTask.Description ='Please fill in the hourly rate for ' + relatedProjectMember.Name + ' project member.';
            newTask.Priority = 'High';
            newTask.Status = 'Pending';
            tasksToInsert.add(newTask);
            
             // send email to Account owner
           acc = [SELECT Id, Name, Owner.Name, Owner.Email FROM Account WHERE Id = :relatedProjectMember.Client__c LIMIT 1];
    
            if (acc.Owner.Email != null) {
                // Create a URL with the current record ID
                String recordId = relatedProjectMember.Id;
                String recordURL = 'https://helioswebservices47-dev-ed.develop.lightning.force.com/lightning/r/Project_Member__c/' + recordId + '/view';
                
                // Compose the email body with the clickable URL
                String emailBody = 'Please Fill Hourly Rate  For ' + relatedProjectMember.Name + ' project member.' +
                                   '\n\nClick the link below to update the record:\n' + recordURL;
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{acc.Owner.Email});
                mail.setSubject('Please Fill Hourly Rate  ');
                mail.setPlainTextBody(emailBody);
                
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            }
        }
         //if hourly rate is not null and role is null..
        if (relatedProjectMember.Project_role__c == null && relatedProjectMember.Hourly_Rate__c != null) {
            Task newTask = new Task();
            newTask.Project_Member__c = relatedProjectMember.Id;
            newTask.WhatId = relatedProjectMember.Client__c;
            newTask.WhoId = relatedProjectMember.Expert__c;
            newTask.Subject = 'Please Fill Role';
            newTask.Description ='Please fill in the Role for ' + relatedProjectMember.Name + ' project member.';
            newTask.Priority = 'High';
            newTask.Status = 'Pending';
            tasksToInsert.add(newTask);

            if (acc.Owner.Email != null) {
                // Create a URL with the current record ID
                String recordId = relatedProjectMember.Id;
                String recordURL = 'https://helioswebservices47-dev-ed.develop.lightning.force.com/lightning/r/Project_Member__c/' + recordId + '/view';
                
                // Compose the email body with the clickable URL
                String emailBody = 'Please Fill Role For ' + relatedProjectMember.Name + ' project member.' +
                                   '\n\nClick the link below to update the record:\n' + recordURL;
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{acc.Owner.Email});
                mail.setSubject('Please Fill Role ');
                mail.setPlainTextBody(emailBody);
                
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            }
        }
        //if hourly rate and role both are null..
        if (relatedProjectMember.Hourly_Rate__c == null && relatedProjectMember.Project_role__c == null) {
            Task newTask = new Task();
            newTask.Project_Member__c = relatedProjectMember.Id;
            newTask.WhatId = relatedProjectMember.Client__c;
            newTask.WhoId = relatedProjectMember.Expert__c;
            newTask.Subject = 'Please Fill Hourly Rate & Role';
            newTask.Description ='Please fill in the hourly rate & Role for ' + relatedProjectMember.Name + ' project member.';
            newTask.Priority = 'High';
            newTask.Status = 'Pending';
            tasksToInsert.add(newTask);
    
        if (acc.Owner.Email != null) {
            // Create a URL with the current record ID
            String recordId = relatedProjectMember.Id;
            String recordURL = 'https://helioswebservices47-dev-ed.develop.lightning.force.com/lightning/r/Project_Member__c/' + recordId + '/view';
            
            // Compose the email body with the clickable URL
            String emailBody = 'Please Fill Hourly Rate & Role For ' + relatedProjectMember.Name + ' project member.' +
                               '\n\nClick the link below to update the record:\n' + recordURL;
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{acc.Owner.Email});
            mail.setSubject('Please Fill Hourly Rate & Role ');
            mail.setPlainTextBody(emailBody);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        }
    }

        
          
        

       
    }

    insert tasksToInsert;
}