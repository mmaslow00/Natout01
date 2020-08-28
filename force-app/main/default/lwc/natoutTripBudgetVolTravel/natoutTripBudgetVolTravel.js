import { LightningElement, api, wire, track } from 'lwc';
import getVolTravelList from '@salesforce/apex/NatoutTripBudgetController.getVolTravelList';
import { createRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { reduceErrors } from 'c/ldsUtils';

const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];
const columns = [
    { label: 'Category', fieldName: 'Item_Category__c', type: 'text', wrapText: true, hideDefaultActions: true  },
    { label: 'Amount', fieldName: 'amountDisplay', hideDefaultActions: true},
    { label: 'Role', fieldName: 'Staff_Role__c', hideDefaultActions: true, wrapText: true }
];

const itemCategories = [
    { label: 'Airfare', value: 'Airfare'},
    { label: 'Mileage', value: 'Mileage'},
    { label: 'Other - airport parking, baggage fees, etc.', value: 'Other - airport parking, baggage fees, etc.'},
    { label: 'Subsistence', value: 'Subsistence'},
    { label: 'Transportation - In country', value: 'Transportation - In country'},
    { label: 'Transportation - US', value: 'Transportation - US'},
    { label: 'Vehicle Rental - Volunteer', value: 'Vehicle Rental - Volunteer'},
];

const formatter = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2
  });

export default class NatoutTripBudgetVolTravel extends LightningElement {
    itemCategories = itemCategories;
    @api recordId = '';
    @api staffRoleOptions = [];
    @api canEdit = false;
    @track budgetList=[];
    @track itemToUpdate = {};
    @track isModalOpen = false;
    @track amountLabel = 'Dollars';
    wiredBudget;
    saveSuccessful;

    @wire(getVolTravelList, {tripId: '$recordId'})
    wiredBudgetList(result) {
        if(result.data) {
            this.wiredBudget = result;
            this.budgetList = result.data.map(row => {
                let amountDisplay = row.Amount__c.toString();
                if(row.Factor_Type__c === 'Dollars') {
                    amountDisplay = formatter.format(row.Amount__c);                
                }
                else {
                    amountDisplay += ' ' + row.Factor_Type__c;
                }
                let newRow = {...row , amountDisplay};
                return newRow;
            });

        }
        else if(result.error) {
            this.showSnackbar('failure','Error retrieving list',reduceErrors(error).join(', '));
        }
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        let retrievedItem = row;
        switch (action.name) {
            case 'edit':
                this.itemToUpdate = {
                    Id: row.Id,
                    Factor_Type__c: row.Factor_Type__c,
                    Item_Category__c: row.Item_Category__c,
                    Amount__c: row.Amount__c,
                    Staff_Role__c: row.Staff_Role__c
                };
                switch(row.Item_Category__c) {
                    case 'Mileage':
                        this.amountLabel = 'Miles';
                        break;
                    case 'Subsistence':
                        this.amountLabel = 'Days';
                        break;
                    default:
                        this.amountLabel = 'Dollars';
                        break;
                }        
                this.openModal();
                break;
            case 'delete':
                if(confirm('Delete this Budget Item?')) {
                    deleteRecord(retrievedItem.Id)
                    .then(() => {
                        this.showSnackbar('success','Success','Budget Item Deleted');
                        return refreshApex(this.wiredBudget);
                    })
                    .catch(error => {
                        this.showSnackbar('failure','Error deleting record',reduceErrors(error).join(', '));
                    });                    
                }
                break;
            default:
        }
    }

    openModal() {
        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
    }
    handleCategoryChange(e) {
        let newCategory = e.currentTarget.value;
        switch(newCategory) {
            case 'Mileage':
                this.amountLabel = 'Miles';
                break;
            case 'Subsistence':
                this.amountLabel = 'Days';
                break;
            default:
                this.amountLabel = 'Dollars';
                break;
        }
        this.itemToUpdate.Item_Category__c = newCategory;
        this.itemToUpdate.Factor_Type__c = this.amountLabel;
    }
    handleAmountChange(e) {
        this.itemToUpdate.Amount__c = e.currentTarget.value;
    }
    handleRoleChange(e) {
        this.itemToUpdate.Staff_Role__c = e.currentTarget.value;
    }
    saveAndClose() {
        this.saveItem(false);
        if(this.saveSuccessful) {
            this.closeModal();
        }
    }
    saveAndNew() {
        this.saveItem(true);
    }
    createNewItem(e) {
        e.preventDefault();
        this.createNewRecord();
        this.openModal();
    }
    createNewRecord() {
        this.itemToUpdate = {
            National_Outings_Trip__c: this.recordId,
            Budget_Category__c: 'Volunteer Travel',
            Factor_Type__c: 'Dollars',
            Item_Category__c: 'Airfare',
            Staff_Role__c: 'Leader'
        };
    }
    saveItem(createNew) {
        this.saveSuccessful = true;
        if( ! this.itemToUpdate.Amount__c ) {
            this.saveSuccessful = false;
        }
        else if(this.itemToUpdate.Amount__c == 0) {
            this.saveSuccessful = false;
        }
        if( ! this.saveSuccessful ) {
            this.showSnackbar('failure','Unable to Save Budget Item','You must specify an amount');
            return;
        }
        if(this.itemToUpdate.Id) {
            updateRecord ({
                fields: this.itemToUpdate
            })
            .then(result => {
                this.message = result;
                this.error = undefined;
                this.saveSuccessful = true;
                if(createNew) {
                    this.createNewRecord();
                }
                this.showSnackbar('success','Budget Item Updated','Budget Item sucessfully updated');
                return refreshApex(this.wiredBudget);
            })
            .catch(error => {
                this.error = error;
                this.saveSuccessful = false;
                this.showSnackbar('failure','Update Failed',reduceErrors(error).join(', '));
            });
        } else {
            createRecord ({
                apiName: "National_Outings_Trip_Budget_Item__c",
                fields: this.itemToUpdate
            })
            .then(result => {
                this.message = result;
                this.error = undefined;
                this.saveSuccessful = true;
                if(createNew) {
                    this.createNewRecord();
                }
                this.showSnackbar('success','Budget Item Added','Budget Item successfully added');
                return refreshApex(this.wiredBudget);
            })
            .catch(error => {
                this.error = error;
                this.saveSuccessful = false;
                this.showSnackbar('failure','Error Creating Budget Item',reduceErrors(error).join(', '));
            });
        }
    }
    get isCurrency() {
        return (this.amountLabel === 'Dollars');
    }
    get showBudgetList() {
        return this.budgetList.length > 0;
    }
    get columns() {
        let cols = columns;
        if(this.canEdit) {
            let lastIdx = cols.length - 1;
            if(typeof cols[lastIdx]['type'] === 'undefined') {
                cols.push({ type: 'action', typeAttributes: { rowActions: actions } });
            }
        }
        return cols;
    }
    showSnackbar(type, header, text) {
        this.template.querySelector('c-snackbar').show(type, header, text);
    }
    @api getRowCount() {
        return this.budgetList.length;
    }
}