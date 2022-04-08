import { LightningElement, api } from 'lwc';
import getStaffApprovals from '@salesforce/apex/NatoutTripService.getStaffApprovals';
import updateStaffApprovals from '@salesforce/apex/NatoutTripService.updateStaffApprovals';
import { reduceErrors } from 'c/ldsUtils';

export default class NatoutTripApprovals extends LightningElement {
    @api recordId;
    staffApprovals;
 
    connectedCallback() {
        this.retrieveApprovals();
    }

    updateApprovals() {
        let budget = false;
        if( ! this.budgetApproved) {
            budget = this.template.querySelector('[data-id=budget]').checked;
        }
        let marketing = false;
        if( ! this.marketingApproved) {
            marketing = this.template.querySelector('[data-id=marketing]').checked;
        }
        let permits = false;
        if( ! this.permitsApproved) {
            permits = this.template.querySelector('[data-id=permits]').checked;
        }
        let vendors = false;
        if( ! this.vendorsApproved) {
            vendors = this.template.querySelector('[data-id=vendors]').checked;
        }

        updateStaffApprovals({
            tripId: this.recordId,
            budget: budget,
            marketing: marketing,
            permits: permits,
            vendors: vendors
        })
        .then(result => {
            this.staffApprovals = result;
        })
        .catch(error => {
            this.error = error;
            this.showSnackbar('failure', 'Update Failed', reduceErrors(error).join(', '));
        });
    }

    retrieveApprovals() {
        getStaffApprovals({
            tripId: this.recordId
        })
        .then(result => {
            this.staffApprovals = result;
        })
        .catch(error => {
            this.error = error;
            this.showSnackbar('failure', 'Approval Retrieval Failed', reduceErrors(error).join(', '));
        });
    }
    get permitsApproved() {
        if(this.staffApprovals) {
            return typeof this.staffApprovals.permitsDate !== 'undefined';
        }
        return false;
    }
    get marketingApproved() {
        if(this.staffApprovals) {
            return typeof this.staffApprovals.marketingDate !== 'undefined';
        }
        return false;
    }
    get budgetApproved() {
        if(this.staffApprovals) {
            return typeof this.staffApprovals.budgetDate !== 'undefined';
        }
        return false;
    }
    get vendorsApproved() {
        if(this.staffApprovals) {
            return typeof this.staffApprovals.vendorsDate !== 'undefined';
        }
        return false;
    }
    get budgetUser() {
        let user = '';
        if(this.staffApprovals) {
            user = this.staffApprovals.budgetUser;
        }
        return user;
    }
    get budgetDate() {
        let budgetDate = null;
        if(this.staffApprovals) {
            budgetDate = this.staffApprovals.budgetDate;
        }
        return budgetDate;
    }
    get vendorsUser() {
        let user = '';
        if(this.staffApprovals) {
            user = this.staffApprovals.vendorsUser;
        }
        return user;
    }
    get vendorsDate() {
        let vendorsDate = null;
        if(this.staffApprovals) {
            vendorsDate = this.staffApprovals.vendorsDate;
        }
        return vendorsDate;
    }
    get marketingUser() {
        let user = '';
        if(this.staffApprovals) {
            user = this.staffApprovals.marketingUser;
        }
        return user;
    }
    get marketingDate() {
        let date = null;
        if(this.staffApprovals) {
            date = this.staffApprovals.marketingDate;
        }
        return date;
    }
    get permitsUser() {
        let permits = '';
        if(this.staffApprovals) {
            permits = this.staffApprovals.permitsUser;
        }
        return permits;
    }
    get permitsDate() {
        let date = null;
        if(this.staffApprovals) {
            date = this.staffApprovals.permitsDate;
        }
        return date;
    }
    get allApproved() {
        return this.budgetApproved && this.vendorsApproved && this.marketingApproved && this.permitsApproved;
    }
    showSnackbar(type, header, text) {
        this.template.querySelector('c-snackbar').show(type, header, text);
    }
}