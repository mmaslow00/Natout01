import { LightningElement, track, api } from 'lwc';
import getAccountList from '@salesforce/apex/NatoutAccountSearchController.getAccountList';

export default class NatoutLeaderSearch extends LightningElement {
    @api accountType;
    @track accountList = [];
    @track searchName = '';
    @track resultsFound = true;
    @track loadingResults = false;

    searchAccounts() {
        if(this.checkValid()) {
            this.loadingResults = true;
            getAccountList({ accountType: this.accountType, searchName: this.searchName })
            .then(result => {
                this.accountList = result;
                this.resultsFound = this.accountList.length > 0;
                this.error = undefined;
                this.loadingResults = false;
            })
            .catch(error => {
                this.error = error;
                this.accountList = undefined;
                this.loadingResults = false;
            });
        }
    }
    checkValid() {
        var inputCmp = this.template.querySelector("lightning-input");
        return inputCmp.reportValidity();
    }
    setSearchName(e) {
        this.searchName = e.target.value;
    }
    selectAccount(e) {
        e.preventDefault();
        let rowIndex = e.currentTarget.rowIndex;
        let selectedAccount = this.accountList[rowIndex];
        const accountSelectedEvent = new CustomEvent("accountselected",
            {detail: selectedAccount}
        );
        this.dispatchEvent(accountSelectedEvent);
    }
    cancelSelection(e) {
        e.preventDefault();
        const accountSelectedEvent = new CustomEvent("accountselected",
            {detail: {}}
        );
        this.dispatchEvent(accountSelectedEvent);
    }
}