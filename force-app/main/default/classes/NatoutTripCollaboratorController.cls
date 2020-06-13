public with sharing class NatoutTripCollaboratorController {
    @AuraEnabled (cacheable=true)
    public static List<National_Outings_Trip_Collaborator__c> getCollaboratorList(String tripId) {
        List<National_Outings_Trip_Collaborator__c> collaboratorList = [
            SELECT Id, Contact__r.Name, Access__c
            FROM National_Outings_Trip_Collaborator__c
            WHERE National_Outings_Trip__c = :tripId
        ];
        return collaboratorList;
    }
}