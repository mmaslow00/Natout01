public with sharing class NatoutLeaderSearchController {
    @AuraEnabled (cacheable=true)
    public static List<SearchResult> getLeaderList(String lastName, String firstName) {
        lastName = lastName + '%';
        if( ! String.isEmpty(firstName)) {
            firstName = firstName + '%';
        }
        String sql = 'SELECT Contact__c contactId, Contact__r.FirstName firstName, Contact__r.LastName lastName ' +
            'FROM Leadership__c ' +
            'WHERE ' +
            'Club_Entity__r.Type__c = \'National Outing Subcomm\' ' +
            'AND Position_Status__c = \'Active\' ' +
            'AND Contact__r.LastName LIKE :lastName ';
        if( ! String.isEmpty(firstName)) {
            sql += 'AND Contact__r.FirstName LIKE :firstName ';
        }
        sql += 'GROUP BY Contact__c, Contact__r.FirstName, Contact__r.LastName ' +
            'ORDER BY Contact__r.LastName, Contact__r.FirstName';
        
        AggregateResult[] groupedResults = Database.query(sql);
        List<SearchResult> resultList = new List<SearchResult>();
        for (AggregateResult ar : groupedResults)  {
            SearchResult result = new SearchResult();
            result.contactId = (String)ar.get('contactId');
            result.firstName = (String)ar.get('firstName');
            result.lastName = (String)ar.get('lastName');
            resultList.add(result);
        }
        return resultList;
    }
    @TestVisible private class SearchResult {
        @AuraEnabled
        public String contactId {get; set;}
        @AuraEnabled
        public String firstName {get; set;}
        @AuraEnabled
        public String lastName {get; set;}
    }
}