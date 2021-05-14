import { LightningElement, api, wire, track } from 'lwc';
import getStaffList from '@salesforce/apex/NatoutTripStaffController.getStaffList';
import { createRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { reduceErrors } from 'c/ldsUtils';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import TRIP_STAFF_OBJECT from '@salesforce/schema/National_Outings_Trip_Staff__c';
import ROLE_FIELD from '@salesforce/schema/National_Outings_Trip_Staff__c.Role__c';

const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];
const readOnlyColumns = [
    { label: 'Name', fieldName: 'fullName'},
    { label: 'Role', fieldName: 'Role__c'} //, 
];
const editColumns = [
    { label: 'Name', fieldName: 'fullName'},
    { label: 'Role', fieldName: 'Role__c'}, 
    { type: 'action', typeAttributes: { rowActions: actions } }
];

export default class NatoutTripStaff extends LightningElement {
    @api recordId = '';
    @api canEdit = false;
    @track staffList = [];
    @track isModalOpen = false;
    @track searchingContacts = false;
    @track staffToUpdate = {};
    @track savingStaff = false;
    wiredStaff;
    editRole = null;

    @wire(getStaffList, {tripId: '$recordId'})
    wiredStaffList(result) {
        if (result.data) {
            this.wiredStaff = result;
            this.staffList = result.data.map(row => {
                let fullName = row.Contact__r ? row.Contact__r.FirstName + ' ' + row.Contact__r.LastName : 'Unknown';
                let newRow = {...row , fullName};
                return newRow;
            });
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.staffList = undefined;
        }
    }

    @wire(getObjectInfo, { objectApiName: TRIP_STAFF_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ROLE_FIELD})
    rolePicklistValues;    

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        let retrievedStaff = row;
        switch (action.name) {
            case 'edit':
                this.staffToUpdate = {
                    Id: retrievedStaff.Id,
                    Contact__c: retrievedStaff.Contact__c,
                    Role__c: retrievedStaff.Role__c,
                    TripName: retrievedStaff.National_Outings_Trip__r.Name,
                    FirstName: retrievedStaff.Contact__r ? retrievedStaff.Contact__r.FirstName : 'Unknown',
                    LastName: retrievedStaff.Contact__r ? retrievedStaff.Contact__r.LastName : ''
                };
                this.searchingContacts = false;
                this.editRole = this.staffToUpdate.Role__c;
                this.openModal();
                break;
            case 'delete':
                // eslint-disable-next-line no-alert
                if(confirm('Delete this Staff Member?')) {
                    this.savingStaff = true;
                    deleteRecord(retrievedStaff.Id)
                    .then(() => {
                        this.savingStaff = false;
                        this.showSnackbar('success','Success','Staff Member Deleted');
                        return refreshApex(this.wiredStaff);
                    })
                    .catch(error => {
                        this.savingStaff = false;
                        this.showSnackbar('failure','Error deleting record',reduceErrors(error).join(', '));
                    });                    
                }
                break;
            default:
        }
    }
    openModal() {
        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
    }
    searchContacts() {
        this.searchingContacts = true;
    }
    setContact(e) {
        let selectedContact = e.detail;
        if(selectedContact.contactId) {
            this.staffToUpdate.Contact__c = selectedContact.contactId;
            this.staffToUpdate.FirstName = selectedContact.firstName;
            this.staffToUpdate.LastName = selectedContact.lastName;
        }
        else if(selectedContact === 'Unknown') {
            this.staffToUpdate.Contact__c = null;
            this.staffToUpdate.FirstName = 'Unknown';
            this.staffToUpdate.LastName = '';
        }
        this.searchingContacts = false; 
        this.editRole = this.staffToUpdate.Role__c;
    }
    setRole(e) {        
        this.staffToUpdate.Role__c = e.target.value;
    }

    retrieveList() {
        getStaffList({tripId: this.recordId})
            .then(result => {
                this.staffList = result.map(row => {
                    let fullName = row.Contact__r.FirstName + ' ' + row.Contact__r.LastName;
                    let newRow = {...row , fullName}
                    return newRow;
                });
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.showSnackbar('failure','Error Retrieving List',reduceErrors(error).join(', '));
            });
    }

    createNewStaff(e) {
        e.preventDefault();
        this.staffToUpdate = {
            National_Outings_Trip__c: this.recordId,
            Contact__c: null,
            FirstName: 'Unknown',
            LastName: ''
        };
        this.editRole = null;
        this.searchingContacts = true;
        this.openModal();
    }
    saveStaff() {
        let staffRecord = {
            Id: this.staffToUpdate.Id,
            National_Outings_Trip__c: this.staffToUpdate.National_Outings_Trip__c,
            Contact__c: this.staffToUpdate.Contact__c,
            Role__c: this.staffToUpdate.Role__c
        };

        let inputCmp = this.template.querySelector("[data-field='Role__c']")
        let isOK = inputCmp.reportValidity();
        if(isOK) {
            this.savingStaff = true;
            if(staffRecord.Id) {
                updateRecord ({
                        fields: staffRecord
                })
                .then(result => {
                    this.message = result;
                    this.error = undefined;
                    this.savingStaff = false;
                    this.showSnackbar('success','Staff Updated','Staff successfully updated');
                    if(staffRecord.Role__c === 'Leader') {
                        const leaderUpdatedEvent = new CustomEvent("leaderupdated",
                            {detail: {}}
                        );
                        this.dispatchEvent(leaderUpdatedEvent);
                    }
    
                    return refreshApex(this.wiredStaff);
                })
                .catch(error => {
                    this.error = error;
                    this.savingStaff = false;
                    this.showSnackbar('failure','Staff Update Failed',reduceErrors(error).join(', '));
                });
            } else {
                createRecord ({
                    apiName: "National_Outings_Trip_Staff__c",
                    fields: staffRecord
                })
                .then(result => {
                    this.message = result;
                    this.error = undefined;
                    this.savingStaff = false;
                    this.showSnackbar('success','Staff Member Added','Staff successfully added');
                    return refreshApex(this.wiredStaff);
                })
                .catch(error => {
                    this.error = error;
                    this.savingStaff = false;
                    this.showSnackbar('failure','Staff Update Failed',reduceErrors(error).join(', '));
                });
            }
            this.closeModal();
        }
    }
    get roleOptions() {
        let staffList = this.staffList;
        //remove roles that have already been filled for this trip
        let availableRoles = this.rolePicklistValues.data.values.filter(function(picklistValue) {
            return ! staffList.find(function(staffValue) {
                return picklistValue.value === staffValue.Role__c;
            });
        });        
        //if editing, add current role to list and sort
        if(this.editRole != null) {
            availableRoles.push({label: this.editRole, value: this.editRole});
            availableRoles.sort(function(a, b) {
                let comparison = 0;
                if (a.value > b.value) {
                  comparison = 1;
                } else if (a.value < b.value) {
                  comparison = -1;
                }
                return comparison;                
            });
            this.editRole = null;
        }
        return availableRoles;
    }
    get columns() {
        if(this.canEdit) {
            return editColumns;
        }
        return readOnlyColumns;
    }
    showSnackbar(type, header, text) {
        this.template.querySelector('c-snackbar').show(type, header, text);
    }
    @api getTripRoles() {
        let roleList = [];
        for(let i=0; i < this.staffList.length; i++) {
            roleList.push({
                label: this.staffList[i].Role__c,
                value: this.staffList[i].Role__c
            });
        }
        roleList.sort(function(a, b) {
            let comparison = 0;
            if (a.value > b.value) {
              comparison = 1;
            } else if (a.value < b.value) {
              comparison = -1;
            }
            return comparison;                
        });
        return roleList;
    }
    @api allStaffAssigned() {
        let retVal = true;
        for(let i=0; i < this.staffList.length; i++) {
            if(this.staffList[i].fullName === 'Unknown') {
                retVal = false;
            }
        }
        return retVal;
    }
}