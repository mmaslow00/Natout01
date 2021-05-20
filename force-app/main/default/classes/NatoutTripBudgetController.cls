public with sharing class NatoutTripBudgetController {
    @AuraEnabled(cacheable = true)
    public static List<National_Outings_Trip_Budget_Item__c> getVolTravelList(String tripId) {
        List<National_Outings_Trip_Budget_Item__c> budgetList = [
            SELECT Id, Item_Category__c, Amount__c, Factor_Type__c, Staff_Role__c  
            FROM National_Outings_Trip_Budget_Item__c
            WHERE National_Outings_Trip__c = :tripId
                AND Budget_Category__c = 'Volunteer Travel'
        ];
        return budgetList;
    }  
    @AuraEnabled(cacheable = true)
    public static List<National_Outings_Trip_Budget_Item__c> getMealsList(String tripId) {
        List<National_Outings_Trip_Budget_Item__c> budgetList = [
            SELECT Id, Item_Category__c, Day_Number__c, Participant_Amount__c, Staff_Amount__c, Number_Participants__c, Number_Staff__c
            FROM National_Outings_Trip_Budget_Item__c
            WHERE National_Outings_Trip__c = :tripId
                AND Budget_Category__c = 'Meals'
            ORDER BY Day_Number__c
        ];
        return budgetList;
    }  
    @AuraEnabled(cacheable = true)
    public static List<National_Outings_Trip_Budget_Item__c> getTransportationList(String tripId) {
        List<National_Outings_Trip_Budget_Item__c> budgetList = [
            SELECT Id, Item_Category__c, Option__c, Amount__c
            FROM National_Outings_Trip_Budget_Item__c
            WHERE National_Outings_Trip__c = :tripId
                AND Budget_Category__c = 'Transportation'
        ];
        return budgetList;
    }  
    @AuraEnabled(cacheable = true)
    public static List<National_Outings_Trip_Budget_Item__c> getConcessionaireList(String tripId) {
        List<National_Outings_Trip_Budget_Item__c> budgetList = [
            SELECT Id, Item_Category__c, Option__c, Amount__c, Number_Staff__c
            FROM National_Outings_Trip_Budget_Item__c
            WHERE National_Outings_Trip__c = :tripId
                AND Budget_Category__c = 'Concessionaires'
        ];
        return budgetList;
    }
}