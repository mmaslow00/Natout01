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
        this.volunteerOptions = [
            {label: 'Trip Leader and any collaborators they appoint', value: 'Leaders'},
            {label: 'Subcommittee officers and any collaborators they appoint', value: 'Officers'},
        ];
        this.staffOptions = [
            {label: 'Program Director', value: 'Director'},
            {label: 'Marketing Manager', value: 'Marketing'},
            {label: 'Land Agency Associate', value: 'Land'},
            {label: 'Finance Associate', value: 'Finance'},
            {label: 'Program Safety Team', value: 'Safety'},
            {label: 'Brochure Editor', value: 'Brochure Editor'}
        ];
        this.staffValues = [];
        this.volunteerValues = [];
    }
  
    @wire(getCommentsList, {tripId: '$recordId'})
    wiredCommentsList(result) {
        if (result.data) {

            this.commentsList = result.data.map(row => {
                let submitter = row.CreatedBy.Name;
                let newRow = {...row , submitter};
                let recipients = [];
                if(row.National_Outings_Trip_Comments_Recips__r) {
                    let recip = row.National_Outings_Trip_Comments_Recips__r;
                    for(let idx=0; idx < recip.length; idx++) {
                        let recipient = recip[idx];
                        let name = '';
                        if(recipient.Contact__r) {
                            name = recipient.Contact__r.Name;
                        }
                        else if(recipient.Staff_Position__c != null) {
                            name = recipient.Staff_Position__c;
                        }
                        else {
                            if(recipient.Email__c.indexOf('brochure') >= 0) {
                                name = "Brochure Editor";
                            }
                            else {
                                name = 'Outings Staff';
                            }
                        }
                        recipients.push({Id: recipient.Id, name: name, email: recipient.Email__c});
                    }
                }
                newRow = {...newRow , recipients};
                let hasRecipients = recipients.length > 0;
                newRow = {...newRow , hasRecipients};
                return newRow;
            });

            this.wiredComments = result;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.collabList = undefined;
        }
    }
    handleCommentChange(e) {
        this.tripComment = e.target.value;
    }
    handleVolunteerChange(e) {
        this.volunteerValues = e.detail.value;
    }
    handleStaffChange(e) {
        this.staffValues = e.detail.value;
    }
    get isModalOpen() {
        return this.modalOpen;
    }
    closeModal() {
        this.staffValues = [];
        this.volunteerValues = [];
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
                    Notify_Approvers__c: (this.volunteerValues.indexOf('Officers') >= 0),
                    Notify_Creators__c: (this.volunteerValues.indexOf('Leaders') >= 0),
                    Notify_Staff__c: (this.staffValues.indexOf('Director') >= 0),
                    Notify_Brochure_Editor__c: (this.staffValues.indexOf('Brochure Editor') >= 0),
                    Notify_Finance__c: (this.staffValues.indexOf('Finance') >= 0),
                    Notify_Land_Agency__c: (this.staffValues.indexOf('Land') >= 0),
                    Notify_Marketing__c: (this.staffValues.indexOf('Marketing') >= 0),
                    Notify_Safety__c: (this.staffValues.indexOf('Safety') >= 0)
                }
            }).then(() => {
                this.showSnackbar('success', 'Comment Saved');
                this.modalOpen = false;
                this.staffValues = [];
                this.volunteerValues = [];
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