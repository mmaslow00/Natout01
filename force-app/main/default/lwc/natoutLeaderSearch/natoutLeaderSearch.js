import { LightningElement, track, api } from 'lwc';
import getLeaderList from '@salesforce/apex/NatoutLeaderSearchController.getLeaderList';

export default class NatoutLeaderSearch extends LightningElement {
    @track leaderList = [];
    @track lastName = '';
    @track firstName = '';
    @track resultsFound = true;
    @track loadingResults = false;
    @api allowUnknown = 'false';

    searchLeaders() {
        if(this.checkValid()) {
            this.loadingResults = true;
            getLeaderList({ lastName: this.lastName.trim(), firstName: this.firstName.trim() })
            .then(result => {
                this.leaderList = result;
                this.resultsFound = this.leaderList.length > 0;
                this.error = undefined;
                this.loadingResults = false;
            })
            .catch(error => {
                this.error = error;
                this.tripList = undefined;
                this.loadingResults = false;
            });
        }
    }
    checkValid() {
        var inputCmp = this.template.querySelector(".lastName");
        return inputCmp.reportValidity();
    }
    setLastName(e) {
        this.lastName = e.target.value;
    }
    setFirstName(e) {
        this.firstName = e.target.value;
    }
    selectLeader(e) {
        e.preventDefault();
        let rowIndex = e.currentTarget.rowIndex;
        let selectedLeader = this.leaderList[rowIndex];
        const leaderSelectedEvent = new CustomEvent("leaderselected",
            {detail: selectedLeader}
        );
        this.dispatchEvent(leaderSelectedEvent);
    }
    cancelSelection(e) {
        e.preventDefault();
        const leaderSelectedEvent = new CustomEvent("leaderselected",
            {detail: {}}
        );
        this.dispatchEvent(leaderSelectedEvent);
    }
    leaderUnknown(e) {
        e.preventDefault();
        const leaderSelectedEvent = new CustomEvent("leaderselected",
            {detail: 'Unknown'}
        );
        this.dispatchEvent(leaderSelectedEvent);
    }
    get showUnknownButton() {
        return (this.allowUnknown != 'false');
    }
}