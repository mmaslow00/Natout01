import { LightningElement, api, wire, track } from 'lwc';
import getVolTravelList from '@salesforce/apex/NatoutTripBudgetController.getTransportationList';
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
    { label: 'Option', fieldName: 'Option__c', hideDefaultActions: true, wrapText: true},
    { label: 'Category', fieldName: 'Item_Category__c', hideDefaultActions: true, wrapText: true},
    { label: 'Amount', fieldName: 'Amount__c', type: 'currency', hideDefaultActions: true, wrapText: true }
];

const tripCategories = [
    {label: 'Boat', value: 'Boat'},
    {label: 'Bus', value: 'Bus'},
    {label: 'Charter Aircraft', value: 'Charter Aircraft'},
    {label: 'Mileage', value: 'Mileage'},
    {label: 'Shuttle', value: 'Shuttle'},
    {label: 'Taxi', value: 'Taxi'},
    {label: 'Train', value: 'Train'},
    {label: 'Vehicle Rental', value: 'Vehicle Rental'},
];

const staffPartCategories = [
    {label: 'Boat', value: 'Boat'},
    {label: 'Bus', value: 'Bus'},
    {label: 'Charter Aircraft', value: 'Charter Aircraft'},
    {label: 'Shuttle', value: 'Shuttle'},
    {label: 'Taxi', value: 'Taxi'},
    {label: 'Train', value: 'Train'},
];

const options = [
    {label: 'Trip', value: 'Trip'},
    {label: 'Participants', value: 'Participants'},
    {label: 'Staff', value: 'Staff'}
];

export default class NatoutTripBudgetTransportation extends LightningElement {
    tripCategories = tripCategories;
    staffPartCategories = staffPartCategories;
    options = options;
    @api recordId = '';
    @api canEdit = false;
    @track budgetList=[];
    @track itemToUpdate = {};
    @track isModalOpen = false;
    wiredBudget
    saveSuccessful;

    @wire(getVolTravelList, {tripId: '$recordId'})
    wiredBudgetList(result) {
        if(result.data) {
            this.wiredBudget = result;
            this.budgetList = result.data;
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
                    Option__c: row.Option__c,
                    Item_Category__c: row.Item_Category__c,
                    Amount__c: row.Amount__c
                };
                this.openModal();
                break;
            case 'delete':
                // eslint-disable-next-line no-alert
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
    handleOptionChange(e) {
        this.itemToUpdate.Option__c = e.currentTarget.value;
    }
    handleAmountChange(e) {
        this.itemToUpdate.Amount__c = e.currentTarget.value;
    }
    handleCategoryChange(e) {
        this.itemToUpdate.Item_Category__c = e.currentTarget.value;
    }
    createNewItem(e) {
        e.preventDefault();
        this.createNewRecord();
        this.openModal();
    }
    createNewRecord() {
        this.itemToUpdate = {
            National_Outings_Trip__c: this.recordId,
            Budget_Category__c: 'Transportation',
            Option__c: 'Trip'
        };
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
    saveItem(createNew) {
        this.saveSuccessful = true;
        const allValid = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
            return validSoFar && inputCmp.reportValidity();
            }, true);
        if(! allValid) {
            this.saveSuccessful = false;
            this.showSnackbar('failure','Failed to Save Item','Please enter all required fields');
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
                this.showSnackbar('success','Buddget Item Updated','Budget Item successfully updated');
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
                this.showSnackbar('failure','Update Failed',reduceErrors(error).join(', '));
            });
        }
    }
    get showBudgetList() {
        return this.budgetList.length > 0;
    }
    get categoriesToShow() {
        if(this.itemToUpdate.Option__c === 'Trip') {
            return this.tripCategories;
        }
        return this.staffPartCategories;
    }
    get columns() {
        let cols = columns;
        if(this.canEdit) {
            let lastIdx = cols.length - 1;
            if(typeof cols[lastIdx]['typeAttributes'] === 'undefined') {
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