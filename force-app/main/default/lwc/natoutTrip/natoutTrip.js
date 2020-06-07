import { LightningElement, api, track, wire } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getPicklistOptions from '@salesforce/apex/NatoutTripOptions.getOptions';

export default class NatoutTrip extends NavigationMixin(LightningElement) {
    @api recordId;
    @track tripCategory = 'domestic';
    @track isDomesticTrip = true;
    @track savingTrip = false;
    tripId='';
    subcommOptions = null;
    chosenSubcomm = null;
    chosenTripType = null;
    tripRecord = {
        Name: '',
        Subcommittee__c: '',
        Start_Date__c: null,
        End_Date__c: null,
        Status__c: 'Started'
    }
 
    @wire(getPicklistOptions)
    picklistOptions;
    
    get options() {
        return [
            { label: 'Domestic Trip', value: 'domestic' },
            { label: 'International Trip', value: 'international' },
        ];
    }

    setTypeOption(e) {
        this.tripCategory = e.target.value;
        this.isDomesticTrip = (this.tripCategory === 'domestic');
        if( ! this.isDomesticTrip) {
            this.template.querySelector('[data-field=subcommittee]').value = 'International';
            this.template.querySelector('[data-field=triptype]').value = 'International';
        }
    }
    handleFieldChange(e) {
        let field = e.currentTarget.dataset.field;
        this.tripRecord[field] = e.target.value;
        if(field === 'Start_Date__c' && this.tripRecord.End_Date__c === null) {
            let inputCmp = this.template.querySelector('.endDate');
            let dateInput = new Date(e.target.value);
            let dateString = dateInput.toISOString(dateInput).substring(0,10);
            inputCmp.value = dateString; 
        }
    }
    saveForm() {
        const allValid = [...this.template.querySelectorAll('lightning-input-field, lightning-combobox')]
        .reduce((validSoFar, inputCmp) => {
            return validSoFar && inputCmp.reportValidity();
            }, true);
        if(this.tripRecord.Start_Date__c > this.tripRecord.End_Date__c) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Failed to Create Trip',
                    message: 'End Date Must Be After Start Date',
                    variant: 'error'
                }),
            );
            return;
        }
        if (allValid) {
            if(this.tripCategory === 'international') {
                this.tripRecord.Subcommittee__c = "International";
                this.tripRecord.Trip_Type__c = "International";
            }
            else {
                this.tripRecord.Subcommittee__c = this.chosenSubcomm;
                this.tripRecord.Trip_Type__c = this.chosenTripType;
            }
            if(this.tripRecord.Start_Date__c === null) {
                this.tripRecord.Start_Date__c = this.template.querySelector('.startDate').value;
            }
            this.tripRecord.Title__c = this.tripRecord.Name;
            this.savingTrip = true;
            createRecord({
                apiName: 'National_Outings_Trip__c',
                fields: this.tripRecord
            })
            .then(result => {
                this.tripId = result.id;
                this.error = undefined;
                this.navigateToDetails();
            })
            .catch(error => {
                this.error = error;
                this.savingTrip = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Failed to Create Trip',
                        message: reduceErrors(error).join(', '),
                        variant: 'error'
                    }),
                );
            });
        }
    }
    cancelForm() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'National_Outings_Trip__c',
                actionName: 'list'
            }
        });
    }
    get subcommOptionList() {
        if(this.picklistOptions != null) {
            if(this.subcommOptions == null) {
                if(this.picklistOptions.data) {
                    this.subcommOptions = [];
                    for(let i=0; i < this.picklistOptions.data.subcommList.length; i++) {
                        let label = this.picklistOptions.data.subcommList[i];
                        if(label != 'International') {
                            let labelValue = {label: label, value: label};
                            this.subcommOptions.push(labelValue);
                        }
                    }
                }
            }
        }
        return this.subcommOptions;
    }
    get tripTypeOptions() {
        if(this.picklistOptions != null) {
            if(this.picklistOptions.data) {
                let options = [];
                for(let i=0; i < this.picklistOptions.data.tripTypeList.length; i++) {
                    let label = this.picklistOptions.data.tripTypeList[i];
                    let labelValue = {label: label, value: label};
                    options.push(labelValue);
                }
                return options;
            }
        }
        return null;
    }

    handleSubcommChange(e) {
        this.chosenSubcomm = e.target.value;
    }
    handleTripTypeChange(e) {
        this.chosenTripType = e.target.value;
    }

    navigateToDetails() {
        let currentLocation = window.location.href;
        let lastDash = currentLocation.lastIndexOf('/');
        currentLocation = currentLocation.substring(0, lastDash + 1);
        let nextPage = currentLocation + 'national-outings-trip/' + this.tripId;
        window.location.href = nextPage;

        /*
        this.tripPageRef = {
            type: "comm_namedPage",
            attributes: {
                name: 'National_Outings_Trip_Detail__c',
                recordId: this.tripId
            }
        };
        this[NavigationMixin.GenerateUrl](this.tripPageRef)
            .then(url => this.url = url);

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                recordId: this.tripId,
                name: 'National_Outings_Trip_Detail__c',
            }
        });
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.tripId,
                objectApiName: 'National_Outings_Trip__c',
            }
        });
*/
    }
}