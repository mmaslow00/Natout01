public with sharing class NatoutTripListController {
    @AuraEnabled(cacheable=false)
    public static List<National_Outings_Trip__c> getTripList(NatoutTripListSearchCriteria searchCriteria) {
        Date beginDate, endDate;
        String subcomm;
        String status;
        String tripType;
        String tripState;
        String searchTerm;
        if(String.isNotEmpty(searchCriteria.dtBegin)) {
            beginDate = Date.valueOf(searchCriteria.dtBegin);
        }
        if(String.isNotEmpty(searchCriteria.dtEnd)) {
            endDate = Date.valueOf(searchCriteria.dtEnd);
        }
        String sql = 
            'SELECT Id, Name, Start_Date__c, Status__c, Subcommittee__c, Trip_Type__c, OwnerId ' +
            'FROM National_Outings_Trip__c ';

        String whereClause = '';
        if(beginDate != null) {
            whereClause = appendToWhere(whereClause, 'Start_Date__c >= :beginDate');
        }
        if(endDate != null) {
            whereClause = appendToWhere(whereClause, 'Start_Date__c <= :endDate');
        }
        if(searchCriteria.userTrips) {
            whereClause = appendToWhere(whereClause, 'OwnerId = \'' + UserInfo.getUserId() + '\'');
        } else {
            if(searchCriteria.subcomm != 'any') {
                subcomm = searchCriteria.subcomm;
                whereClause = appendToWhere(whereClause, 'Subcommittee__c = :subcomm');
            }
            if(searchCriteria.status != 'any') {
                status = searchCriteria.status;
                whereClause = appendToWhere(whereClause, 'Status__c = :status');
            }
            if(searchCriteria.type != 'any') {
                tripType = searchCriteria.type;
                whereClause = appendToWhere(whereClause, 'Trip_Type__c = :tripType');
            }
            if(searchCriteria.state != 'any' && searchCriteria.state != 'All') {
                tripState = searchCriteria.state;
                whereClause = appendToWhere(whereClause, 'States__c includes (:tripState)');
            }
            if(String.isNotBlank(searchCriteria.nameMatch)) {
                searchTerm = '%' + searchCriteria.nameMatch + '%';
                whereClause = appendToWhere(whereClause, 'Name like :searchTerm');
            }
        }
        if(whereClause.length() > 0) {
            sql = sql + 'WHERE ' + whereClause;
        }
        sql = sql + ' ORDER BY Start_Date__c desc';

        List<National_Outings_Trip__c> tripList = Database.query(sql);
        return tripList;
    }
    private static String appendToWhere(String original, String toAppend) {
        if(original.length() > 0) {
            original = original + ' AND ';
        }
        return original + toAppend;
    }
}