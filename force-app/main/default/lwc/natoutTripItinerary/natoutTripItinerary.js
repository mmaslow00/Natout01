import { LightningElement, api, wire, track } from 'lwc';
import getItineraryList from '@salesforce/apex/NatoutTripItineraryController.getItineraryList';
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
        type: "number",
        initialWidth: 60
    },
    {   
        label: 'Camp/Lodge', 
        fieldName: 'Camp_Lodge_Location__c'
    },
    {   
        label: 'Agency', 
        fieldName: 'agencyName'
    }
];
export default class NatoutTripItinerary extends LightningElement {
    @api recordId = '';
    @api tripStartDate;
    @api tripEndDate;
    @api agencyOptions;
    @api canEdit = false;
    @track itineraryList=[];
    @track isModalOpen = false;
    @track itemToUpdate = {};
    tripDates=null;
    wiredItinerary;
    editMode=false;
     
    @wire(getItineraryList, {tripId: '$recordId'})
    wiredItineraryList(result) {
        if(result.data) {
            this.wiredItinerary = result;
            this.itineraryList = result.data;
            this.itineraryList = result.data.map(row => {
                let agencyName = row.Land_Agency__r ? row.Land_Agency__r.Name : 'None';
                let newRow = {...row , agencyName};
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
                    Day_Number__c: row.Day_Number__c,
                    Camp_Lodge_Location__c: row.Camp_Lodge_Location__c,
                    Land_Agency__c: row.Land_Agency__c ? row.Land_Agency__c : 'None',
                    Trails_Used__c: row.Trails_Used__c,
                    itineraryDate: this.tripDates[row.Day_Number__c - 1]
                };
                this.editMode = true;
                this.openModal();
                break;
            case 'delete':
                // eslint-disable-next-line no-alert
                if(confirm('Delete this Day?')) {
                    deleteRecord(retrievedItem.Id)
                    .then(() => {
                        this.showSnackbar('success','Success','Item Deleted');
                        return refreshApex(this.wiredItinerary);
                    })
                    .catch(error => {
                        this.showSnackbar('failure','Error deleting record',reduceErrors(error).join(', '));
                    });                    
                }
                break;
            default:
        }
    }
    get allDatesEntered() {
        return this.itineraryList.length === this.tripDates.length;
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
        let landAgency = this.agencyOptions[0].value;
        this.itemToUpdate = {
            National_Outings_Trip__c: this.recordId,
            Day_Number__c: ++nextDayIndex,
            Land_Agency__c: landAgency,
            itineraryDate: nextDate
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
            this.showSnackbar('failure','Failed to Save Item','Please enter all required fields');
            this.saveSuccessful = false;
        }
        if(this.saveSuccessful) {
            if(this.itemToUpdate.Id) {
                updateRecord ({
                    fields: {
                        Id: this.itemToUpdate.Id,
                        Day_Number__c: this.itemToUpdate.Day_Number__c,
                        Camp_Lodge_Location__c: this.itemToUpdate.Camp_Lodge_Location__c,
                        Land_Agency__c: this.itemToUpdate.Land_Agency__c === 'None' ? null : this.itemToUpdate.Land_Agency__c,
                        Trails_Used__c: this.itemToUpdate.Trails_Used__c
                    }
                })
                .then(result => {
                    this.message = result;
                    this.error = undefined;
                    if(createNew) {
                        this.createNextDay();
                    }
                    this.showSnackbar('success','Item Updated','Item successfully updated');
                    return refreshApex(this.wiredItinerary);
                })
                .catch(error => {
                    this.saveSuccessful = false;
                    this.error = error;
                    this.showSnackbar('failure','Update Failed',reduceErrors(error).join(', '));
                });
            } else {
                createRecord ({
                    apiName: "National_Outings_Trip_Itinerary__c",
                    fields: {
                        National_Outings_Trip__c: this.recordId,
                        Day_Number__c: this.itemToUpdate.Day_Number__c,
                        Camp_Lodge_Location__c: this.itemToUpdate.Camp_Lodge_Location__c,
                        Land_Agency__c: this.itemToUpdate.Land_Agency__c === 'None' ? null : this.itemToUpdate.Land_Agency__c,
                        Trails_Used__c: this.itemToUpdate.Trails_Used__c
                    }
                })
                .then(result => {
                    this.message = result;
                    this.error = undefined;
                    if(createNew) {
                        this.createNextDay();
                    }
                    this.showSnackbar('success','Item Added','Item successfully added');
                    return refreshApex(this.wiredItinerary);
                })
                .catch(error => {
                    this.error = error;
                    this.saveSuccessful = false;
                    this.showSnackbar('failure','Update Failed',reduceErrors(error).join(', '));
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
        let tripDateArray = this.getTripDates();
        let dayNumArray = [];
        for(let i=0; i < this.itineraryList.length; i++) {
            dayNumArray.push(this.itineraryList[i].Day_Number__c - 1);
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
        let nextDayIndex = this.getNextDayIndex(this.itemToUpdate.Day_Number__c) + 1;
        let nextDate = this.getTripDates()[nextDayIndex];
        this.itemToUpdate = {
            National_Outings_Trip__c: this.recordId,
            Day_Number__c: nextDayIndex + 1,
            Camp_Lodge_Location__c: this.itemToUpdate.Camp_Lodge_Location__c,
            Land_Agency__c: this.itemToUpdate.Land_Agency__c,
            Trails_Used__c: this.itemToUpdate.Trails_Used__c,
            itineraryDate: nextDate
        };
    }

    get showNewButton() {
        let retVal = true;
        let dateArray = this.getTripDates();
        if(dateArray != null && this.itineraryList.length > 0) {
            if(this.itineraryList.length >= this.getTripDates().length) {
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
        if(dateArray != null && this.itineraryList.length > 0) {
            if(this.itineraryList.length >= (this.getTripDates().length - 1)) {
                retVal = false;
            }
        }
        return retVal;
    }
    get showItineraryList() {
        return this.itineraryList.length > 0;
    }
    get currentItineraryDate() {
        if(this.itemToUpdate) {
            return this.itemToUpdate.itineraryDate;
        }
        return null;
    }
    get agencyDisplayOptions() {
        let ret = [];
        if(this.agencyOptions != null) {
            ret = this.agencyOptions;
        }
        return ret;
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
        return this.itineraryList.length;
    }
}