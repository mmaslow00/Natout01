public with sharing class NatoutTripCommentsController {
    @AuraEnabled (cacheable=true)
    public static List<National_Outings_Trip_Comments__c> getCommentsList(String tripId) {
        List<National_Outings_Trip_Comments__c> commentsList = [
            SELECT Id, CreatedBy.Name, CreatedDate, Comments__c,
            (SELECT Id, Contact__r.Name, Email__c, Staff_Position__c FROM National_Outings_Trip_Comments_Recips__r)
            FROM National_Outings_Trip_Comments__c
            WHERE National_Outings_Trip__c = :tripId
            ORDER BY CreatedDate
        ];
        return commentsList;
    }
}
