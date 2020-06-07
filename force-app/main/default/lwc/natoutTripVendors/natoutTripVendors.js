import { LightningElement, api, wire, track } from 'lwc';
import getVendorList from '@salesforce/apex/NatoutTripVendorsController.getVendorList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { reduceErrors } from 'c/ldsUtils';
import getVendorOptions from '@salesforce/apex/NatoutTripOptions.getVendorOptions';


const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];
const columns = [
    { label: 'Vendor', fieldName: 'accountName'},
    { label: 'Type', fieldName: 'Type__c'}
];

export default class NatoutTripVendors extends LightningElement {
    @api recordId = '';
    @api tripIsInternational;
    @api canEdit = false;
    @track vendorList = [];
    @track isModalOpen = false;
    @track searchingVendors = false;
    @track vendorToUpdate = {};
    wiredVendors;
    saveSuccessful;
    optionsList = null;

    @wire(getVendorOptions)
    vendorOptions;

    @wire(getVendorList, {tripId: '$recordId'})
    wiredVendorList(result) {
        if (result.data) {
            this.wiredVendors = result;
            this.vendorList = result.data.map(row => {
                let accountName = row.Account__r.Name;
                let newRow = {...row , accountName};
                return newRow;
            });
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.vendorList = undefined;
        }
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        let retrievedVendor = row;
        switch (action.name) {
            case 'edit':
                this.vendorToUpdate = {
                    Id: retrievedVendor.Id,
                    Type__c: retrievedVendor.Type__c,
                    Account__c: retrievedVendor.Account__c,
                    accountName: retrievedVendor.accountName
                };
                this.searchingVendors = false;
                this.openModal();
                break;
            case 'delete':
                // eslint-disable-next-line no-alert
                if(confirm('Delete this Vendor?')) {
                    deleteRecord(retrievedVendor.Id)
                    .then(() => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Vendor Deleted',
                                variant: 'success'
                            })
                        );
                        return refreshApex(this.wiredVendors);
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
    openModal() {
        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
    }
    searchVendors() {
        this.searchingVendors = true;
    }
    setAccount(e) {
        let selectedAccount = e.detail;
        if(selectedAccount.Id) {
            this.vendorToUpdate.Account__c = selectedAccount.Id;
            this.vendorToUpdate.accountName = selectedAccount.Name;
        }
        this.searchingVendors = false; 
    }
    setVendorType(e) {
        this.vendorToUpdate.Type__c = e.target.value;
    }
    saveAndClose() {
        this.saveVendor(false);
        if(this.saveSuccessful) {
            this.closeModal();
        }
    }
    saveAndNew() {
        this.saveVendor(true);
    }
    createNewVendor(e) {
        e.preventDefault();
        this.searchingVendors = true;
        this.createNewRecord();
        this.openModal();
    }
    createNewRecord() {
        this.vendorToUpdate = {
            Id: null,
            National_Outings_Trip__c: this.recordId
        };
        this.searchingVendors = true;
    }

    saveVendor(createNew) {
        this.saveSuccessful = true;
        const allValid = [...this.template.querySelectorAll('lightning-combobox')]
        .reduce((validSoFar, inputCmp) => {
            return validSoFar && inputCmp.reportValidity();
            }, true);
        if(! allValid) {
            this.saveSuccessful = false;
            return;
        }

        let vendorRecord = {
            Id: this.vendorToUpdate.Id,
            National_Outings_Trip__c: this.vendorToUpdate.National_Outings_Trip__c,
            Type__c: this.vendorToUpdate.Type__c,
            Account__c: this.vendorToUpdate.Account__c
        };
        if( ! vendorRecord.Account__c ) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Update Failed',
                    message: 'You must choose a Vendor',
                    variant: 'error'
                }),
            );
            this.saveSuccessful = false;
            return;
        }

        if(vendorRecord.Id) {
            updateRecord ({
                    fields: {
                        Id: this.vendorToUpdate.Id,
                        Account__c: this.vendorToUpdate.Account__c,
                        National_Outings_Trip__c: this.vendorToUpdate.National_Outings_Trip__c,
                        Type__c: this.vendorToUpdate.Type__c
                    }
            })
            .then(result => {
                this.message = result;
                this.error = undefined;
                this.saveSuccessful = true;
                if(createNew) {
                    this.createNewRecord();
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Vendor Updated',
                        message: 'Vendor successfully updated',
                        variant: 'success',
                    }),
                );
                return refreshApex(this.wiredVendors);
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
        } else {
            createRecord ({
                apiName: "National_Outings_Trip_Vendor__c",
                fields: {
                    Account__c: this.vendorToUpdate.Account__c,
                    National_Outings_Trip__c: this.vendorToUpdate.National_Outings_Trip__c,
                    Type__c: this.vendorToUpdate.Type__c
                }
            })
            .then(result => {
                this.message = result;
                this.error = undefined;
                this.saveSuccessful = true;
                if(createNew) {
                    this.createNewRecord();
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Vendor Added',
                        message: 'Vendor successfully added',
                        variant: 'success',
                    }),
                );
                return refreshApex(this.wiredVendors);
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
    get showVendorList() {
        return this.vendorList.length > 0;
    }
    get typeOptionsList() {
        if(this.optionsList == null) {
            if(this.vendorOptions) {
                let opts = [];
                if(this.tripIsInternational) {
                    opts = this.vendorOptions.data.internationalList;
                }
                else {
                    opts = this.vendorOptions.data.domesticList;
                }
                this.optionsList = [];
                for(let i=0; i < opts.length; i++) {
                    this.optionsList.push({label: opts[i], value: opts[i]});
                }
            }
        }
        return this.optionsList;
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
}