import { LightningElement, api, wire, track } from 'lwc';
import getCollaboratorList from '@salesforce/apex/NatoutTripCollaboratorController.getCollaboratorList';
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
    { label: 'Leader', fieldName: 'contactName'},
    { label: 'Access', fieldName: 'Access__c'}
];

export default class NatoutTripCollaborators extends LightningElement {
    @api recordId = '';
    @api canEdit = false;
    @api canApprove = false;
    @track collabList = [];
    @track isModalOpen = false;
    @track searchingCollabs = false;
    @track collabToUpdate = {};
    wiredCollabs;

    @wire(getCollaboratorList, {tripId: '$recordId'})
    wiredcollabList(result) {
        if (result.data) {
            this.wiredCollabs = result;
            this.collabList = result.data.map(row => {
                let contactName = row.Contact__r.Name;
                let newRow = {...row , contactName};
                return newRow;
            });
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.collabList = undefined;
        }
    }
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        let retrievedCollab = row;
        switch (action.name) {
            case 'edit':
                this.collabToUpdate = {
                    Id: retrievedCollab.Id,
                    Contact__c: retrievedCollab.Contact__c,
                    contactName: retrievedCollab.contactName,
                    Access__c: retrievedCollab.Access__c
                };
                this.searchingContacts = false;
                this.openModal();
                break;
            case 'delete':
                // eslint-disable-next-line no-alert
                if(confirm('Delete this Collaborator?')) {
                    deleteRecord(retrievedCollab.Id)
                    .then(() => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Collaborator Deleted',
                                variant: 'success'
                            })
                        );
                        return refreshApex(this.wiredCollabs);
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
    searchCollabs() {
        this.searchingCollabs = true;
    }
    setContact(e) {
        let selectedContact = e.detail;
        if(selectedContact.contactId) {
            this.collabToUpdate.Contact__c = selectedContact.contactId;
            this.collabToUpdate.contactName = selectedContact.firstName + ' ' + selectedContact.lastName;
        }
        this.searchingCollabs = false; 
    }

    createNewCollab(e) {
        e.preventDefault();
        this.searchingCollabs = true;
        this.collabToUpdate = {
            National_Outings_Trip__c: this.recordId,
            Access__c: 'Edit'
        };
        this.openModal();
    }

    handleAccessChange(e) {
        this.collabToUpdate.Access__c = e.target.value;
    }
    saveCollab() {
        if( ! this.collabToUpdate.Contact__c ) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Update Failed',
                    message: 'You must choose a Collaborator',
                    variant: 'error'
                }),
            );
            return;
        }

        if(this.collabToUpdate.Id) {
            updateRecord ({
                fields: {
                    Id: this.collabToUpdate.Id,
                    Contact__c: this.collabToUpdate.Contact__c,
                    Access__c: this.collabToUpdate.Access__c
                }
            })
            .then(result => {
                this.message = result;
                this.error = undefined;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Collaborator Updated',
                        message: 'Collaborator successfully updated',
                        variant: 'success',
                    }),
                );
                return refreshApex(this.wiredCollabs);
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
                apiName: "National_Outings_Trip_Collaborator__c",
                fields: {
                    Contact__c: this.collabToUpdate.Contact__c,
                    Access__c: this.collabToUpdate.Access__c,
                    National_Outings_Trip__c: this.recordId
                }
            })
            .then(result => {
                this.message = result;
                this.error = undefined;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Collaborator Added',
                        message: 'Collaborator successfully added',
                        variant: 'success',
                    }),
                );
                return refreshApex(this.wiredCollabs);
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
    get showCollabList() {
        return this.collabList.length > 0;
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
    get approvalAccess() {
        return this.canApprove;
    }
    get allowUknown() {
        return false;
    }
    get accessOptions() {
        return [
            {label: 'Edit', value: 'Edit'},
            {label: 'Approve', value: 'Approve'}
        ];
    }
}