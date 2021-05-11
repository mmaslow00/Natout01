trigger NatoutTripTrigger on National_Outings_Trip__c (before insert, after insert, before update, after update, before delete) {
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
        else if(trigger.isBefore) {
            NatoutTripTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    else if(Trigger.isDelete) {
        if(Trigger.isBefore) {
            NatoutTripTriggerHandler.beforeDelete(Trigger.old);
        }
    }
}