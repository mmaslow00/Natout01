public with sharing class NatoutEmailHandler {
    public static final String testEmailAddr = 'mmaslow00@gmail.com';
    public static final String staffEmailAddr = 'mmaslow00+staff@gmail.com';

    public static List<TriggeredSendEmail__c> statusChanged(List<National_Outings_Trip__c> tripList, Map<Id, National_Outings_Trip__c> oldMap) {
        Map<Id, List<Recipient>> creatorMap = getCreators(tripList);
        Map<Id, List<Recipient>> approverMap = getApprovers(tripList);

        List<TriggeredSendEmail__c> tseList = new List<TriggeredSendEmail__c>();

        for(National_Outings_Trip__c trip : tripList) {
            National_Outings_Trip__c prevTrip = oldMap.get(trip.Id);
            if((prevTrip.Status__c == 'Started' || prevTrip.Status__c == 'Returned')) {
                if(trip.Status__c == 'Submitted') {
                    List<Recipient> recipientList = approverMap.get(trip.Id);
                    String msgText = startedToSubmittedText(trip.Name);
                    String subject = 'Trip submission for ' + trip.Name + ' ready for review';
                    String textToSend = getMsgPrefix(recipientList) + ' : ' + msgText;
                    for(Recipient rcp : recipientList) {
                        //rcp.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, textToSend));
                        tseList.add(createTriggeredSend(rcp.contactId, testEmailAddr, subject, textToSend));
                    }
                }
            }
            else if(prevTrip.Status__c == 'Submitted' && trip.Status__c == 'Approved by Chair') {
                List<Recipient> recipientList = creatorMap.get(trip.Id);
                String msgText = submittedToApprovedByChairText(trip.Name, trip.Subcommittee__c);
                String subject = 'Trip submission for ' + trip.Name + ' approved by chair and/or collaborator';
                String textToSend = getMsgPrefix(recipientList) + ' : ' + msgText;
                for(Recipient rcp : recipientList) {
                    //rcp.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, textToSend));
                    tseList.add(createTriggeredSend(rcp.contactId, testEmailAddr, subject, textToSend));
                }
            }
            else if(prevTrip.Status__c == 'Approved by Chair' && trip.Status__c == 'Approved by Staff') {
                List<Recipient> recipientList = creatorMap.get(trip.Id);
                String msgText = approvedByChairToApprovedByStaffText(trip.Name);
                String subject = 'Trip submission for ' + trip.Name + ' approved by staff';
                String textToSend = getMsgPrefix(recipientList) + ' : ' + msgText;
                for(Recipient rcp : recipientList) {
                    //rcp.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, textToSend));
                    tseList.add(createTriggeredSend(rcp.contactId, testEmailAddr, subject, textToSend));
                }
            }
            else if(prevTrip.Status__c == 'Submitted' && trip.Status__c == 'Returned') {
                List<Recipient> recipientList = creatorMap.get(trip.Id);
                String msgText = submittedToReturnedText(trip.Name, trip.Subcommittee__c);
                String subject = 'Trip submission for ' + trip.Name + ' returned';
                String textToSend = getMsgPrefix(recipientList) + ' : ' + msgText;
                for(Recipient rcp : recipientList) {
                    //rcp.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, textToSend));
                    tseList.add(createTriggeredSend(rcp.contactId, testEmailAddr, subject, textToSend));
                }
            }
        }
        return tseList;
    }
    private static String getMsgPrefix(List<Recipient> recipientList) {
        String emails = '';
        for(Recipient rcp : recipientList) {
            if(emails.length() > 0) {
                emails += ', ';
            }
            emails += rcp.emailAddr;
        }
        return 'In production, this email would be sent to: ' + emails;
}
    private static Map<Id, List<Recipient>> getCreators(List<National_Outings_Trip__c> tripList) {
        Set<Id> tripIds = new Set<Id>();
        for(National_Outings_Trip__c trip : tripList) {
            tripIds.add(trip.Id);
        }

        Map<Id, List<Recipient>> creatorMap = new Map<Id, List<Recipient>>();

        //Trip Leaders
        List<National_Outings_Trip_Staff__c> tripLeaderList = [
            SELECT National_Outings_Trip__c, Contact__c, Contact__r.Email
            FROM National_Outings_Trip_Staff__c
            WHERE 
                Role__c = 'Leader'
                AND National_Outings_Trip__c in :tripIds
        ];
        for(National_Outings_Trip_Staff__c staff : tripLeaderList) {
            List<Recipient> recipientList = creatorMap.get(staff.National_Outings_Trip__c);
            if(recipientList == null) {
                recipientList = new List<Recipient>();
            }
            recipientList.add(new Recipient(staff.Contact__c, staff.Contact__r.Email));
            creatorMap.put(staff.National_Outings_Trip__c, recipientList);
        }

        //Collaborators added by Leaders
        List<National_Outings_Trip_Collaborator__c> collabList = [
            SELECT
                National_Outings_Trip__c, 
                Contact__c,
                Contact__r.Email
            FROM National_Outings_Trip_Collaborator__c
            WHERE National_Outings_Trip__c in :tripIds AND Access__c = 'Edit'
        ];
        for(National_Outings_Trip_Collaborator__c collab : collabList) {
            List<Recipient> recipientList = creatorMap.get(collab.National_Outings_Trip__c);
            if(recipientList == null) {
                recipientList = new List<Recipient>();
            }
            recipientList.add(new Recipient(collab.Contact__c, collab.Contact__r.Email));
            creatorMap.put(collab.National_Outings_Trip__c, recipientList);
        }
        return creatorMap;
    }
    private static Map<Id, List<Recipient>> getApprovers(List<National_Outings_Trip__c> tripList) {
        Set<String> subcomms = new Set<String>();
        Set<Id> tripIds = new Set<Id>();

        for(National_Outings_Trip__c trip : tripList) {
            subcomms.add(trip.Subcommittee__c);
            tripIds.add(trip.Id);
        }

        //Subcommittee Officers with approval authority

        //First, create officerMap to find subcommittee officers by subcommittee name
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
        Map<String, List<Recipient>> officerMap = new Map<String, List<Recipient>>();
        for(Leadership__c officer : subcommOfficerList) {
            List<Recipient> recipientList = officerMap.get(officer.Club_Entity__r.Name);
            if(recipientList == null) {
                recipientList = new List<Recipient>();
            }
            recipientList.add(new Recipient(officer.Contact__c, officer.Contact__r.Email));
            officerMap.put(officer.Club_Entity__r.Name, recipientList);
        }

        //Now create approverMap. Contains one entry for each trip, mapped to a list of recipients
        
        Map<Id, List<Recipient>> approverMap = new Map<Id, List<Recipient>>();

        //First add list of subcommittee officers for each trip
        for(National_Outings_Trip__c trip : tripList) {
            List<Recipient> recipientList = officerMap.get(trip.Subcommittee__c);
            if(recipientList != null) {
                approverMap.put(trip.Id, recipientList);
            }
        }

        //Next. add trip collaborators with approval authority for each trip
        //(collaborators granted approval authority for specific trips)
        List<National_Outings_Trip_Collaborator__c> collabList = [
            SELECT
                National_Outings_Trip__c, 
                Access__c,
                Contact__c,
                Contact__r.Email
            FROM National_Outings_Trip_Collaborator__c
            WHERE National_Outings_Trip__c in :tripIds AND Access__c = 'Approve'
        ];

        for(National_Outings_Trip_Collaborator__c collab : collabList) {
            List<Recipient> recipientList = approverMap.get(collab.National_Outings_Trip__c);
            if(recipientList == null) {
                recipientList = new List<Recipient>();
            }
            recipientList.add(new Recipient(collab.Contact__c, collab.Contact__r.Email));
            approverMap.put(collab.National_Outings_Trip__c, recipientList);
        }
        return approverMap;
    }
    private static String startedToSubmittedText(String tripName) {
        String msg = 
            'Trip submission for ' +
            tripName + ' ' +
            'has been submitted and is now ready for your review. ' +
            'If you’re satisfied with it, select "Approved by Chair", and it will be sent to staff for processing. ' +
            'You may also make adjustments or add comments at the end of the form before approving. ' + 
            'If you’re not satisfied with it, add any questions or requested changes to the comments section ' +
            'and select "Returned" to return it back to the trip leader for further edits.'
            ;
        return msg;
    }
    private static String submittedToApprovedByChairText(String tripName, String subCommName) {
        String msg =
            'Trip submission for ' +
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
            'Trip submission for ' +
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

    public static List<TriggeredSendEmail__c> notifyOfComments(List<National_Outings_Trip_Comments__c> commentsList) {
        Set<Id> tripIds = new Set<Id>();
        for(National_Outings_Trip_Comments__c comments : commentsList) {
            tripIds.add(comments.National_Outings_Trip__c);
        }
        List<National_Outings_Trip__c> tripList = [
            SELECT Id, Name, Subcommittee__c FROM National_Outings_Trip__c WHERE Id in :tripIds
        ];
        Map<Id, National_Outings_Trip__c> tripMap = new Map<Id, National_Outings_Trip__c>(tripList);
        Map<Id, List<Recipient>> creatorMap = getCreators(tripList);
        Map<Id, List<Recipient>> approverMap = getApprovers(tripList);

        List<TriggeredSendEmail__c> sendList = new List<TriggeredSendEmail__c>();
        for(National_Outings_Trip_Comments__c comments : commentsList) {
            National_Outings_Trip__c trip = tripMap.get(comments.National_Outings_Trip__c);
            String subject = 'New Comment for Trip ' + trip.Name;
            if(comments.Notify_Creators__c) {
                List<Recipient> recipientList = creatorMap.get(comments.National_Outings_Trip__c);
                for(Recipient rcp : recipientList) {
                    //rcp.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, comments.Comments__c));
                    sendList.add(createTriggeredSend(rcp.contactId, testEmailAddr, subject, comments.Comments__c));
                }
            }
            if(comments.Notify_Approvers__c) {
                List<Recipient> recipientList = approverMap.get(comments.National_Outings_Trip__c);
                for(Recipient rcp : recipientList) {
                    //rcp.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, comments.Comments__c));
                    sendList.add(createTriggeredSend(rcp.contactId, testEmailAddr, subject, comments.Comments__c));
                }
            }
            if(comments.Notify_Staff__c) {
                sendList.add(createTriggeredSend(null, staffEmailAddr, subject, comments.Comments__c));
            }
        }
        return sendList;
    }

    private static TriggeredSendEmail__c createTriggeredSend(Id contactId, String emailAddr, String subject, String msg) {
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeFieldName('To');
        gen.writeStartObject();
        gen.writeStringField('Address', emailAddr);
        gen.writeStringField('SubscriberKey', contactId == null ? emailAddr : contactId);
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
