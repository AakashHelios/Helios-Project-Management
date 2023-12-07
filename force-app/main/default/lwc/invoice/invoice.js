import { LightningElement, wire, track } from 'lwc';
import createInvoice from '@salesforce/apex/InvoiceController.createInvoice';
import { getListUi } from 'lightning/uiListApi';
import getProjectLogs from'@salesforce/apex/InvoiceController.getProjectLogs'
import getAccountDetails from '@salesforce/apex/InvoiceController.getAccountDetails'


import { NavigationMixin } from 'lightning/navigation';


export default class Invoice extends LightningElement {
    @track startDate;
    @track endDate;
    @track invoiceNumber;
    @track client;
    @track terms;
    @track gstin;
    @track showTable = false; 
    @track showfields=false;
    @track totalCost = 0;
    
    @track invoiceItems = Array.from({ length: 3 }, (_, index) => ({
        id: index,
        description: '',
        hours: 0,
        price: 0,
        cost: 0
    }));
    
    @track selectedAccountId;
    @track accountOptions = [];
    
    @wire(getListUi, { objectApiName: 'Account', listViewApiName: 'AllAccounts' })
    wiredAccounts({ error, data }) {
       
        if (data) {
            this.accountOptions = data.records.records.map(record => ({
                label: record.fields.Name.value,
                value: record.id
            }));
        } else if (error) {
            console.error('Error loading accounts:', error);
        }
    }

    
    handlePullData() {
        getProjectLogs({ startDate: this.startDate, endDate: this.endDate, clientId: this.selectedAccountId })
            .then(result => {
                if (result && result.length > 0) {
                    this.invoiceItems = result.map(item => ({
                        id: item.Id,
                        description: `${item.Project} - ${item.name}`, 
                        hours: item.totalHours || 0, 
                        price: item.HR || 0,
                        cost: item.totalHours*item.HR
                    }));
                    this.showfields = true;
                    this.showtable=true;

                    this.calculateTotalCost();
                   
                getAccountDetails({ accountId: this.selectedAccountId })
                .then(accountDetails => {
                    this.gstin = accountDetails.gstin;
                    this.terms = accountDetails.terms;
                    this.attention=accountDetails.attention
                })
                .catch(error => {
                    console.error('Error fetching Account details:', error);
                });
        } else {
            console.error('Empty ');
        }
    })
            .catch(error => {
                console.error('Error fetching Project Logs:', error);
            });
    }
    fetchAccountDetails(accountId) {
    getAccountDetails({ accountId: accountId })
    .then(result => {
        if (result) {
          
            this.gstin = result.GSTIN__c; 
            this.terms = result.Terms__c; 
            this.attention=result.Attention__c;
        } else {
            console.error('Account details not found.');
        }
    })
    .catch(error => {
        console.error('Error fetching Account details:', error);
    });
    }
    calculateTotalCost() {
        this.totalCost = this.invoiceItems.reduce((total, item) => {
            return total + parseFloat(item.cost);
        }, 0);
    }


    handleItemChange(event) {
    const { index, field } = event.target.dataset;
    const value = event.target.value;
    this.invoiceItems[index][field] = value;
    if (field === 'hours' || field === 'price') {
        this.invoiceItems[index].cost = this.calculateCost(
            this.invoiceItems[index].hours,
            this.invoiceItems[index].price
        );
    }
    this.calculateTotalCost();
    this.invoiceItems = [...this.invoiceItems];
    console.log('invoiceItems', this.invoiceItems );
}


    handlestartdate(event) {
        const { label, value } = event.target;
        this[label.toLowerCase()] = value;
        this.startDate=value;

    }

    handleenddate(event){
        const { label, value } = event.target;
        this[label.toLowerCase()] = value;
        this.endDate=value;
    }
    handleClientChange(event) {
        this.selectedAccountId = event.detail.value;
    }



    calculateCost(hours, price) {
        return hours * price;
    }

    get calculatedTotalCost() {
        return this.invoiceItems.reduce((total, item) => {
            return total + parseFloat(item.cost);
        }, 0);
    }

    handleGenerateInvoice() {
        let invoiceLineItems = [];
        this.invoiceItems.forEach(item => {
            let lineItem = {
                Description: item.description,
                Hours: parseFloat(item.hours),
                Price: parseFloat(item.price),
                Cost: parseFloat(item.cost)
            };
            invoiceLineItems.push(lineItem);
        });
    
        createInvoice({
            attention: this.attention,
            startDate: this.startDate,
            endDate: this.endDate,
            accountId: this.selectedAccountId,
            invoiceLineItems: invoiceLineItems,
            GSTIN:this.gstin,
            Terms: this.terms
            
        })
        .then(result => {
        //    this.navigateToCustomTab();
            let invoiceId = result; 
            console.log('invoiceId', invoiceId);
            let vfPageUrl = '/apex/invoice?id=' + invoiceId; 
            window.open(vfPageUrl, '_blank');
            
          
       
            this.InvoiceRecordPage();
  
          //  this.navigateToCustomTab();

        })
        .catch(error => {
            console.error('Error creating invoice:', error.body.message);
        });
    }

    //To redirect to Recordpage
    InvoiceRecordPage(){
    
    let accountId = this.selectedAccountId;
    console.log('accountId',accountId);
    let customTabUrl = `https://helioswebservices47-dev-ed.develop.lightning.force.com/lightning/r/Account/${accountId}/view`;
    window.location.href = customTabUrl;

    }
    
    
    navigateToCustomTab() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Invoice__c',
                actionName: 'list'
            }
        });
    }    

  
    handleCancel(){
        this.showfields = false;
        this.showtable=false;
    }
    
    connectedCallback() {
        console.log(' this.invoiceItems', this.invoiceItems);
        this.invoiceItems.push({
            id: 1,
            Description: '', 
            Hours: 0,        
            Price: 0,         
            Cost: 0           
        });
    }
    
    handleGstinInputChange(event) {
        this.gstin = event.target.value;
    }

    handleTermInputChange(event) {
        this.terms = event.target.value;
    }

}
