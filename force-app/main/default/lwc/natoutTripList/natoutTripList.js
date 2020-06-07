import { LightningElement, track, wire } from 'lwc';
import getTripList from '@salesforce/apex/NatoutTripListController.getTripList';
import getUserInfo from '@salesforce/apex/NatoutUserInfo.getUserInfo';
import copyTrip from '@salesforce/apex/NatoutTripCopy.copy';
import markUploaded from '@salesforce/apex/NatoutTripCopy.markUploaded';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPicklistOptions from '@salesforce/apex/NatoutTripOptions.getOptions';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import TRIP_OBJECT from '@salesforce/schema/National_Outings_Trip__c';
import userId from '@salesforce/user/Id';
import getUserAccess from '@salesforce/apex/NatoutUserInfo.getUserAccess';

const statusOptions = [
    {label: 'Any', value: 'any'},
    {label: 'Started', value: 'Started'},
    {label: 'Submitted', value: 'Submitted'},
    {label: 'Returned', value: 'Returned'},
    {label: 'Approved by Chair', value: 'Approved by Chair'}
];

export default class NatoutTripList extends LightningElement {
    userInfo = {};
    columns;
    @track tripList = { data: [] }
    selectedSubcomm = 'any';
    @track dtBegin = null;
    @track dtEnd = null;
    @track copying = false;
    @track selectTypeAny = false;
    selectedStatus = 'any';
    selectedTripType = 'any';
    selectedState = 'any';
    selectedNameSearch = '';
    @track sortedBy;
    @track sortDirection = 'asc';

    @wire(getPicklistOptions)
    picklistOptions;

    @wire(getObjectInfo, { objectApiName: TRIP_OBJECT })
    objectInfo;

    @wire(getUserAccess, {tripId: ''})
    userAccess;

    constructor() {
        super();
        this.columns =
        [
            { label: 'Name', type: 'url', fieldName: 'nameUrl', sortable: 'true', typeAttributes: {label: {fieldName: 'Name'}} },
            { label: 'Departs', type: 'date-local', sortable: true,
                typeAttributes: {
                    month: "2-digit",
                    day: "2-digit"
                },
                fieldName: 'Start_Date__c' },
            {label: 'Subcommittee', fieldName: 'Subcommittee__c', sortable: true},
            {label: 'Status', fieldName: 'Status__c', sortable: true},
            {label: 'Type', fieldName: 'Trip_Type__c', sortable: true},
            { type: 'action', typeAttributes: { rowActions: this.getRowActions } },
        ];        
    }

   connectedCallback() {
       this.retrieveUserData();
   }

    get selectTypeOptions () {
        let radioOptions = [];
        radioOptions.push({ label: 'My Trips', value: 'myTrips'});
        radioOptions.push({label: 'All Trips', value: 'all'});
        return radioOptions;
    }
    get subcommOptions () {
        if(this.picklistOptions != null) {
            if(this.picklistOptions.data) {
                let options = [{label: 'Any', value: 'any'}];
                for(let i=0; i < this.picklistOptions.data.subcommList.length; i++) {
                    let label = this.picklistOptions.data.subcommList[i];
                    let labelValue = {label: label, value: label};
                    options.push(labelValue);
                }
                return options;
            }
        }
        return null;
    }
    get tripTypeOptions() {
        if(this.picklistOptions != null) {
            if(this.picklistOptions.data) {
                let options = [{label: 'Any', value: 'any'}];
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
    get statesOptions() {
        if(this.picklistOptions != null) {
            if(this.picklistOptions.data) {
                let options = [{label: 'Any', value: 'any'}];
                for(let i=0; i < this.picklistOptions.data.stateList.length; i++) {
                    let state = this.picklistOptions.data.stateList[i];
                    let labelValue = {label: state.label, value: state.value};
                    options.push(labelValue);
                }
                return options;
            }
        }
        return null;
    }
    retrieveUserData() {
        getUserInfo()
        .then(result => {
            this.userInfo = result;
            this.dtBegin = this.getDefaultDate();
            this.retrieveList();
        })
        .catch(error => {
            this.error = error;
            this.userInfo = undefined;
        });
    }

    retrieveList() {
        let parameterObject = {
            userTrips: ! this.selectTypeAny,
            dtBegin: this.dtBegin,
            dtEnd: this.dtEnd,
            subcomm: this.selectedSubcomm,
            status: this.selectedStatus,
            type: this.selectedTripType,
            state: this.selectedState,
            nameMatch: this.selectedNameSearch
        };

        getTripList({ searchCriteria: parameterObject })
            .then(result => {
                this.tripList.data = result.map(row => {
                    let nameUrl = (this.userInfo.isInCommunity ? '/national-outings-trip/' : '/') + row.Id;
                    let newRow = {...row , nameUrl};
                    return newRow;
                });
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.tripList = undefined;
            });
    }
    copy(id) {
        this.copying = true;
        copyTrip({ tripId: id})
        .then(result => {
            this.navigateToTrip(result);
        })
        .catch(error => {
            this.error = error;
        });
    }
    markAsUploaded() {
        if(confirm('Are you sure you want to mark selected trips as Uploaded?')) {
            let idList = [];
            let datatable = this.template.querySelector('lightning-datatable');
            let selectedRows = datatable.getSelectedRows();
            for(let i=0; i < selectedRows.length; i++) {
                idList.push(selectedRows[i].Id);
            }
            markUploaded({idList: idList})
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Status of Selected Trips Set to Uploaded',
                        variant: 'success'
                    })
                );
                this.retrieveList();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error attempting to set status to uploaded',
                        message: reduceErrors(error).join(', '),
                        variant: 'error'
                    })
                );
            });                    
        }
    }
    navigateToTrip(id) {
        let currentLocation = window.location.href;
        let endOfString = '/natout/s/';
        let lastDash = currentLocation.indexOf(endOfString) + endOfString.length;
        currentLocation = currentLocation.substring(0, lastDash);
        let nextPage = currentLocation + 'national-outings-trip/' + id;
        window.location.href = nextPage;
    }
    getDefaultDate() {
        var d = new Date();
        var year = d.getFullYear();
        var month = d.getMonth();
        var day = d.getDate();
        return new Date(year - 1, month, day).toJSON();    
    }      
    
    handleSelectTypeChange(event) {
        this.selectTypeAny= event.detail.value === 'myTrips' ? false : true; 
    }
    handleTripTypeChange(e) {
        this.selectedTripType = e.target.value;
    }
    updateDtBegin(event) {
        this.dtBegin = event.target.value;
    }
    updateDtEnd(event) {
        this.dtEnd = event.target.value;
    }
    handleSubcommChange(event) {
        this.selectedSubcomm = event.target.value;
    }
    handleStatusChange(e) {
        this.selectedStatus = e.target.value;
    }
    handleStateChange(e) {
        this.selectedState = e.target.value;
    }
    handleNameSearchChange(e) {
        this.selectedNameSearch = e.target.value;
    }
    get statusOptions() {
        return statusOptions;
    }
    getRowActions(row, doneCallback) {
        let actions = [
            { label: 'Copy', name: 'copy'}
        ];
        if (row.OwnerId === userId) {
            if(row.Status__c === 'Started') {
                actions.push({
                    'label': 'Delete',
                    'name': 'delete'
                });
            }
        }
        doneCallback(actions);
    }
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'copy':
                this.copy(row.Id);
                break;
            case 'delete':
                if(confirm('Are you sure you want to delete this trip?')) {
                    deleteRecord(row.Id)
                    .then(() => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Trip Deleted',
                                variant: 'success'
                            })
                        );
                        this.retrieveList();
                    })
                    .catch(error => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error deleting record',
                                message: reduceErrors(error).join(', '),
                                variant: 'error'
                            })
                        );
                    });                    
                }
                break;
            default:
        }
    }
    exportSelected(e) {
        e.preventDefault();
        let linkValue;
        switch(e.detail.value) {
            case 'trip':
                linkValue = 'NatoutTripExport';
                break;
            case 'budget':
                linkValue = 'NatoutTripBudgetExport';
                break;
        }
        let datatable = this.template.querySelector('lightning-datatable');
        let selectedRows = datatable.getSelectedRows();
        let idString = '';
        for(let i=0; i < selectedRows.length; i++) {
            if(idString.length > 0) {
                idString += ',';
            }
            idString += selectedRows[i].Id;
        }
        if(idString.length > 0) {
            window.open('/' + linkValue + '?trips=' + idString);
        }
    }

    handleSort(e) {
        let fieldName = e.detail.fieldName;
        this.sortedBy = fieldName;
        let sortDirection = e.detail.sortDirection;
        // assign the latest attribute with the sorted column fieldName and sorted direction
        this.sortDirection = sortDirection;
        this.tripList.data = this.sortData(fieldName, sortDirection);
    }    

    sortData(fieldname, direction) {
        if(fieldname === 'nameUrl') {
            fieldname = 'Name';
        }
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.tripList.data));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // checking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // return the sorted data
        return parseData;
    }
    get userIsNotAdmin() {
        if(this.userAccess && this.userAccess.data) {
            return ! this.userAccess.data.isAdmin;
        }
        return false;
    }
}