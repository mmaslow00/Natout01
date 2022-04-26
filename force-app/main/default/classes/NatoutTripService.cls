public with sharing class NatoutTripService {
    @AuraEnabled
    public static Decimal getTripPrice(String tripId) {
        Decimal retVal = null;
        List<Campaign> campList = [
            SELECT Id, Trip_Price__c
            FROM Campaign
            WHERE Name = :tripId
        ];
        if(campList.size() > 0) {
            retVal = campList[0].Trip_Price__c;
            if(retVal == null) {
                retVal = 0;
            }
        }
        return retVal;
    }
    @AuraEnabled
    public static ShipTo getSatPhoneAddr(String tripId) {
        National_Outings_Trip_Staff__c leader = [
            SELECT  
            Contact__r.Name,
            Contact__r.MailingStreet,
            Contact__r.MailingCity,
            Contact__r.MailingState,
            Contact__r.MailingPostalCode,
            Contact__r.Phone,
            Contact__r.Email
            FROM National_Outings_Trip_Staff__c
            WHERE 
                National_Outings_Trip__c = :tripId
                AND Contact__c != null
                AND Role__c = 'Leader'
        ];
        ShipTo to = new ShipTo();
        to.name = leader.Contact__r.Name;
        to.address = leader.Contact__r.MailingStreet;
        to.city = leader.Contact__r.MailingCity;
        to.state = leader.Contact__r.MailingState;
        to.zip = leader.Contact__r.MailingPostalCode;
        to.phone = leader.Contact__r.Phone;
        to.email = leader.Contact__r.email;
        return to;
    }
    @AuraEnabled
    public static BudgetApproval approveBudget(String tripId) {
        Datetime now = System.now();
        Id userId = UserInfo.getUserId();
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Id = tripId,
            Budget_Approved_Date__c = now,
            Budget_Approved_By__c = userId
        );
        update trip;
        return new BudgetApproval(now, userId);
    }
    @AuraEnabled
    public static BudgetApproval returnBudget(String tripId) {
        Id userId = UserInfo.getUserId();
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Id = tripId,
            Budget_Approved_Date__c = null,
            Budget_Approved_By__c = userId,
            Status__c = 'Returned'
        );
        update trip;
        return new BudgetApproval(null, userId);
    }
    @AuraEnabled 
    public static StaffApprovals getStaffApprovals(String tripId) {
        System.debug('retrieving trip');
        National_Outings_Trip__c trip = [
            SELECT 
                Approve_Budget_Date__c,
                Approve_Budget_User__r.Name,
                Approve_Marketing_Date__c,
                Approve_Marketing_User__r.Name,
                Approve_Permits_Date__c,
                Approve_Permits_User__r.Name,
                Approve_Vendors_Date__c,
                Approve_Vendors_User__r.Name
            FROM National_Outings_Trip__c
            WHERE Id = :tripId
        ];
        StaffApprovals approvals = new StaffApprovals(trip);
        System.debug('approvals: ' + approvals);
        return approvals;
    }
    @AuraEnabled 
    public static StaffApprovals updateStaffApprovals(String tripId, Boolean budget, Boolean marketing, Boolean permits, Boolean vendors) {
        if(budget || marketing || permits || vendors) {
            National_Outings_Trip__c trip = new National_Outings_Trip__c(Id=tripId);
            if(budget) {
                trip.Approve_Budget_Date__c = System.now();
                trip.Approve_Budget_User__c = System.UserInfo.getUserId();
            }
            if(marketing) {
                trip.Approve_Marketing_Date__c = System.now();
                trip.Approve_Marketing_User__c = System.UserInfo.getUserId();
            }
            if(permits) {
                trip.Approve_Permits_Date__c = System.now();
                trip.Approve_Permits_User__c = System.UserInfo.getUserId();
            }
            if(vendors) {
                trip.Approve_Vendors_Date__c = System.now();
                trip.Approve_Vendors_User__c = System.UserInfo.getUserId();
            }
            update trip;
        }
        return getStaffApprovals(tripId);
    }
    @AuraEnabled(cacheable=true)
    public static List<National_Outings_Trip_Status_History__c> getStatusHistory(String tripId) {
        List<National_Outings_Trip_Status_History__c> histList = [
            SELECT Id, CreatedDate, Status__c, User__r.Name 
            FROM National_Outings_Trip_Status_History__c
            WHERE National_Outings_Trip__c = :tripId
            ORDER BY CreatedDate DESC
        ];
        return histList;
    }
    public Class ShipTo {
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String address {get; set;}
        @AuraEnabled
        public String city {get; set;}
        @AuraEnabled
        public String state {get; set;}
        @AuraEnabled
        public String zip {get; set;}
        @AuraEnabled
        public String phone {get; set;}
        @AuraEnabled
        public String email {get; set;}
    }
    public Class BudgetApproval {
        BudgetApproval(Datetime dateApproved, Id approvedBy) {
            this.dateApproved = dateApproved;
            this.approvedBy = approvedBy;
        }
        @AuraEnabled
        public Datetime dateApproved {get; set;}
        @AuraEnabled
        public String approvedBy {get; set;}
    }
    public Class StaffApprovals {
        StaffApprovals(National_Outings_Trip__c trip) {
            this.budgetUser = trip.Approve_Budget_User__r.Name;
            this.budgetDate = trip.Approve_Budget_Date__c;
            this.marketingUser = trip.Approve_Marketing_User__r.Name;
            this.marketingDate = trip.Approve_Marketing_Date__c;
            this.permitsUser = trip.Approve_Permits_User__r.Name;
            this.permitsDate = trip.Approve_Permits_Date__c;
            this.vendorsUser = trip.Approve_Vendors_User__r.Name;
            this.vendorsDate = trip.Approve_Vendors_Date__c;
        }
        @AuraEnabled
        public Datetime budgetDate {get; set;}
        @AuraEnabled
        public String budgetUser {get; set;}
        @AuraEnabled
        public Datetime marketingDate {get; set;}
        @AuraEnabled
        public String marketingUser {get; set;}
        @AuraEnabled
        public Datetime permitsDate {get; set;}
        @AuraEnabled
        public String permitsUser {get; set;}
        @AuraEnabled
        public Datetime vendorsDate {get; set;}
        @AuraEnabled
        public String vendorsUser {get; set;}
    }
}
