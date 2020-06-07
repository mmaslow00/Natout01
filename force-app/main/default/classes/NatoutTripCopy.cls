public with sharing class NatoutTripCopy {
    public NatoutTripCopy() {
    }
    @AuraEnabled
    public static String copy(String tripId) {
        String retVal = null;
        String query = 'SELECT ' + 
            getFieldList('National_Outings_Trip__c') +
            ' FROM National_Outings_Trip__c WHERE Id = :tripId';
        National_Outings_Trip__c fromTrip = Database.query(query);
        National_Outings_Trip__c toTrip = fromTrip.clone(false, true, false, false);
        toTrip.Name = 'Copy of ' + fromTrip.Name;
        Database.SaveResult rslt = Database.insert(toTrip);
        if( ! rslt.isSuccess()) {
            return null;
        }
        retVal = rslt.getId();

        List<SObject> relObjList = new List<SObject>();
        relObjList.addAll(getRelatedObjList('National_Outings_Trip_Budget_Item__c', tripId, retVal));
        relObjList.addAll(getRelatedObjList('National_Outings_Trip_Permit__c', tripId, retVal));
        relObjList.addAll(getRelatedObjList('National_Outings_Trip_Agency__c', tripId, retVal));
        relObjList.addAll(getRelatedObjList('National_Outings_Trip_Itinerary__c', tripId, retVal));
        relObjList.addAll(getRelatedObjList('National_Outings_Trip_Vendor__c', tripId, retVal));
        List<Database.SaveResult> rsltList = Database.insert(relObjList);

        return retVal;
    }
    @AuraEnabled
    public static void markUploaded(List<String> idList) {
        List<National_Outings_Trip__c> tripsToUpdate = new List<National_Outings_Trip__c>();
        for(String tripId : idList) {
            tripsToUpdate.add(new National_Outings_Trip__c(Id = tripId, Status__c = 'Uploaded to TRAIL'));
        }
        update tripsToUpdate;
    }

    private static List<SObject> getRelatedObjList(String objName, Id fromTripId, Id toTripId) {
        List<SObject> toObjList = new List<SObject>();

        String query = 'SELECT ' +
            getFieldList(objName) +
            ' FROM ' + objName + ' WHERE National_Outings_Trip__c = :fromTripId';
        List<SObject> fromObjList = Database.query(query);
        for(SObject fromObj : fromObjList) {
            SObject toObj = fromObj.clone(false, true, false, false);
            toObj.put('National_Outings_Trip__c', toTripId);
            toObjList.add(toObj);
        }

        return toObjList;
    }

    private static String getFieldList(String objName) {
        Map <String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
        List<String> fieldNames = new List<String>();
        for( String fieldName : fieldMap.keySet() ) {
            Schema.SObjectField field = fieldMap.get(fieldName);
            if(field.getDescribe().isUpdateable()) {
                fieldNames.add( fieldName );
            }
        }
        return String.join(fieldNames, ','); 
    }
}