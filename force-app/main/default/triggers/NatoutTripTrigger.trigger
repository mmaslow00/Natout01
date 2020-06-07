trigger NatoutTripTrigger on National_Outings_Trip__c (before insert, after insert) {
    if(Trigger.isInsert) {
        if(Trigger.isBefore) {
            NatoutTripTriggerHandler.beforeInsert(Trigger.new);
        }
        else {
            NatoutTripTriggerHandler.afterInsert(Trigger.new);
        }
    }
}