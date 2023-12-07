@isTest
public class InvoiceControllerTest {
    
      @isTest
    static void testInvoiceControllerWithInvoiceId() {
        // Test data setup
        Invoice__c testInvoice = new Invoice__c(
            Attention__c = 'Test Attention',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today(),

           
            Terms__c = 'Test Terms',
            GSTIN__c = 'Test GSTIN',
            Date__c = Date.today()
        );
        insert testInvoice;

        Invoice_Line_Item__c testLineItem = new Invoice_Line_Item__c(
            Description__c = 'Test Description',
            Hours__c = 5,
            Hourly_Rate__c = 50,
            Total_Cost__c = 250,
            Invoice__c = testInvoice.Id
        );
        insert testLineItem;

        // Set the current page parameters
        ApexPages.currentPage().getParameters().put('id', testInvoice.Id);

        Test.startTest();
        // Instantiate the controller
        InvoiceController controller = new InvoiceController();
        Test.stopTest();

        // Verify that the invoice details are populated
        System.assertNotEquals(null, controller.invoice);
        System.assertEquals(testInvoice.Id, controller.invoice.Id);
        System.assertEquals(1, controller.invoiceLineItems.size());
        System.assertEquals(250, controller.totalAmount);
    }
    
    
    
    
    
    @isTest
    static void testCreateInvoiceWithEmptyLineItems() {
        // Test data setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        List<Map<String, Object>> invoiceLineItems = new List<Map<String, Object>>();
        
        Test.startTest();
        Id invoiceId = InvoiceController.createInvoice('Test Attention', acc.Id, Date.today(), 'Test Terms', 'Test GSTIN', Date.today(), invoiceLineItems);
        Test.stopTest();
        
        // Verify that the invoice was created successfully with no line items
        System.assertNotEquals(null, invoiceId);
        
        // Query the invoice and verify its existence
        Invoice__c invoice = [SELECT Id FROM Invoice__c WHERE Id = :invoiceId LIMIT 1];
        System.assertEquals(invoiceId, invoice.Id);
        
        List<Invoice_Line_Item__c> lineItems = [SELECT Id FROM Invoice_Line_Item__c WHERE Invoice__c = :invoiceId];
        System.assertEquals(0, lineItems.size());
    }
    
    @isTest
    static void testGetAccountDetails() {
        // Test data setup
        Account acc = new Account(Name = 'Test Account', Attention__c = 'Test Attention');
        insert acc;
        
        // Call the method to be tested
        Map<String, String> accountDetails = InvoiceController.getAccountDetails(acc.Id);
        
        // Verify that account details were retrieved successfully
        System.assertEquals('Test Attention', accountDetails.get('attention'));
    }
    
    @isTest
    static void testGetProjectLogs() {
        
        
        
        // Test data setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;
         List<Map<String, Object>> invoiceLineItems = new List<Map<String, Object>>();
        Map<String, Object> lineItem = new Map<String, Object>{
            'Description' => 'Test Description',
                'Hours' => 5,
                'Price' => 50,
                'Cost' => 250,
                'Invoice' => acc.Id
                };
                    invoiceLineItems.add(lineItem);

        Id clientId = '0015i00000yQM2EAAW'; 
        // Creating related data
        Project_Member__c projectMember = new Project_Member__c(
            
            Project_role__c = 'a015i000011sMlPAAU',
            Hourly_Rate__c = 50.00,
            Client__c = clientId
        );
        insert projectMember;
        
        Project_Logs__c projectLog = new Project_Logs__c(
            Project__c = 'Test Project',
            Project_Member_id__c = projectMember.Id,
            Hours__c = 10,
            Date__c = Date.today()
        );
        insert projectLog;
        
        // Call the method to be tested
        Test.startTest();
          Id invoiceId = InvoiceController.createInvoice('Test Attention', acc.Id, Date.today(), 'Test Terms', 'Test GSTIN', Date.today(), invoiceLineItems);

        List<InvoiceController.ProjectLogWrapper> projectLogs = InvoiceController.getProjectLogs(Date.today(), Date.today(), clientId);
        Test.stopTest();
        
        // Verify that project logs were retrieved successfully
        System.assertNotEquals(null, projectLogs);
        System.assertEquals(1, projectLogs.size()); // Assuming one log was created for the given date range and account ID
        
        // Verify the values in the returned wrapper
        InvoiceController.ProjectLogWrapper logWrapper = projectLogs[0];
             // Query the line items and verify their existence
        List<Invoice_Line_Item__c> lineItems = [SELECT Id FROM Invoice_Line_Item__c WHERE Invoice__c = :invoiceId];
        System.assertEquals(1, lineItems.size());

        System.assertEquals('Test Project', logWrapper.Project);
        System.assertEquals('Developer', logWrapper.name);
        System.assertEquals(10.0, logWrapper.totalHours);
        System.assertEquals(50.0, logWrapper.HR);
    }
    
    
    
    /* @isTest
static void testGetharvestLogs() {
// Test data setup
Account acc = new Account(Name = 'Test Account');
insert acc;

// Call the method to be tested
List<InvoiceController.ProjectLogWrapper> projectLogs = InvoiceController.getProjectLogs(Date.today(), Date.today(), acc.Id);

// Verify that project logs were retrieved successfully
System.assertEquals(0, projectLogs.size()); // Assuming no logs exist for the given date range and account ID
}*/
    
    @isTest
    static void testGetProjectLogsForharvest() {
        // Test data setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Id clientId = acc.id; 
        // Creating related data
        Project_Member__c projectMember = new Project_Member__c(
            
            Project_role__c = 'a015i000011sMlPAAU',
            Hourly_Rate__c = 50.00,
            Client__c = clientId
        );
        insert projectMember;
        
        Harvest_logs__c projectLog = new Harvest_logs__c(
            Project__c = 'Test Project',
            Project_Member_id__c = projectMember.Id,
            Hours__c = 10,
            Date__c = Date.today()
        );
        insert projectLog;
        
        // Call the method to be tested
        Test.startTest();
        List<InvoiceController.ProjectLogWrapper> projectLogs = InvoiceController.getProjectLogs(Date.today(), Date.today(), clientId);
        Test.stopTest();
        
        // Verify that project logs were retrieved successfully
        System.assertNotEquals(null, projectLogs);
        System.assertEquals(1, projectLogs.size()); // Assuming one log was created for the given date range and account ID
        
        // Verify the values in the returned wrapper
        InvoiceController.ProjectLogWrapper logWrapper = projectLogs[0];
        System.assertEquals('Test Project', logWrapper.Project);
        System.assertEquals('Developer', logWrapper.name);
        System.assertEquals(10.0, logWrapper.totalHours);
        System.assertEquals(50.0, logWrapper.HR);
    }
    
    
    @isTest
    static void testInvoiceControllerWithNonNullInvoiceId() {
        // Test data setup
        Invoice__c invoice = new Invoice__c(/* Set required fields */);
        insert invoice;
        
        // Set the current page parameters
        ApexPages.currentPage().getParameters().put('id', invoice.Id);
        
        // Call the constructor
        InvoiceController controller = new InvoiceController();
        
        // Verify that the invoice details are populated
        System.assertNotEquals(null, controller.invoice);
    }
    
    @isTest
    static void testInvoiceControllerWithNullInvoiceId() {
        // Set the current page parameters with null invoiceId
        ApexPages.currentPage().getParameters().put('id', null);
        
        // Call the constructor
        InvoiceController controller = new InvoiceController();
        
        // Verify that the appropriate error message is added to ApexPages messages
        System.assertEquals(1, ApexPages.getMessages().size());
        System.assertEquals(ApexPages.Severity.ERROR, ApexPages.getMessages()[0].getSeverity());
    }
    
    
    
    
    
    
    
    
    
    
}