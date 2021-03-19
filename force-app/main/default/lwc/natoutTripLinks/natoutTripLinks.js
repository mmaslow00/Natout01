import { LightningElement, api, wire, track } from 'lwc';
import getTripLinks from '@salesforce/apex/NatoutTripLinksController.getLinkList';
import { createRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { reduceErrors } from 'c/ldsUtils';

export default class NatoutTripLinks extends LightningElement {
    @api recordId = '';
    @api tripIsInternational;
    @api canEdit = false;
    @track linkList = [];
    @track isModalOpen = false;
    wiredLinks;

    @wire(getTripLinks, {tripId: '$recordId'})
    wiredLinkList(result) {
        if(result.data) {
            this.wiredLinks = result;
            this.linkList = result.data;
            this.error = undefined;
        }
        else if(result.error) {
            this.error = result.error;
            this.linkList = undefined;
        }        
    }
    openModal() {
        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
    }
    get modalIsOpen() {
        return this.isModalOpen;
    }
    get columns() {
        const actions = [
            { label: 'Edit', name: 'edit' },
            { label: 'Delete', name: 'delete' }
        ];
        const columns = [
            { type: 'url', fieldName: 'Url__c', typeAttributes: {label: {fieldName: 'Description__c'}, target: '_blank'}}
        ];
        let cols = columns;
        if(this.canEdit) {
            if(cols.length === 1) {
                cols.push({ type: 'action', typeAttributes: { rowActions: actions } });
            }
        }
        return cols;
    }
    createNewLink(e) {
        e.preventDefault();
        this.itemToUpdate = {
            National_Outings_Trip__c : this.recordId,
            Url__c : '',
            Description__c : ''
        };
        this.openModal();
    }
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        let retrievedLink = row;
        switch (action.name) {
            case 'edit':
                this.itemToUpdate = {
                    Id: retrievedLink.Id,
                    Url__c: retrievedLink.Url__c,
                    Description__c: retrievedLink.Description__c
                };
                this.openModal();
                break;
            case 'delete':
                // eslint-disable-next-line no-alert
                if(confirm('Delete this Link?')) {
                    deleteRecord(retrievedLink.Id)
                    .then(() => {
                        this.showSnackbar('success','Success','Link Deleted');
                        return refreshApex(this.wiredLinks);
                    })
                    .catch(error => {
                        this.showSnackbar('failure','Error deleting record',reduceErrors(error).join(', '));
                    });                    
                }
                break;
            default:
        }
    }
    handleFieldChange(e) {
        let fieldName = e.currentTarget.dataset.field;
        this.itemToUpdate[fieldName] = e.target.value;
    }
    saveAndClose() {
        this.save();
        if(this.saveSuccessful) {
            this.closeModal();
        }
    }
    saveAndNew() {
        this.save();
        if(this.saveSuccessful) {
            this.itemToUpdate = {
                National_Outings_Trip__c : this.recordId,
                Url__c : '',
                Description__c : ''
            };
        }
        this.template.querySelector('[data-field=Url__c]').value = '';
        this.template.querySelector('[data-field=Description__c]').value = '';
    }
    save() {
        this.saveSuccessful = true;
        const allValid = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
            return validSoFar && inputCmp.reportValidity();
            }, true);
        if(! allValid) {
            this.saveSuccessful = false;
            return;
        }
        if(this.itemToUpdate.Id) {
            updateRecord ({
                fields: this.itemToUpdate
                }
            )
            .then(result => {
                this.message = result;
                this.error = undefined;
                this.showSnackbar('success','Link Updated','Link successfully updated');
                return refreshApex(this.wiredLinks);
            })
            .catch(error => {
                this.error = error;
                this.showSnackbar('failure','Update Failed',reduceErrors(error).join(', '));
            });
        } else {
            createRecord ({
                apiName: "National_Outings_Trip_Link__c",
                fields: this.itemToUpdate
            })
            .then(result => {
                this.message = result;
                this.error = undefined;
                this.showSnackbar('success','Link Added','Link successfully added');
                return refreshApex(this.wiredLinks);
            })
            .catch(error => {
                this.error = error;
                this.showSnackbar('failure','Update Failed',reduceErrors(error).join(', '));
            });
        }
    }
    showSnackbar(type, header, text) {
        this.template.querySelector('c-snackbar').show(type, header, text);
    }
}