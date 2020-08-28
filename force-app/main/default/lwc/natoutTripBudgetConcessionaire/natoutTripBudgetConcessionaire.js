import { LightningElement, api, wire, track } from 'lwc';
import getConcessionaireList from '@salesforce/apex/NatoutTripBudgetController.getConcessionaireList';
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
    { label: 'Amount', fieldName: 'Amount__c', type: 'currency', hideDefaultActions: true, wrapText: true },
    { label: 'Staff', fieldName: 'Number_Staff__c', type: 'number', hideDefaultActions: true, wrapText: true }
];

const staffPartCategories = [
    {label: 'Admissions', value: 'Admissions'},
    {label: 'Concessionaire', value: 'Concessionaire'},
    {label: 'Guides', value: 'Guides'},
    {label: 'Gratuities', value: 'Gratuities'},
    {label: 'Lodging/Hotel', value: 'Lodging/Hotel'},
    {label: 'Other', value: 'Other'},
    {label: 'Rentals', value: 'Rentals'},
];

const options = [
    {label: 'Trip', value: 'Trip'},
    {label: 'Participants', value: 'Participants'},
    {label: 'Staff', value: 'Staff'}
];

export default class NatoutTripBudgetTransportation extends LightningElement {
    staffPartCategories = staffPartCategories;
    options = options;
    @api recordId = '';
    @api tripIsInternational = false;
    @api numStaff = 0;
    @api canEdit = false
    @track budgetList=[];
    @track itemToUpdate = {};
    @track isModalOpen = false;
    wiredBudget
    saveSuccessful;

    @wire(getConcessionaireList, {tripId: '$recordId'})
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
                    Amount__c: row.Amount__c,
                    Number_Staff__c: row.Number_Staff__c
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
    handleNumStaffChange(e) {
        this.itemToUpdate.Number_Staff__c = e.currentTarget.value;
    }
    createNewItem(e) {
        e.preventDefault();
        this.createNewRecord();
        this.openModal();
    }
    createNewRecord() {
        this.itemToUpdate = {
            National_Outings_Trip__c: this.recordId,
            Budget_Category__c: 'Concessionaires',
            Option__c: 'Trip',
            Number_Staff__c: this.numStaff
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
        if(this.itemToUpdate.Option__c != 'Staff') {
            this.itemToUpdate.Number_Staff__c = null;
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
                this.showSnackbar('success','Success','Budget Item successfully updated');
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
                this.showSnackbar('failure','Staff Update Failed',reduceErrors(error).join(', '));
            });
        }
    }
    get showBudgetList() {
        if(this.budgetList) {
            return this.budgetList.length > 0;
        }
        return false;
    }
    get categoriesToShow() {
        if(this.itemToUpdate.Option__c === 'Trip') {
            return this.tripCategories;
        }
        return this.staffPartCategories;
    }
    get listTitle() {
        let title = "Concessionaires";
        if(this.tripIsInternational) {
            title = "Concessionaires/Leader Planned Arrangements";
        }
        return title;
    }

    get tripCategories() {
        let categoryList = [
            {label: 'Admissions', value: 'Admissions'}
        ];
        if( ! this.tripIsInternational) {
            categoryList.push({label: 'Campground', value: 'Campground'});
            categoryList.push({label: 'Cook', value: 'Cook'});
        }
        categoryList.push({label: 'Concessionaire', value: 'Concessionaire'});
        categoryList.push({label: 'Guides', value: 'Guides'});
        categoryList.push({label: 'Gratuities', value: 'Gratuities'});
        categoryList.push({label: 'Lodging/Hotel', value: 'Lodging/Hotel'});
        categoryList.push({label: 'Other', value: 'Other'});
        if( ! this.tripIsInternational) {
            categoryList.push({label: 'Packer', value: 'Packer'});
        }
        categoryList.push({label: 'Instructor/Guest Speaker', value: 'Instructor/Guest Speaker'});
        categoryList.push({label: 'Rentals', value: 'Rentals'});
        categoryList.push({label: 'Single Supplement', value: 'Single Supplement'});
        
        return categoryList;
    }
    get staffOptionChosen() {
        return this.itemToUpdate.Option__c === 'Staff';
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