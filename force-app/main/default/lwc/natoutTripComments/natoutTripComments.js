import { LightningElement, api, wire, track } from 'lwc';
import getCommentsList from '@salesforce/apex/NatoutTripCommentsController.getCommentsList';
import { createRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { reduceErrors } from 'c/ldsUtils';

export default class NatoutTripComments extends LightningElement {
    @api recordId = '';
    @api canEdit = false;
    @track commentsList = [];
    @track modalOpen = false;

    constructor() {
        super();
        this.checkboxOptions = [
            {label: 'Leader and any collborators they appoint', value: 'Leaders'},
            {label: 'Subcommittee officers and any collaborators they appoint', value: 'Officers'},
            {label: 'National Outings staff', value: 'Staff'}
        ];
        this.checkboxValues = [];
    }
  
    @wire(getCommentsList, {tripId: '$recordId'})
    wiredCommentsList(result) {
        if (result.data) {

            this.commentsList = result.data.map(row => {
                let submitter = row.CreatedBy.Name;
                let newRow = {...row , submitter};
                return newRow;
            });

            this.wiredComments = result;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.collabList = undefined;
        }
    }
    handleChange(e) {
        this.tripComment = e.target.value;
    }
    handleCheckboxChange(e) {
        this.checkboxValues = e.detail.value;
    }
    get isModalOpen() {
        return this.modalOpen;
    }
    closeModal() {
        this.modalOpen = false;
    }
    openModal() {
        this.modalOpen = true;
    }
    saveComment() {
        const allValid = [...this.template.querySelectorAll('lightning-textarea')]
        .reduce((validSoFar, inputCmp) => {
            return validSoFar && inputCmp.reportValidity();
            }, true);
        if(allValid) {
            createRecord({
                apiName: 'National_Outings_Trip_Comments__c',
                fields: {
                    National_Outings_Trip__c: this.recordId,
                    Comments__c: this.tripComment,
                    Notify_Approvers__c: (this.checkboxValues.indexOf('Officers') >= 0),
                    Notify_Creators__c: (this.checkboxValues.indexOf('Leaders') >= 0),
                    Notify_Staff__c: (this.checkboxValues.indexOf('Staff') >= 0)
                }
            }).then(result => {
                this.showSnackbar('success', 'Comment Saved');
                this.modalOpen = false;
                this.checkboxValues = [];
                return refreshApex(this.wiredComments);
            })
            .catch(error => {
                this.error = error;
                this.modalOpen = false;
                this.showSnackbar('failure', 'Failed to Save Comment',reduceErrors(error).join(', '))
            });
        }
    }
    @api createNewComment() {
        this.modalOpen = true;
    }
    showSnackbar(type, header, text) {
        this.template.querySelector('c-snackbar').show(type, header, text);
    }
}