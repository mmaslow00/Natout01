trigger NatoutTripCommentsTrigger on National_Outings_Trip_Comments__c (after insert) {
    List<TriggeredSendEmail__c> tseList = NatoutEmailHandler.notifyOfComments(Trigger.new);
    //insert tseList;
    for(TriggeredSendEmail__c email : tseList) {
        System.debug('email: ' + email);
    }
}