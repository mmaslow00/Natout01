import { LightningElement, api, wire, track } from 'lwc';
import getAgencyList from '@salesforce/apex/NatoutTripAgenciesController.getAgencyList';
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
    { label: 'Agency', fieldName: 'accountName'}
];

export default class NatoutTripAgencies extends LightningElement {
    @api recordId = '';
    @api canEdit = false;
    @track agencyList = [];
    @track isModalOpen = false;
    @track searchingAgencies = false;
    @track agencyToUpdate = {};
    wiredAgencies;

    @wire(getAgencyList, {tripId: '$recordId'})
    wiredAgencyList(result) {
        if (result.data) {
            this.wiredAgencies = result;
            this.agencyList = result.data.map(row => {
                let accountName = row.Account__r.Name;
                let newRow = {...row , accountName};
                return newRow;
            });
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.agencyList = undefined;
        }
    }

    @api getAgencyOptions() {
        let ret = [];
        for(let i=0; i < this.agencyList.length; i++) {
            ret.push({label: this.agencyList[i].accountName, value: this.agencyList[i].Account__c});
        }
        return ret;
    }
    @api getRowCount() {
        return this.agencyList.length;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        let retrievedAgency = row;
        switch (action.name) {
            case 'edit':
                this.agencyToUpdate = {
                    Id: retrievedAgency.Id,
                    Account__c: retrievedAgency.Account__c,
                    accountName: retrievedAgency.accountName
                };
                this.searchingContacts = false;
                this.openModal();
                break;
            case 'delete':
                // eslint-disable-next-line no-alert
                if(confirm('Delete this Agency?')) {
                    deleteRecord(retrievedAgency.Id)
                    .then(() => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Agency Deleted',
                                variant: 'success'
                            })
                        );
                        return refreshApex(this.wiredAgencies);
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
    searchAgencies() {
        this.searchingAgencies = true;
    }
    setAccount(e) {
        let selectedAccount = e.detail;
        if(selectedAccount.Id) {
            this.agencyToUpdate.Account__c = selectedAccount.Id;
            this.agencyToUpdate.accountName = selectedAccount.Name;
        }
        this.searchingAgencies = false; 
    }

    createNewAgency(e) {
        e.preventDefault();
        this.searchingAgencies = true;
        this.agencyToUpdate = {
            National_Outings_Trip__c: this.recordId,
        };
        this.openModal();
    }

    saveAgency() {
        let agencyRecord = {
            Id: this.agencyToUpdate.Id,
            National_Outings_Trip__c: this.agencyToUpdate.National_Outings_Trip__c,
            Account__c: this.agencyToUpdate.Account__c
        };
        if( ! agencyRecord.Account__c ) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Update Failed',
                    message: 'You must choose an Agency',
                    variant: 'error'
                }),
            );
            return;
        }

        if(agencyRecord.Id) {
            updateRecord ({
                    fields: {
                        Id: this.agencyToUpdate.Id,
                        Account__c: this.agencyToUpdate.Account__c,
                        National_Outings_Trip__c: this.agencyToUpdate.National_Outings_Trip__c
                    }
            })
            .then(result => {
                this.message = result;
                this.error = undefined;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Agency Updated',
                        message: 'Agency successfully updated',
                        variant: 'success',
                    }),
                );
                return refreshApex(this.wiredAgencies);
            })
            .catch(error => {
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
                apiName: "National_Outings_Trip_Agency__c",
                fields: {
                    Account__c: this.agencyToUpdate.Account__c,
                    National_Outings_Trip__c: this.agencyToUpdate.National_Outings_Trip__c
                }
            })
            .then(result => {
                this.message = result;
                this.error = undefined;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Agency Added',
                        message: 'Agency successfully added',
                        variant: 'success',
                    }),
                );
                return refreshApex(this.wiredAgencies);
            })
            .catch(error => {
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Update Failed',
                        message: reduceErrors(error).join(', '),
                        variant: 'error'
                    }),
                );
            });
        }
        this.closeModal();
    }
    get showAgencyList() {
        return this.agencyList.length > 0;
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