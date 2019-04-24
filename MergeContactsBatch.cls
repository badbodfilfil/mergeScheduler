global with sharing class MergeContactsBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return getContacts();
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> scope) {
        try {
            findDuplicates(scope);
        } catch (Exception ex) {
            system.debug(ex);
        }
    }

    global void finish(Database.BatchableContext BC) {
        database.executebatch(new MergeAccountsBatch(), 70);
    }

    public void findDuplicates(List<Contact> listOfContacts) {
        List<Attachment> attachToInsert = new List<Attachment>();
        for (Contact contact : listOfContacts) {
        	List<sObject> recordsToUpdate = new List<sObject>();
            if (contact.LastName != null && contact.FirstName != null) {
                String contId = contact.Id;
                String lastName = contact.LastName;
                String firstName = contact.FirstName;
                String query = 'SELECT Id, Full_Name__c, Legacy_ID_Contact__c, MailingState, FirstName, LastName, Email, MobilePhone, Phone, CreatedDate FROM Contact WHERE Id != :contId AND LastName = :lastName AND FirstName = :firstName';
                if (contact.Email != null) {
                    String email = contact.Email;
                    query += ' AND Email = :email';
                } else if (contact.Phone != null) {
                    String phone = contact.Phone;
                    query += ' AND Phone = :phone';
                } else {
                    String state = contact.MailingState;
                    query += ' AND MailingState = :state';
                }
                query += ' ORDER BY CreatedDate ASC';

                List<Contact> duplicateContacts = Database.query(query);

                Set<Id> duplicIds = new Set<Id>();
                for (Contact duplicate : duplicateContacts) {
                    duplicIds.add(duplicate.Id);
                    if (contact.Legacy_ID_Contact__c == null) {
                        contact.Legacy_ID_Contact__c = duplicate.Legacy_ID_Contact__c;
                    }
                    if (contact.MailingState == null) {
                        contact.MailingState = duplicate.MailingState;
                    }
                    if (contact.Email == null) {
                        contact.Email = duplicate.Email;
                    }
                    if (contact.MobilePhone == null) {
                        contact.MobilePhone = duplicate.MobilePhone;
                    }
                    if (contact.Phone == null) {
                        contact.Phone = duplicate.Phone;
                    }
                }

                if (duplicateContacts.size() != 0) {
                    system.debug('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' + contact);
            		system.debug('!!!!!!!!!!!!!CONTS' + duplicateContacts);

                    recordsToUpdate.add(contact);

                    List<Case> casesFromDuplicates = [SELECT Id, ContactId FROM Case WHERE ContactId IN :duplicIds];
                    for (Case caseRec : casesFromDuplicates) {
                        caseRec.ContactId = contact.Id;
                    }
                    recordsToUpdate.addAll(casesFromDuplicates);
                    
                    attachToInsert.add(createAttachment(duplicateContacts, contact.Id));

        			update recordsToUpdate;
                    delete duplicateContacts;   
                }
            }
        }
        insert attachToInsert;
    }
    
    public static Attachment createAttachment(List<Contact> duplicates, Id originalId) {
        String logBody = JSON.serialize(duplicates);
        return new Attachment(Name = 'duplicateContacts.txt', ParentId = originalId, Body = Blob.valueOf(logBody));
    }

    public Database.QueryLocator getContacts() {
        return Database.getQueryLocator([
            SELECT Id, Full_Name__c, Legacy_ID_Contact__c, MailingState,
                FirstName, LastName, Email, MobilePhone, Phone, CreatedDate
            FROM Contact
            ORDER BY CreatedDate
            DESC
            LIMIT 200
        ]);
    }
}