@isTest
public class TestInvoiceController {

    @isTest
    static void testInvoiceControllerWithValidId() {
        // Create test data and set the page parameters with a valid ID
        Invoice__c testInvoice = new Invoice__c(
            Attention__c = 'Test Attention',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today(),
            Terms__c = 'Net 30',
            GSTIN__c = 'GST123456',
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

        // Set the page parameters with a valid ID
        Test.setCurrentPageReference(new PageReference('/apex/invoice?id=' + testInvoice.Id));

        // Instantiate the controller
        InvoiceController controller = new InvoiceController();

        // Verify the controller logic
        System.assertEquals(testInvoice.Id, controller.invoiceId);
        System.assertEquals(testInvoice.Attention__c, controller.invoice.Attention__c);
        System.assertEquals(testInvoice.Start_Date__c, controller.invoice.Start_Date__c);
        // Add more assertions as needed based on your use case
        
    }

    @isTest
    static void testInvoiceControllerWithInvalidId() {
        // Set the page parameters with a valid but non-existing ID
        Test.setCurrentPageReference(new PageReference('/apex/invoice?id=0011234567889'));

        // Instantiate the controller
        InvoiceController controller = new InvoiceController();

        // Verify that an error message is added to the page messages
        System.assertEquals(1, ApexPages.getMessages().size());
        System.assertEquals(ApexPages.Severity.ERROR, ApexPages.getMessages()[0].getSeverity());
    }
}