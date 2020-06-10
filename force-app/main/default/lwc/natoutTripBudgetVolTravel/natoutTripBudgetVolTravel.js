import { LightningElement, api, wire, track } from 'lwc';
import getVolTravelList from '@salesforce/apex/NatoutTripBudgetController.getVolTravelList';
//import { ShowToastEvent } from 'lightning/platformShowToastEvent';
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
    { label: 'Category', fieldName: 'Item_Category__c' },
    { label: 'Amount', fieldName: 'amountDisplay'},
    { label: 'Role', fieldName: 'Staff_Role__c' }
];

const itemCategories = [
    { label: 'Airfare', value: 'Airfare'},
    { label: 'Mileage', value: 'Mileage'},
    { label: 'Other - Volunteer', value: 'Other - Volunteer'},
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
            /*
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error retrieving list',
                    message: reduceErrors(error).join(', '),
                    variant: 'error'
                })
            );
            */
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
                        /*
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Budget Item Deleted',
                                variant: 'success'
                            })
                        );
                        */
                        return refreshApex(this.wiredBudget);
                    })
                    .catch(error => {
                        this.showSnackbar('failure','Error deleting record',reduceErrors(error).join(', '));
                        /*
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error deleting record',
                                message: reduceErrors(error).join(', '),
                                variant: 'error'
                            })
                        );
                        */
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
            /*
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Unable to Save Budget Item',
                    message: 'You must specify an amount',
                    variant: 'error'
                }),
            );
            */
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
                /*
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Budget Item Updated',
                        message: 'Budget Item successfully updated',
                        variant: 'success',
                    }),
                );
                */
                return refreshApex(this.wiredBudget);
            })
            .catch(error => {
                this.error = error;
                this.saveSuccessful = false;
                this.showSnackbar('failure','Update Failed',reduceErrors(error).join(', '));
                /*
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Update Failed',
                        message: reduceErrors(error).join(', '),
                        variant: 'error'
                    }),
                );
                */
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
                /*
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Budget Item Added',
                        message: 'Budget Item successfully added',
                        variant: 'success',
                    }),
                );
                */
                return refreshApex(this.wiredBudget);
            })
            .catch(error => {
                this.error = error;
                this.saveSuccessful = false;
                this.showSnackbar('failure','Error Creating Budget Item',reduceErrors(error).join(', '));
                /*
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Staff Update Failed',
                        message: reduceErrors(error).join(', '),
                        variant: 'error'
                    }),
                );
                */
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