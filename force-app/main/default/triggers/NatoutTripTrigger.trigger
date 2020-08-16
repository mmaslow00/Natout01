trigger NatoutTripTrigger on National_Outings_Trip__c (before insert, after insert, after update) {
    if(Trigger.isInsert) {
        if(Trigger.isBefore) {
            NatoutTripTriggerHandler.beforeInsert(Trigger.new);
        }
        else {
            NatoutTripTriggerHandler.afterInsert(Trigger.new);
        }
    }
    else if(Trigger.isUpdate) {
        if(Trigger.isAfter) {
            NatoutTripTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}