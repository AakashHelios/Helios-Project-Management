public with sharing class InvoiceController {
    //public Id accountId { get; set; }
    //public Date startDate { get; set; }
    //public Date endDate { get; set; }
    //public String invoiceNumber { get; set; }
    //public String terms { get; set; }
    //public String gstin { get; set; }
    //public String invoiceTerms { get; set; }
    public Date invoiceDate { get; set; }
    public Decimal totalAmount { get; set; }
    public Id invoiceId { get; set; }
    public Invoice__c invoice { get; set; }
    public List<Invoice_Line_Item__c> invoiceLineItems { get; set; }
    
    public InvoiceController() {
        invoiceId = ApexPages.currentPage().getParameters().get('id');
        invoiceDate=date.today();
        System.debug('invoiceId'+invoiceId);
        if (invoiceId != null) {
            
            invoice = [
                SELECT Id, Attention__c, Start_Date__c, End_Date__c, Client__c, Invoice_Number__c, Terms__c, GSTIN__c, Date__c,
                (SELECT Id, Description__c, Hours__c, Hourly_Rate__c, Total_Cost__c
                 FROM Invoice_Line_Items__r)
                FROM Invoice__c
                WHERE Id = :invoiceId
            ];
            invoiceLineItems=invoice.Invoice_Line_Items__r;
            system.debug('@invoiceLineItems'+invoiceLineItems);
            totalAmount = 0;
            for (Invoice_Line_Item__c lineItem : invoiceLineItems) {
                totalAmount += lineItem.Total_Cost__c;}
            /*if (invoiceId == null) {
ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid invoice ID.'));
}*/
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid invoice ID.'));
        }
    }
    
    public class ProjectLogWrapper {
        // @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String Project { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Decimal totalHours { get; set; }
        @AuraEnabled public Decimal HR { get; set; }
        
        public ProjectLogWrapper(AggregateResult aggregateResult) {
            this.Project = (String) aggregateResult.get('Project__c');
            this.name = (String) aggregateResult.get('name');
            this.totalHours = (Decimal) aggregateResult.get('totalHours');
            this.HR = (Decimal) aggregateResult.get('HR');
        }
    }
    
    @AuraEnabled
    public static List<ProjectLogWrapper> getProjectLogs(Date startDate, Date endDate, Id clientId) {
        startDate = Date.newInstance(startDate.year(), startDate.month(), startDate.day());
        endDate = Date.newInstance(endDate.year(), endDate.month(), endDate.day());
        
        
        List<ProjectLogWrapper> wrappedLogs = new List<ProjectLogWrapper>();
        if(clientId=='0015i00000yQM2EAAW'){
            
            
            List<AggregateResult> projectLogs = [
                SELECT Project__c, Project_Member_id__r.Project_role__r.name, SUM(Hours__c) totalHours,
                MAX(Project_Member_id__r.Hourly_Rate__c) HR
                FROM Project_Logs__c
                WHERE Date__c >= :startDate AND Date__c <= :endDate AND Project_Member_id__r.Client__c = :clientId
                GROUP BY Project__c, Project_Member_id__r.Project_role__r.name
            ];
            
            for (AggregateResult aggregateResult : projectLogs) {
                wrappedLogs.add(new ProjectLogWrapper(aggregateResult));
            }
        }else {
            List<AggregateResult> projectLogs = [
                SELECT Project__c, Project_Member_id__r.Project_role__r.name, SUM(Hours__c) totalHours,
                MAX(Project_Member_id__r.Hourly_Rate__c) HR
                FROM Harvest_logs__c
                WHERE Date__c >= :startDate AND Date__c <= :endDate AND Project_Member_id__r.Client__c = :clientId
                GROUP BY Project__c, Project_Member_id__r.Project_role__r.name
                
            ];
            for (AggregateResult aggregateResult : projectLogs) {
                wrappedLogs.add(new ProjectLogWrapper(aggregateResult));
            }
            
        }
        
        
        
        System.debug('Fetched Project Logs: ' + wrappedLogs);
        return wrappedLogs;
    }
    
    @AuraEnabled
    public static Map<String, String> getAccountDetails(Id accountId) {
        Map<String, String> accountDetails = new Map<String, String>();
        
        
        Account acc = [SELECT Attention__c, Terms__c, GSTIN__c FROM Account WHERE Id = :accountId LIMIT 1];
        
        // Populate the map with the retrieved values
        accountDetails.put('attention', acc.Attention__c);
        accountDetails.put('terms', acc.Terms__c);
        accountDetails.put('gstin', acc.GSTIN__c);
        
        return accountDetails;
    }
    @AuraEnabled
    public static Id createInvoice(String attention, Id accountId, Date startDate,String Terms, String GSTIN, Date endDate, List<Map<String, Object>> invoiceLineItems) {
        
        
        
        
        Invoice__c newInvoice = new Invoice__c();
        newInvoice.Attention__c = attention;
        newInvoice.Client__c = accountId; 
        newInvoice.Start_Date__c = startDate;
        newInvoice.End_Date__c = endDate;
        newInvoice.GSTIN__c = GSTIN;
        newInvoice.Terms__c = Terms;
        System.debug('Account.id'+accountId);
        insert newInvoice;
        System.debug('newInvoice.id'+newInvoice.id);
        
        
        
        List<Invoice_Line_Item__c> lineItemsToInsert = new List<Invoice_Line_Item__c>();
        for (Map<String, Object> lineItem : invoiceLineItems) {
            Invoice_Line_Item__c newItem = new Invoice_Line_Item__c();
            newItem.Description__c = (String) lineItem.get('Description');
            newItem.Hours__c = (Decimal) lineItem.get('Hours');
            newItem.Hourly_Rate__c = (Decimal) lineItem.get('Price');
            newItem.Total_Cost__c = (Decimal) lineItem.get('Cost');
            newItem.Invoice__c = (Id) lineItem.get('Invoice');
            
            newItem.Invoice__c = newInvoice.Id; 
            System.debug('newInvoice.Id---'+newInvoice.Id);
            
            lineItemsToInsert.add(newItem);
        }
        
        if (!lineItemsToInsert.isEmpty()) {
            insert lineItemsToInsert;
        }
        
        System.debug('invoiceLineItems: ' + invoiceLineItems);
        System.debug('accountId: ' + accountId);
        System.debug('startDate: ' + startDate);
        System.debug('endDate: ' + endDate);
        
        // Return the ID of the created Invoice
        System.debug('newInvoice.Id'+newInvoice.Id);
        Date currDate = Date.today();
        String formattedDate = currDate.format();//prints "2023-02-16"
        
        InvoiceController.createAttachment( accountId);
        System.debug('newInvoice.Id'+newInvoice.Id);
        return newInvoice.Id;
        
        
    }
    
    @AuraEnabled
    @Future(callout=true)
    public static void createAttachment(id accId){
        Account acc=[select Id,name,owner.name,owner.email from Account where id=:accId];
        
        Date currDate = Date.today();
        String formattedDate = currDate.format();//prints "2023-02-16"
        
        // Generate the invoice content and save it as a ContentVersion
        PageReference pageRef = Page.invoice; 
        pageRef.getParameters().put('accid', accId);
        Id accountId = accId;
        
        System.debug('Account Id for Content --'+accId);
        try {
            Blob pdfContent = pageRef.getContent();
            System.debug('  Blob pdfContent '+pageRef.getContent());
            
            
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Invoice-' + formattedDate + '.pdf'; // Set the file name
            cv.PathOnClient = 'Invoice-' + formattedDate + '.pdf'; // Set the file path
            cv.VersionData = pdfContent; // Set the file content
            
            
            insert cv;
            
            System.debug('cv.id'+cv.id);
            
            // Create ContentDocumentLink to link the file to the Account record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
            System.debug('ContentDocumentId--'+cdl.ContentDocumentId);
            cdl.LinkedEntityId = accountId;
            cdl.ShareType = 'V'; 
            cdl.Visibility = 'AllUsers'; 
            
            insert cdl;
            System.debug('cdl'+cdl);
            
            //////////////////////////
            
            
            /* // Prepare the email message
Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
email.setToAddresses(new List<String>{acc.Owner.Email});
email.setSubject('Invoice Created for Account ' + acc.Name);
email.setPlainTextBody('Hello ' + acc.Owner.Name + ',\n\n' +
'An invoice has been created for the account ' + acc.Name + '.\n\n' +
'Please find the attached invoice for your reference.\n\n' +
'Best regards,\nHelios Web Services');

// Attach the invoice PDF to the email
Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
attachment.setFileName(cv.Title);
attachment.setBody(pdfContent);
System.debug('pdfContent'+pdfContent);
email.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});

// Send the email
System.debug('email'+email);
System.debug('To Addresses: ' + email.getToAddresses());
System.debug('Subject: ' + email.getSubject());
System.debug('Body: ' + email.getPlainTextBody());

Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});

*/
        } catch (Exception e) {
            System.debug('Error generating PDF or sending email: ' + e.getMessage());
        }        
    }
    
    
    
    
    
}