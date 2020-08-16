public with sharing class NatoutEmailHandler {
    public static final String testEmailAddr = 'mmaslow00@gmail.com';

    public static List<TriggeredSendEmail__c> statusChanged(List<National_Outings_Trip__c> tripList, Map<Id, National_Outings_Trip__c> oldMap) {
        Map<Id, National_Outings_Trip__c> tripMap = new Map<Id, National_Outings_Trip__c>();
        Set<String> subcomms = new Set<String>();
        Map<String, List<Recipient>> officerMap = new Map<String, List<Recipient>>();
        Map<Id, List<Recipient>> collaboratorMap = new Map<Id, List<Recipient>>();
        Map<Id, Recipient> leaderMap = new Map<Id, Recipient>();
        List<TriggeredSendEmail__c> tseList = new List<TriggeredSendEmail__c>();

        for(National_Outings_Trip__c trip : tripList) {
            National_Outings_Trip__c oldTrip = oldMap.get(trip.Id);
            if(trip.Status__c != oldTrip.Status__c) {
                tripMap.put(trip.Id, trip);
                subcomms.add(trip.Subcommittee__c);
            }
        }
        List<Leadership__c> subcommOfficerList = [
            SELECT
                Club_Entity__r.Name,
                Contact__c, 
                Contact__r.Email
            FROM Leadership__c 
            WHERE
                Club_Entity__r.Entity_Category__c = 'Outings' AND Club_Entity__r.Type__c = 'National Outing Subcomm' 
                AND Position_Status__c = 'Active' AND Leader_Position__r.Name IN ('Chair','Sub-comm Co-Chair','Vice Chair')
                AND Club_Entity__r.Name in :subcomms
        ];
        for(Leadership__c ldr : subcommOfficerList) {
            List<Recipient> recipientList = officerMap.get(ldr.Club_Entity__r.Name);
            if(recipientList == null) {
                recipientList = new List<Recipient>();
            }
            recipientList.add(new Recipient(ldr.Contact__c, ldr.Contact__r.Email));
            officerMap.put(ldr.Club_Entity__r.Name, recipientList);
        }

        Set<Id> tripIds = tripMap.keySet();
        List<National_Outings_Trip_Collaborator__c> collabList = [
            SELECT
                National_Outings_Trip__c, 
                Access__c,
                Contact__c,
                Contact__r.Email
            FROM National_Outings_Trip_Collaborator__c
            WHERE National_Outings_Trip__c in :tripIds
        ];
        for(National_Outings_Trip_Collaborator__c collab : collabList) {
            if(collab.Access__c == 'Approve') {
                List<Recipient> recipientList = collaboratorMap.get(collab.National_Outings_Trip__c);
                if(recipientList == null) {
                    recipientList = new List<Recipient>();
                }
                recipientList.add(new Recipient(collab.Contact__c, collab.Contact__r.Email));
                collaboratorMap.put(collab.National_Outings_Trip__c, recipientList);
            }
        }

        List<National_Outings_Trip_Staff__c> tripLeaderList = [
            SELECT National_Outings_Trip__c, Contact__c, Contact__r.Email
            FROM National_Outings_Trip_Staff__c
            WHERE 
                Role__c = 'Leader'
                AND National_Outings_Trip__c in :tripIds
        ];
        for(National_Outings_Trip_Staff__c staff : tripLeaderList) {
            leaderMap.put(staff.National_Outings_Trip__c, new Recipient(staff.Contact__c, staff.Contact__r.Email));
        }

        for(National_Outings_Trip__c trip : tripList) {
            National_Outings_Trip__c prevTrip = oldMap.get(trip.Id);
            if((prevTrip.Status__c == 'Started' || prevTrip.Status__c == 'Returned')) {
                if(trip.Status__c == 'Submitted') {
                    List<Recipient> recipientList = new List<Recipient>();
                    recipientList.addAll(officerMap.get(trip.Subcommittee__c));
                    List<Recipient> collaborators = collaboratorMap.get(trip.Id);
                    if(collaborators != null) {
                        recipientList.addAll(collaborators);
                    }

                    String msgText = startedToSubmittedText(trip.Name);
                    String msgPrefix = 'In production, this email would be sent to: \n';
                    String subject = 'Trip submission for ' + trip.Name + ' ready for review';
                    for(Recipient rcp : recipientList) {
                        msgPrefix += rcp.emailAddr + '\n';
                    }
                    String textToSend = msgPrefix + '\n\n' + msgText;
                    for(Recipient rcp : recipientList) {
                        //rcp.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, textToSend));
                        tseList.add(createTriggeredSend(rcp.contactId, testEmailAddr, subject, textToSend));
                    }
                }
            }
            else if(prevTrip.Status__c == 'Submitted' && trip.Status__c == 'Approved by Chair') {
                Recipient recip = leaderMap.get(trip.Id);
                String msgText = submittedToApprovedByChairText(trip.Name, trip.Subcommittee__c);
                String subject = 'Trip submission for ' + trip.Name + ' approved by chair and/or collaborator';
                String msgPrefix = 'In production, this email would be sent to: \n';
                msgPrefix += recip.emailAddr + '\n';
                String textToSend = msgPrefix + '\n\n' + msgText;
                tseList.add(createTriggeredSend(recip.contactId, testEmailAddr, subject, textToSend));
            }
            else if(prevTrip.Status__c == 'Approved by Chair' && trip.Status__c == 'Approved by Staff') {
                Recipient recip = leaderMap.get(trip.Id);                
                String msgText = approvedByChairToApprovedByStaffText(trip.Name);
                String subject = 'Trip submission for ' + trip.Name + ' approved by staff';
                String msgPrefix = 'In production, this email would be sent to: \n';
                msgPrefix += recip.emailAddr + '\n';
                String textToSend = msgPrefix + '\n\n' + msgText;
                tseList.add(createTriggeredSend(recip.contactId, testEmailAddr, subject, textToSend));
            }
            else if(prevTrip.Status__c == 'Submitted' && trip.Status__c == 'Returned') {
                Recipient recip = leaderMap.get(trip.Id);                
                String msgText = submittedToReturnedText(trip.Name, trip.Subcommittee__c);
                String subject = 'Trip submission for ' + trip.Name + ' returned';
                String msgPrefix = 'In production, this email would be sent to: \n';
                msgPrefix += recip.emailAddr + '\n';
                String textToSend = msgPrefix + '\n\n' + msgText;
                tseList.add(createTriggeredSend(recip.contactId, testEmailAddr, subject, textToSend));
            }
        }
        return tseList;
    }

    private static String startedToSubmittedText(String tripName) {
        String msg = 
            'Trip submission for ' +
            tripName + ' ' +
            'has been submitted and is now ready for your review. ' +
            'If you’re satisfied with it, select “Approved by Chair,” and it will be sent to staff for processing. ' +
            'You may also make adjustments or add comments at the end of the form before approving. ' + 
            'If you’re not satisfied with it, add any questions or requested changes to the comments section ' +
            'and select “Returned” to return it back to the trip leader for further edits.'
            ;
        return msg;
    }
    private static String submittedToApprovedByChairText(String tripName, String subCommName) {
        String msg =
            'Trip submission ' +
            tripName + ' ' +
            'has been approved the ' +
            subCommName + ' ' +
            'Subcommittee Chair and/or collaborators. ' +
            'Your trip will now be sent to staff for processing. ' +
            'You will be notified once the trip has been approved by staff or if there are questions or changes required.'
            ;
        return msg;
    }
    private static String approvedByChairToApprovedByStaffText(String tripName) {
        String msg =
            'Trip submission ' +
            tripName + ' ' +
            'has been approved by staff. ' +
            'If there are any changes to your trip now that it is in the system, ' +
            'please notify tony.rango@sierraclub.org and copy your subcommittee chair so that all parties are in the loop.'
        ;
        return msg;
    }
    private static String submittedToReturnedText(String tripName, String subCommName) {
        String msg = 
            'Trip Submission for ' + tripName + ' ' +
            'has been reviewed by the ' + subCommName + ' ' +
            'Subcommittee Chair, collaborators, and/or staff ' +
            'being returned to you with questions or requested changes. ' +
            'Please review the comments at the end of the trip submission form for an explanation of why it was returned. ' +
            'Once you’ve addressed these questions or changes, you may resubmit, with comments if necessary.' 
        ;
        return msg;
    }

    private static TriggeredSendEmail__c createTriggeredSend(Id contactId, String emailAddr, String subject, String msg) {
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeFieldName('To');
        gen.writeStartObject();
        gen.writeStringField('Address', emailAddr);
        gen.writeStringField('SubscriberKey', contactId);
        gen.writeFieldName('ContactAttributes');
        gen.writeStartObject();
        gen.writeFieldName('SubscriberAttributes');
        gen.writeStartObject();
        gen.writeStringField('Subject', subject);
        gen.writeStringField('MessageBody', msg);
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndObject();
        gen.close();
        
        TriggeredSendEmail__c triggeredSend = new TriggeredSendEmail__c (
            Email__c = emailAddr,
            SubscriberKey__c = contactId,
            RequestBody__c = gen.getAsString(),
            SendId__c = 'nat-trip-sub'
        );
        return triggeredSend;
    }
    private class Recipient {
        public recipient(Id contactId, String emailAddr) {
            this.contactId = contactId;
            this.emailAddr = emailAddr;
        }
        String emailAddr;
        Id contactId;
    }
}
