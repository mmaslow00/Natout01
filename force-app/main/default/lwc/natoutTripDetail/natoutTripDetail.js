import { LightningElement, api, track, wire } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/ldsUtils';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import TRIP_OBJECT from '@salesforce/schema/National_Outings_Trip__c';
import PERMIT_REQUIREMENT_FIELD from '@salesforce/schema/National_Outings_Trip__c.Permit_Requirement_Options__c';
import getPicklistOptions from '@salesforce/apex/NatoutTripOptions.getOptions';
import getUserAccess from '@salesforce/apex/NatoutUserInfo.getUserAccess';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';

export default class NatoutTripDetail extends LightningElement {
    @api recordId;
    @track tripRecord = {};
    @track wordCount = null;
    @track activeBudgetSections = [];
    @track activeTripSections = ["Approval Status"];
    @track searchingForLocation = false;
    @track showMap = false;
    @track showStatusDialog;
    loadedForm = false;
    loadedStatus = null;
    countryOptions = null;
    chosenCountries = null;
    chosenStates = null;
    subcommOptions = null;
    chosenSubcomm = null;
    tripTypeOptions = null;
    chosenTripType = null;
    chosenStatus = null;
    lastFieldInitialized = false;
    @track errorList = [];

    @wire(getObjectInfo, { objectApiName: TRIP_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: PERMIT_REQUIREMENT_FIELD})
    permitRequirementPicklistValues;    
    
    @wire(getPicklistOptions)
    picklistOptions;

    @wire(getUserAccess, {tripId: '$recordId'})
    userAccess;

    constructor() {
        super();
        window.natoutTripDetailChangeMade = false;
        window.addEventListener('beforeunload', function (e) {
            if(natoutTripDetailChangeMade) {
                // Cancel the event
                e.preventDefault(); // If you prevent default behavior in Mozilla Firefox prompt will always be shown
                // Chrome requires returnValue to be set
                e.returnValue = 'Changes you made may not be saved.';
                return;
            }
          });        
    }
    handleLoad(event) {
        if (!this.loadedForm) {
            let fields = Object.values(event.detail.records)[0].fields;
            const recordId = Object.keys(event.detail.records)[0];
            this.tripRecord = {
                Id: recordId,
                ...Object.keys(fields)
                    // eslint-disable-next-line no-unused-vars
                    .filter((field) => !!this.template.querySelector(`[data-field=${field}]`))
                    .reduce((total, field) => {
                        total[field] = fields[field].value;
                        return total;
                    }, {})
            };
            this.setupChosenCountries();
            this.setupChosenStates();
            this.chosenSubcomm = this.tripRecord.Subcommittee__c;
            this.chosenTripType = this.tripRecord.Trip_Type__c;
            this.chosenStatus = this.tripRecord.Status__c;
            this.loadedStatus = this.tripRecord.Status__c;
            document.title = this.tripRecord.Name;
            this.loadedForm = true;
        }
    }
    renderedCallback() {
        if(this.tripRecord.Trip_Copy__c) {
            if(this.wordCount === null) {
                this.calculateWordCount();
            }
        }
        if(this.tripRecord.Latitude__c) {
            this.showMap = true;
        }
        else {
            this.showMap = false;
        }
    }
    handleFieldChange(e) {
        let fieldName = e.currentTarget.dataset.field;
        this.tripRecord[fieldName] = e.target.value;
        if (fieldName === "Trip_Copy__c") {
            this.calculateWordCount();
        }
        else if((fieldName === "Geographic_Area__c" && this.tripIsInternational) || (fieldName === "Meals_Included__c" && ! this.tripIsInternational)) {
            if(this.lastFieldInitialized == false) {
                this.lastFieldInitialized = true;
                let inp=this.template.querySelectorAll('lightning-input-field, lightning-combobox, lightning-dual-listbox, lightning-radio-group');
                inp.forEach(function(element){
                    element.addEventListener('change', evt => {
                        window.natoutTripDetailChangeMade = true;
                    });
                });
            }
        }
    }
    handleCountriesChange(e) {
        this.chosenCountries = e.target.value;
    }
    handleStatesChange(e) {
        this.chosenStates = e.target.value;
    }
    handleSubcommChange(e) {
        this.chosenSubcomm = e.target.value;
    }
    handleTripTypeChange(e) {
        this.chosenTripType = e.target.value;
    }
    handleStatusChange(e) {
        let previousStatus = this.chosenStatus;
        this.chosenStatus = e.target.value;
        if((previousStatus === 'Started' || previousStatus === 'Returned') && this.chosenStatus === 'Submitted') {
            this.errorList = this.statusStartedToSubmitted();
            if(this.errorList.length > 0) {
                this.template.querySelector('.approvalStatus').value = previousStatus;
                this.chosenStatus = previousStatus;
            }
            this.showStatusDialog = true;
        }
    }
    handleBudgetSectionToggle(event) {
        const openSections = event.detail.openSections;

        if(openSections.includes('budget-report')) {
            //refresh report page
            let iframe = this.template.querySelector('iframe');
            iframe.src += '';
        }
        let sectionDiff = openSections.filter( x => !this.activeBudgetSections.includes(x) );
        if (sectionDiff.length > 0) {
        //only update if there is a difference (as handleToggleSection is reexecuted
        //until no diffs (seems odd, but it was)
        this.activeBudgetSections = sectionDiff;
        }
    }
    handleTripSectionToggle(event) {
        const openSections = event.detail.openSections;
        let sectionDiff = openSections.filter( x => !this.activeTripSections.includes(x) );
        if (sectionDiff.length > 0) {
        //only update if there is a difference (as handleToggleSection is reexecuted
        //until no diffs (seems odd, but it was)
        this.activeTripSections = sectionDiff;
        }
    }
    saveForm() {
        // eslint-disable-next-line no-console
        //console.log('Trip for save => ', JSON.stringify(this.tripRecord));
        let saveErrors = false;
        const allValid = [...this.template.querySelectorAll('lightning-input-field, lightning-combobox')]
        .reduce((validSoFar, inputCmp) => {
            return validSoFar && inputCmp.reportValidity();
            }, true);
        if(! allValid) {
            saveErrors = true;
            this.showSnackbar('failure', 'Trip Update Failed', 'Please enter all required fields');
        }
        if((this.loadedStatus === 'Started' || this.loadedStatus === 'Returned') && this.tripRecord.Status__c === 'Submitted') {
            this.errorList = this.statusStartedToSubmitted();
            if(this.statusChangeErrors) {
                saveErrors = true;
                this.showSnackbar('failure', 'Trip Update Failed', 'There are Status Change errors');
                this.showStatusDialog = true;
            }
        }
        if( ! saveErrors ) {
            this.saveChosenCountries();
            this.saveChosenStates();
            this.tripRecord.Subcommittee__c = this.chosenSubcomm;
            this.tripRecord.Trip_Type__c = this.chosenTripType;
            this.tripRecord.Status__c = this.chosenStatus;

            updateRecord ({
                fields: this.tripRecord
            })
            .then(result => {
                this.message = result;
                this.error = undefined;
                this.showSnackbar('success', 'Trip Updated', 'Trip was successfully updated');
                window.natoutTripDetailChangeMade = false;
                if(this.loadedStatus === 'Started' && this.tripRecord.Status__c === 'Submitted') {
                    return refreshApex(this.userAccess);
                }
            })
            .catch(error => {
                this.error = error;
                this.showSnackbar('failure', 'Update Failed', reduceErrors(error).join(', '));
            });
        }   
    }

    setupChosenCountries() {
        let retArray = [];
        if(this.tripRecord.International_Countries__c) {
            let chosenArray = this.tripRecord.International_Countries__c.split(";");
            for(let i=0; i < chosenArray.length; i++) {
                retArray.push(chosenArray[i]);
            }
        }
        this.chosenCountries = retArray;
    }
    saveChosenCountries() {
        let chosen = '';
        for(let i=0; i < this.chosenCountries.length; i++) {
            if(chosen.length > 0) {
                chosen += ";";
            }
            chosen += this.chosenCountries[i];
        }
        this.tripRecord.International_Countries__c = chosen;
    }
    setupChosenStates() {
        let retArray = [];
        if(this.tripRecord.States__c) {
            let chosenArray = this.tripRecord.States__c.split(";");
            for(let i=0; i < chosenArray.length; i++) {
                retArray.push(chosenArray[i]);
            }
        }
        this.chosenStates = retArray;
    }
    saveChosenStates() {
        let chosen = '';
        for(let i=0; i < this.chosenStates.length; i++) {
            if(chosen.length > 0) {
                chosen += ";";
            }
            chosen += this.chosenStates[i];
        }
        this.tripRecord.States__c = chosen;
    }

    get mealsBudgetSubcomm() {
        return this.tripRecord.Meals_Budget_Option__c === 'Subcommittee';
    }
    get mealsBudgetDay() {
        return this.tripRecord.Meals_Budget_Option__c === 'Day';
    }
    get mealsBudgetNone() {
        return this.tripRecord.Meals_Budget_Option__c === 'None';
    }
    get selectedMealsBudgetOption() {
        return this.tripRecord.Meals_Budget_Option__c;
    }
    get tripIsInternational() {
        let retVal = false;
        if(this.tripRecord.Subcommittee__c) {
            if(this.tripRecord.Subcommittee__c === 'International') {
                retVal = true;
            }
        }
        return retVal;
    }
    get isBPTrip() {
        let retVal = false;
        if(this.chosenTripType) {
            if(this.chosenTripType.indexOf('Backpack') >= 0) {
                retVal = true;
            }
        }
        return retVal;
    }
    get satPhoneNeeded () {
        let retVal = false;
        if(this.tripRecord.Sat_Phone_Needed__c) {
            return this.tripRecord.Sat_Phone_Needed__c;
        }
        return retVal;
    }
    get showMinAge() {
        let retVal = false;
        if(this.tripRecord.Trip_Type__c) {
            switch (this.tripRecord.Trip_Type__c) {
                case 'Family':
                case 'Family Raft':
                case 'Grandparents':
                    retVal = true;
                    break;
                default:
                    retVal = false;
            }
        }
        return retVal;
    }
    get tripStartDate() {
        return this.tripRecord.Start_Date__c;
    }
    get tripEndDate() {
        return this.tripRecord.End_Date__c;
    }
    get numStaff() {
        return this.tripRecord.Planned_Staff__c;
    }
    get agencyOptions() {
        let agencyComponent = this.template.querySelector('c-natout-trip-agencies');
        let agencyOptionsList = [];
        if(agencyComponent != null) {
            agencyOptionsList = agencyComponent.getAgencyOptions();
        }
        agencyOptionsList.unshift({label: 'None', value: 'None'});
        return agencyOptionsList;
    }
    get mealsBudgetOptions() {
        let mealsOptions = [{label: "None", value: "None"}];
        if(this.tripRecord.Subcommittee__c) {
            if(this.tripRecord.Subcommittee__c != 'International') {
                mealsOptions.push({label: "Subcommittee Standard Values", value: "Subcommittee"});
            }
        }
        mealsOptions.push({label: "Budget by Day", value: "Day"});
        return mealsOptions;
    }
    get latLng() {
        if(this.tripRecord.Latitude__c && this.tripRecord.Longitude__c) {
            return {"latitude": this.tripRecord.Latitude__c, "longitude": this.tripRecord.Longitude__c};
        }
        return {};
    }
    get mapMarkers() {
        let mapMarker = null;
        if(this.tripRecord) {
            if(this.tripRecord.Latitude__c && this.tripRecord.Longitude__c) {
                mapMarker = [{
                    location: {
                        Latitude: this.tripRecord.Latitude__c,
                        Longitude: this.tripRecord.Longitude__c
                    }
                }];
            }
        }
        return mapMarker;
    }
    get staffRoleOptions() {
        let staffComponent = this.template.querySelector('c-natout-trip-staff');
        let optionsList = [];
        if(staffComponent != null) {
            optionsList = staffComponent.getTripRoles();
        }
        return optionsList;
    }
    get permitRequirementOptions () {
        let options = [];
        if(this.permitRequirementPicklistValues.data) {
            for(let i=0; i < this.permitRequirementPicklistValues.data.values.length; i++) {
                options.push(this.permitRequirementPicklistValues.data.values[i]);
            }
        }
        return options;
    }
    get selectedPermitRequirementOption() {
        return this.tripRecord.Permit_Requirement_Options__c;
    }
    get countryListOptions() {
        if(this.picklistOptions != null) {
            if(this.countryOptions == null) {
                this.countryOptions = [];
                for(let i=0; i < this.picklistOptions.data.countryList.length; i++) {
                    let label = this.picklistOptions.data.countryList[i];
                    let labelValue = {label: label, value: label};
                    this.countryOptions.push(labelValue);
                }
            }
        }
        return this.countryOptions;
    }
    get stateListOptions() {
        if(this.picklistOptions != null) {
            if(this.picklistOptions.data) {
                if(this.stateOptions == null) {
                    this.stateOptions = this.picklistOptions.data.stateList;
                }               
            }
        }
        return this.stateOptions;
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
    get intlQuestion01Options() {
        return [
            {label: 'Concessionaire-led', value: 'Concessionarie-led' },
            {label: 'Third-party supported', value: 'Third-party supported'},
            {label: 'No vendors used', value: 'No vendors used'}

        ];
    }
    get selectedIntlQuestion01Option() {
        return this.tripRecord.IntlQuestion01__c;
    }
    get tripTypeOptionList() {
        if(this.picklistOptions != null) {
            if(this.tripTypeOptions == null) {
                if(this.picklistOptions.data) {
                    this.tripTypeOptions = [];
                    for(let i=0; i < this.picklistOptions.data.tripTypeList.length; i++) {
                        let label = this.picklistOptions.data.tripTypeList[i];
                        let labelValue = {label: label, value: label};
                        this.tripTypeOptions.push(labelValue);
                    }
                }
            }
        }
        return this.tripTypeOptions;
    }
    calculateWordCount() {
        this.wordCount = 0;
        if(this.tripRecord.Trip_Copy__c) {
            this.wordCount = this.tripRecord.Trip_Copy__c
                .split(' ')
                .filter(function(n) { return n != ''; })
                .length;
        }
        return this.wordCount;
    }
    get repeatTrip() {
        if(this.tripRecord) {
            return ! this.tripRecord.First_Time_Run__c;
        }
        return false;
    }
    get concessionaireTitle() {
        let title = "Concessionaires";
        if(this.tripRecord.Subcommittee__c) {
            if(this.tripRecord.Subcommittee__c === 'International') {
                title = "Concessionaires/Leader Planned Arrangements";
            }
        }
        return title;
    }
    get budgetReportUrl() {
        let baseUrl = window.location.protocol + '//' + window.location.hostname + '/' + window.location.pathname.split('/')[1];
        if( ! baseUrl.endsWith('apex')) {
            baseUrl += '/apex';
        }
        baseUrl += '/NatoutTripBudgetReport?trip=' + this.recordId;
        return baseUrl;
    }
    get userCanEdit() {
        if(this.userAccess && this.userAccess.data) {
            return this.userAccess.data.canEdit;
        }
        return false;
    }
    get userCanApprove() {
        if(this.userAccess && this.userAccess.data) {
            return this.userAccess.data.canApprove;
        }
        return false;
    }
    get userIsAdmin() {
        if(this.userAccess && this.userAccess.data) {
            return this.userAccess.data.isAdmin;
        }
        return false;
    }
    get statusOptions() {
        let opts = [];
        if(this.userAccess && this.userAccess.data) {
            if(this.userCanEdit) {
                if(this.tripRecord.Status__c === 'Started') {
                    opts.push('Started');
                }
                opts.push('Submitted');
                if(this.tripRecord.Status__c === 'Returned') {
                    opts.push('Returned');
                }
            }
            if(this.userCanApprove) {
                if( ! opts.includes('Returned')) {
                    opts.push('Returned');
                    opts.push('Approved by Chair');
                }
            }
            if(this.userIsAdmin) {
                opts.push('Approved by Staff');
                opts.push('Uploaded to TRAIL');
            }
        }
        let options = [];
        for(let i=0; i < opts.length; i++) {
            options.push({label: opts[i], value: opts[i]});
        }
        return options;
    }
    get userIsReadOnly() {
        return ! this.userCanEdit;
    }
    get statusChangeErrors() {
        return this.errorList.length > 0;
    }
    get showApprovalWarnings() {
        let retVal = false;
        if(this.tripRecord.Status__c === 'Submitted') {
            if(this.userCanApprove || this.userIsAdmin) {
                if(this.approvalWarnings.length > 0) {
                    retVal = true;
                }
            }
        }
        return retVal;
    }
    get approvalWarnings() {
        let warnings = [];
        let rowNum = 0;
        let allStaffAssigned = this.template.querySelector('c-natout-trip-staff').allStaffAssigned();
        if( ! allStaffAssigned) {
            warnings.push({rowNum: rowNum++, text: 'Not all staff positions have been assigned'});
        }
        let cmp = this.template.querySelector('[data-field=Sat_Phone_Needed_Date__c]');
        if(cmp) {
            let satPhoneNeededDate = cmp.value;
            if(satPhoneNeededDate) {
                let numDays = this.numberOfDaysBetween(satPhoneNeededDate, this.tripRecord.Start_Date__c);
                if(numDays > 5) {
                    warnings.push({rowNum: rowNum++, text: 'Sat Phone Needed Date is more than 5 days before start date'});
                }
            }
        }
        let itineraryDays = this.template.querySelector('c-natout-trip-itinerary').getRowCount();
        let startDate = new Date(this.tripRecord.Start_Date__c);
        let endDate = new Date(this.tripRecord.End_Date__c);
        let tripDays = this.numberOfDaysBetween(startDate, endDate) + 1;
        if(itineraryDays < tripDays) {
            warnings.push({rowNum: rowNum++, text: 'Itinerary Days is less than days between start and end dates'});
        }
        return warnings;

    }
    numberOfDaysBetween(startDate, endDate) {
        const oneDay = 24 * 60 * 60 * 1000; // hours*minutes*seconds*milliseconds
        let firstDate = new Date(startDate);
        let secondDate = new Date(endDate);
        
        return Math.round((secondDate - firstDate) / oneDay);        
    }
    setLocation(e) {
        let latLng = e.detail;
        this.tripRecord.Latitude__c = latLng.latitude;
        this.tripRecord.Longitude__c = latLng.longitude; 
        this.template.querySelector('[data-field=Latitude__c]').value = latLng.latitude;
        this.template.querySelector('[data-field=Longitude__c]').value = latLng.longitude;
        this.searchingForLocation = false;
    }
    cancelLocation(e) {
        this.searchingForLocation = false;
    }
    mapLocation(e) {
        e.preventDefault();
        this.searchingForLocation = true;
    }
    closeErrorDisplay() {
        this.showStatusDialog = false;
    }
    statusStartedToSubmitted() {
        let errors = [];
        let rowNum = 0;
        if( ! this.tripRecord.Name ) {
            errors.push({rowNum: rowNum++, text: 'Name is Required'});
        }
        if( ! this.tripRecord.Title__c ) {
            errors.push({rowNum: rowNum++, text: 'Title is Required'});
        }
        if( ! this.tripRecord.Start_Date__c ) {
            errors.push({rowNum: rowNum++, text: 'Start Date is Required'});
        }
        if( ! this.tripRecord.End_Date__c ) {
            errors.push({rowNum: rowNum++, text: 'End Date is Required'});
        }
        if( ! this.tripRecord.Participants__c ) {
            errors.push({rowNum: rowNum++, text: 'Number of Participants is Required'});
        } else if(parseInt(this.tripRecord.Participants__c) < 1) {
            errors.push({rowNum: rowNum++, text: 'Number of Participants is Required'});
        }
        if( ! this.tripRecord.Planned_Staff__c ) {
            errors.push({rowNum: rowNum++, text: 'Number of Planned Staff is Required'});
        } else if(parseInt(this.tripRecord.Planned_Staff__c) < 1) {
            errors.push({rowNum: rowNum++, text: 'Number of Planned Staff is Required'});
        } else {
            let staffComponent = this.template.querySelector('c-natout-trip-staff');
            let optionsList = [];
            if(staffComponent != null) {
                optionsList = staffComponent.getTripRoles();
            }
            if(optionsList.length > this.tripRecord.Planned_Staff__c) {
                errors.push({rowNum: rowNum++, text: 'More Staff Entered than Planned'});
            }
        }

        if(this.tripRecord.First_Time_Run__c) {
            if( ! this.tripRecord.Trip_Copy__c ) {
                errors.push({rowNum: rowNum++, text: 'Trip Copy is Required for a First Time Trip'});
            }
        }
        else if( ! this.tripRecord.Prior_Trip__c) {
            errors.push({rowNum: rowNum++, text: 'Prior Trip # is Required if this not a First Time Trip'});
        }
        if( ! this.tripRecord.Conservation_Emphasis__c) {
            errors.push({rowNum: rowNum++, text: 'Conservation Emphasis is Required'});
        }
        if(this.tripIsInternational) {
            if(this.chosenCountries.length == 0) {
                errors.push({rowNum: rowNum++, text: 'At least one country is Required'});
            }
            else if(this.chosenCountries.length > 3) {
                errors.push({rowNum: rowNum++, text: 'You cannot specify more than 3 Countries'});
            }
        }
        else {
            let areas = this.tripRecord.Area__c;
            if( ! areas) {
                errors.push({rowNum: rowNum++, text: 'At least one Area is Required'});
            }    
            else if(areas.length == 0) {
                errors.push({rowNum: rowNum++, text: 'At least one Area is Required'});
            }
            else {
                areas = this.tripRecord.Area__c.split(';');
                if(areas.length > 3) {
                    errors.push({rowNum: rowNum++, text: 'You cannot specify more than 3 Areas'});
                }
            }
            let actTypes = this.tripRecord.Activity_Type__c;
            if( ! actTypes ) {
                errors.push({rowNum: rowNum++, text: 'At least one Activity Type is Required'});
            }
            else if(actTypes.length == 0) {
                errors.push({rowNum: rowNum++, text: 'At least one Activity Type is Required'});
            }
            else {
                actTypes = this.tripRecord.Activity_Type__c.split(';');
                if(actTypes.length > 3) {
                    errors.push({rowNum: rowNum++, text: 'You cannot specify more than 3 Activity Types'});
                }
            }

            if(this.chosenStates.length > 3) {
                errors.push({rowNum: rowNum++, text: 'You cannot specify more than 3 States'});
            }

            if( ! this.tripRecord.Country__c ) {
                errors.push({rowNum: rowNum++, text: 'Country is Required'});
            }
        }
        if( ! (this.tripRecord.Latitude__c && this.tripRecord.Longitude__c) ) {
            errors.push({rowNum: rowNum++, text: 'Longitude and Latitude are Required'});
        }
        if( ! this.tripRecord.Risks_Hazards__c ) {
            errors.push({rowNum: rowNum++, text: 'Risks/Hazards is Required'});
        }

        if( this.tripRecord.Permit_Requirement_Options__c === 'Permit Associate Staff will obtain Commercial Permit (s)' ) {
            let agencyCount = this.template.querySelector('c-natout-trip-agencies').getRowCount();
            if(agencyCount < 1) {
                errors.push({rowNum: rowNum++, text: 'At least one permit must be entered'});
            }
            if(this.isBPTrip) {
                if( ! (this.tripRecord.Entry_Trail_Head__c && this.tripRecord.Exit_Trail_Head__c) ) {
                    errors.push({rowNum: rowNum++, text: 'Entry and Exit Trail Heads are required'});
                }
            }
        }
        let budgetCount = 
            this.template.querySelector('c-natout-trip-budget-concessionaire').getRowCount() +
            this.template.querySelector('c-natout-trip-budget-vol-travel').getRowCount() +
            this.template.querySelector('c-natout-trip-budget-transportation').getRowCount();

        if(budgetCount == 0) {
            let mealsBudgetComponent = this.template.querySelector('c-natout-trip-budget-meals');
            if(mealsBudgetComponent) {
                budgetCount += mealsBudgetComponent.getRowCount();
            }
        }

        if(budgetCount == 0) {
            if( ! 
                (
                this.tripRecord.Wilderness_Agency_Fees__c > 0 ||
                this.tripRecord.Commercial_Agency_Fees__c > 0 ||
                this.tripRecord.Postage__c > 0 ||
                this.tripRecord.Communication_Devices__c > 0 ||
                this.tripRecord.Shipping__c > 0 ||
                this.tripRecord.Supplies_Equipment__c > 0
                )
            ) {
                errors.push({rowNum: rowNum++, text: 'Missing Budget'});
            }
            
        }
        if( this.tripRecord.Sat_Phone_Needed__c ) {
            let date = this.template.querySelector('[data-field=Sat_Phone_Needed_Date__c]').value;
            if(date) {
                if(date > this.tripRecord.Start_Date__c) {
                    errors.push({rowNum: rowNum++, text: 'Sat Phone Needed Date is after Start Date'});
                }
            }
            let name = this.template.querySelector('[data-field=Sat_Phone_Ship_To_Name__c]').value;
            let address = this.template.querySelector('[data-field=Sat_Phone_Ship_To_Address__c]').value;
            let city = this.template.querySelector('[data-field=Sat_Phone_Ship_To_City__c]').value;
            let state = this.template.querySelector('[data-field=Sat_Phone_Ship_To_State_Prov__c]').value;
            let zip = this.template.querySelector('[data-field=Sat_Phone_Ship_To_Zip_Code__c]').value;

            if( ! (date && name && address && city && state && zip) ) {
                errors.push({rowNum: rowNum++, text: 'All Sat Phone fields must be entered when Sat Phone is needed'});
            }
        }
        let itineraryDays = this.template.querySelector('c-natout-trip-itinerary').getRowCount();
        let tripDays = this.numberOfDaysBetween(this.tripRecord.Start_Date__c, this.tripRecord.End_Date__c) + 1;
        if(itineraryDays > tripDays) {
            errors.push({rowNum: rowNum++, text: 'Itinerary Days is greater than days between start and end dates'});
        }

        return errors;
    }
    showSnackbar(type, header, text) {
        this.template.querySelector('c-snackbar').show(type, header, text);
    }
}