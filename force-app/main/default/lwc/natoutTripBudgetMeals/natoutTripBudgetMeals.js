import { LightningElement, api, wire, track } from 'lwc';
import getMealsList from '@salesforce/apex/NatoutTripBudgetController.getMealsList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
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
    {   
        label: 'Day', 
        fieldName: 'Day_Number__c',
        type: 'number',
        initialWidth: 60
    },
    { 
        label: 'Number of Staff', 
        fieldName: 'Number_Staff__c',
        type: 'number'
    },
    { 
        label: 'Participant Amount', 
        fieldName: 'Participant_Amount__c',
        type: 'currency'
    },
    { 
        label: 'Staff Amount', 
        fieldName: 'Staff_Amount__c',
        type: 'currency'
    }
];

const formatter = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2
  });

export default class NatoutTripBudgetMeals extends LightningElement {
    @api recordId = '';
    @api tripStartDate;
    @api tripEndDate;
    @api numStaff;
    @api canEdit = false;
    @track budgetList=[];
    @track isModalOpen = false;
    @track itemToUpdate = {};
    tripDates=null;
    wiredBudget;
    dateStart;
    dateEnd;
    days = [];
    saveSuccessful;
    editMode = false;

    @wire(getMealsList, {tripId: '$recordId'})
    wiredBudgetList(result) {
        if(result.data) {
            this.wiredBudget = result;
            this.budgetList = result.data;
        }
        else if(result.error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error retrieving list',
                    message: reduceErrors(error).join(', '),
                    variant: 'error'
                })
            );
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
                    Day_Number__c: row.Day_Number__c,
                    Number_Staff__c: row.Number_Staff__c,
                    Participant_Amount__c: row.Participant_Amount__c,
                    Staff_Amount__c: row.Staff_Amount__c,
                    mealsDate: this.tripDates[row.Day_Number__c - 1]
                };
                this.editMode = true;
                this.openModal();
                break;
            case 'delete':
                // eslint-disable-next-line no-alert
                if(confirm('Delete this Budget Item?')) {
                    deleteRecord(retrievedItem.Id)
                    .then(() => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Budget Item Deleted',
                                variant: 'success'
                            })
                        );
                        return refreshApex(this.wiredBudget);
                    })
                    .catch(error => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error deleting record',
                                message: reduceErrors(error).join(', '),
                                variant: 'error'
                            })
                        );
                    });                    
                }
                break;
            default:
        }
    }
    get allDatesEntered() {
        return budgetList.length === this.tripDates.length;
    }

    handleFieldChange(e) {
        let fieldName = e.currentTarget.dataset.field;
        this.itemToUpdate[fieldName] = e.target.value;
    }
    getTripDates() {
        if(this.tripDates === null && this.tripStartDate && this.tripEndDate) {
            this.tripDates = [];
            let nextDate = new Date(this.tripStartDate);
            let lastDate = new Date(this.tripEndDate);
            while(nextDate <= lastDate) {
                let dateString = nextDate.toISOString(nextDate).substring(0,10);
                this.tripDates.push(dateString);
                nextDate.setDate(nextDate.getDate() + 1);
            }
        }
        return this.tripDates;
    }
    createNewItem(e) {
        e.preventDefault();
        let nextDayIndex = this.getNextDayIndex();
        let nextDate = this.getTripDates()[nextDayIndex];
        this.itemToUpdate = {
            National_Outings_Trip__c: this.recordId,
            Budget_Category__c: 'Meals',
            Day_Number__c: ++nextDayIndex,
            Number_Staff__c: this.numStaff,
            mealsDate: nextDate
        };
        this.editMode = false;
        this.openModal();
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
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Failed to Save Item',
                    message: 'Please enter all required fields',
                    variant: 'error'
                })
            );
            this.saveSuccessful = false;
        }
        if(this.saveSuccessful) {
            if(this.itemToUpdate.Id) {
                updateRecord ({
                    fields : {
                        Id: this.itemToUpdate.Id,
                        Day_Number__c: this.itemToUpdate.Day_Number__c,
                        Number_Staff__c: this.itemToUpdate.Number_Staff__c,
                        Participant_Amount__c: this.itemToUpdate.Participant_Amount__c,
                        Staff_Amount__c: this.itemToUpdate.Staff_Amount__c
                    }
                })
                .then(result => {
                    this.message = result;
                    this.error = undefined;
                    if(createNew) {
                        this.createNextDay();
                    }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Budget Item Updated',
                            message: 'Budget Item successfully updated',
                            variant: 'success',
                        }),
                    );
                    return refreshApex(this.wiredBudget);
                })
                .catch(error => {
                    this.saveSuccessful = false;
                    this.error = error;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Update Failed',
                            message: reduceErrors(error).join(', '),
                            variant: 'error'
                        }),
                    );
                });
            } else {
                createRecord ({
                    apiName: "National_Outings_Trip_Budget_Item__c",
                    fields : {
                        National_Outings_Trip__c: this.itemToUpdate.National_Outings_Trip__c,
                        Budget_Category__c: this.itemToUpdate.Budget_Category__c,
                        Day_Number__c: this.itemToUpdate.Day_Number__c,
                        Number_Staff__c: this.itemToUpdate.Number_Staff__c,
                        Participant_Amount__c: this.itemToUpdate.Participant_Amount__c,
                        Staff_Amount__c: this.itemToUpdate.Staff_Amount__c
                    }
                })
                .then(result => {
                    this.message = result;
                    this.error = undefined;
                    if(createNew) {
                        this.createNextDay();
                    }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Budget Item Added',
                            message: 'Budget Item successfully added',
                            variant: 'success',
                        }),
                    );
                    return refreshApex(this.wiredBudget);
                })
                .catch(error => {
                    this.error = error;
                    this.saveSuccessful = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Update Failed',
                            message: reduceErrors(error).join(', '),
                            variant: 'error'
                        }),
                    );
                });
            }
        }
    }
    openModal() {
        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
    }
    getNextDayIndex(lastDay) {
        let dayNumArray = [];
        for(let i=0; i < this.budgetList.length; i++) {
            dayNumArray.push(this.budgetList[i].Day_Number__c - 1);
        }
        if(lastDay != null) {
            dayNumArray.push(lastDay);
        }
        let idx = 0;
        while(dayNumArray.includes(idx)) {
            idx++;
        }
        return idx;
    }
    createNextDay() {
        let partAmt = this.itemToUpdate.Participant_Amount__c;
        let staffAmt = this.itemToUpdate.Staff_Amount__c;
        let nextDayIndex = this.getNextDayIndex(this.itemToUpdate.Day_Number__c) + 1;
        let nextDate = this.getTripDates()[nextDayIndex];
        this.itemToUpdate = {
            National_Outings_Trip__c: this.recordId,
            Budget_Category__c: 'Meals',
            Day_Number__c: nextDayIndex + 1,
            Number_Staff__c: this.numStaff,
            Participant_Amount__c: partAmt,
            Staff_Amount__c: staffAmt,
            mealsDate: nextDate
        };
    }  
    get showNewButton() {
        let retVal = true;
        let dateArray = this.getTripDates();
        if(dateArray != null && this.budgetList.length > 0) {
            if(this.budgetList.length >= this.getTripDates().length) {
                retVal = false;
            }
        }
        return retVal;
    }
    get showSaveAndNewButton() {
        if(this.editMode) {
            return false;
        }
        let retVal = true;
        let dateArray = this.getTripDates();
        if(dateArray != null && this.budgetList.length > 0) {
            if(this.budgetList.length >= (this.getTripDates().length - 1)) {
                retVal = false;
            }
        }
        return retVal;
    }
    get showBudgetList() {
        return this.budgetList.length > 0;
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
    @api getRowCount() {
        return this.budgetList.length;
    }
}