import { LightningElement, api, wire, track } from 'lwc';
import getCommentsList from '@salesforce/apex/NatoutTripCommentsController.getCommentsList';
import { createRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { reduceErrors } from 'c/ldsUtils';

const columns = [
    { label: 'Leader', fieldName: 'contactName'},
    { label: 'Access', fieldName: 'Access__c'}
];

export default class NatoutTripComments extends LightningElement {
    @api recordId = '';
    @track commentsList = [];
    wiredComments;

    @wire(getCommentsList, {tripId: '$recordId'})
    wiredCommentsList(result) {
        if (result.data) {

            this.commentsList = result.data.map(row => {
                let submitter = row.CreatedBy.Name;
                let newRow = {...row , submitter};
                return newRow;
            });

            this.wiredComments = result;
            //this.commentsList = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.collabList = undefined;
        }
    }

}