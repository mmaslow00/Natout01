public without sharing class NatoutUserInfo {
    public static Id getContactId() {
        Id userId = System.UserInfo.getUserId();
        Id contactId;
        if(System.UserInfo.getUserType() == 'Standard') {
            contactId = [select Contact__c from User_Lookups__c where User__c = :userId].Contact__c;
        }
        else {
            contactId = [select ContactId from User where Id=:userId].ContactId;
        }
        return contactId;
    }
    @AuraEnabled (cacheable=true)
    public static UserAccess getUserAccess(String tripId) {
        Id userId = System.UserInfo.getUserId();
        Id contactId = getContactId();
        UserAccess uAccess = new UserAccess();

        /* National Outings Admins get full access */
        AggregateResult[] rslt = [
            SELECT COUNT(Id) cnt FROM National_Outings_Admin__c
            WHERE User__c = :userId
        ];
        Integer count = (Integer)rslt[0].get('cnt');
        if(count > 0) {
            uAccess.canEdit = true;
            uAccess.canApprove = true;
            uAccess.isAdmin = true;
            uAccess.canApproveBudget = canApproveBudget(contactId);
            return uAccess;
        }

        if(String.isEmpty(tripId)) {
            return uAccess;
        }

        National_Outings_Trip__c trip = [
            SELECT Id, OwnerId, Status__c, Subcommittee__c, Budget_Approved_Date__c
            FROM National_Outings_Trip__c
            WHERE Id = :tripId
        ];

        /* Trip creators get edit access until status is set to submitted */
        if(trip.OwnerId == userId) {
            if(trip.Status__c == 'Started' || trip.Status__c == 'Returned' || trip.Status__c == null) {
                uAccess.canEdit = true;
            }
        }

        /* Certain subcomittee positions get approval access */
        String subcommName = trip.Subcommittee__c;
        List<Leadership__c> ldrList = [
            SELECT Id FROM Leadership__c WHERE
            Contact__c = :contactId
            AND Club_Entity__r.Entity_Category__c = 'Outings' AND Club_Entity__r.Type__c = 'National Outing Subcomm' 
            AND Position_Status__c = 'Active' AND Leader_Position__r.Name IN ('Chair','Sub-comm Co-Chair','Vice Chair')
            AND Club_Entity__r.Name = :subcommName
        ];
        if( ! ldrList.isEmpty()) {
            switch on trip.Status__c {
                when 'Started', 'Returned', 'Submitted' {
                    uAccess.canApprove = true;
                    uAccess.canEdit = true;
                }
            }
        }

        /* Collaborators get appropriate access */
        if( ! (uAccess.canEdit && uAccess.canApprove) ) {
            List<National_Outings_Trip_Collaborator__c> collabList = [
                SELECT Access__c 
                FROM National_Outings_Trip_Collaborator__c
                WHERE Contact__c = :contactId AND National_Outings_Trip__c = :trip.Id
            ];
            for(National_Outings_Trip_Collaborator__c collab : collabList) {
                if(collab.Access__c == 'Approve') {
                    switch on trip.Status__c {
                        when 'Started', 'Returned', 'Submitted' {
                            uAccess.canApprove = true;
                            uAccess.canEdit = true;
                        }
                    }
                }
                else {
                    switch on trip.Status__c {
                        when 'Started', 'Returned' {
                            uAccess.canEdit = true;
                        }
                    }
                }
            }
        }
        if(trip.Status__c == 'Started' || trip.Status__c == 'Returned') {
            if(trip.Budget_Approved_Date__c == null) {
                uAccess.canApproveBudget = canApproveBudget(contactId);
                if(uAccess.canApproveBudget) {
                    uAccess.canEdit = true;
                }
            }
        }

        return uAccess;
    }
    public static Boolean canApproveBudget(String contactId) {
        List<Leadership__c> approverList = [
            SELECT
                Contact__c, 
                Contact__r.Email
            FROM Leadership__c 
            WHERE
                Contact__c = :contactId
                AND Club_Entity__r.Entity_Category__c = 'Outings' AND Club_Entity__r.Type__c = 'National Outing Subcomm' 
                AND Club_Entity__r.Name = 'International'
                AND Position_Status__c = 'Active' AND Leader_Position__r.Name = 'Trip Submission Approver'
        ];
        return ! approverList.isEmpty();
    }
    public class UserAccess {
        public UserAccess() {
            this.canEdit = false;
            this.canApprove = false;
            this.isAdmin = false;
            this.canApproveBudget = false;
        }
        @AuraEnabled
        public Boolean canEdit {get; set;}
        @AuraEnabled
        public Boolean canApprove {get; set;}
        @AuraEnabled
        public Boolean isAdmin {get; set;}
        @AuraEnabled
        public Boolean canApproveBudget {get; set;}
    }
}