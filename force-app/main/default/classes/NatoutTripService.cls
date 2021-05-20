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
            Contact__r.MailingPostalCode
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
}
