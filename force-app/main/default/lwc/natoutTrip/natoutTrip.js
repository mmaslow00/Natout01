import { LightningElement, api, track, wire } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/ldsUtils';
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
            this.showSnackbar('failure','Failed to Create Trip','End Date Must Be After Start Date');
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
                this.showSnackbar('failure','Failed to Create Trip',reduceErrors(error).join(', '));
            });
        }
    }
    cancelForm() {
        window.location.href = 'NatoutTripList';
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
        let nextPage = 'NatoutTripDetail?id=' + this.tripId;
        window.location.href = nextPage;
    }
    showSnackbar(type, header, text) {
        this.template.querySelector('c-snackbar').show(type, header, text);
    }
}