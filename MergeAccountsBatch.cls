global with sharing class MergeAccountsBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return getAccounts();
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        try {
            findDuplicates(scope);
        } catch (Exception ex) {
            system.debug(ex);
        }
    }

    global void finish(Database.BatchableContext BC) {
    }

    public void findDuplicates(List<Account> listOfAccounts) {
        List<Attachment> attachToInsert = new List<Attachment>();
        for (Account account : listOfAccounts) {
        	List<sObject> recordsToUpdate = new List<sObject>();
            if (account.Name != null) {
                String accId = account.Id;
                String accName = account.Name;
                String query = 'SELECT Id, Name, AccountNumber, Phone, CreatedDate, Website, Integration_Key__c, Legacy_ID_Account__c, BillingState FROM Account WHERE Id != :accId AND Name = :accName';
                if (account.Phone != null) {
                    String phone = account.Phone;
                    query += ' AND Phone = :phone';
                } else {
                    String state = account.BillingState;
                    query += ' AND BillingState = :state';
                }
                query += ' ORDER BY CreatedDate ASC';

                List<Account> duplicateAccounts = Database.query(query);
                Set<Id> duplicIds = new Set<Id>();
                for (Account duplicate : duplicateAccounts) {
                    duplicIds.add(duplicate.Id);
                    if (account.Phone == null) {
                        account.Phone = duplicate.Phone;
                    }
                    if (account.Website == null) {
                        account.Website = duplicate.Website;
                    }
                    if (account.Integration_Key__c == null) {
                        account.Integration_Key__c = duplicate.Integration_Key__c;
                    }
                    if (account.Legacy_ID_Account__c == null) {
                        account.Legacy_ID_Account__c = duplicate.Legacy_ID_Account__c;
                    }
                    if (account.BillingState == null) {
                        account.BillingState = duplicate.BillingState;
                    }
                }

                if (duplicateAccounts.size() != 0) {
                    system.debug('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' + account);
            		system.debug('!!!!!!!!!!!!!ACCS' + duplicateAccounts);

                    recordsToUpdate.add(account);

                    List<Contact> contacsFromDuplicates = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :duplicIds];
                    attachToInsert.add(MergeContactsBatch.createAttachment(contacsFromDuplicates, account.Id));
                    for (Contact contact : contacsFromDuplicates) {
                        contact.AccountId = account.Id;
                    }
                    recordsToUpdate.addAll(contacsFromDuplicates);

                    attachToInsert.add(createAttachment(duplicateAccounts, account.Id));
                    
                    List<Opportunity> opportunitiesFromDuplicates = [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :duplicIds];
                    for (Opportunity opportunityRec : opportunitiesFromDuplicates) {
                        opportunityRec.AccountId = account.Id;
                    }
                    recordsToUpdate.addAll(opportunitiesFromDuplicates);
                    
                    List<Case> casesFromDuplicates = [SELECT Id, AccountId FROM Case WHERE AccountId IN :duplicIds];
                    for (Case caseRec : casesFromDuplicates) {
                        caseRec.AccountId = account.Id;
                    }
                    recordsToUpdate.addAll(casesFromDuplicates);
                    
        			update recordsToUpdate;
                    delete duplicateAccounts;   
                }
            }
        }
        insert attachToInsert;
    }
    
    public static Attachment createAttachment(List<Account> duplicates, Id originalId) {
        String logBody = JSON.serialize(duplicates);
        return new Attachment(Name = 'duplicateAccs.txt', ParentId = originalId, Body = Blob.valueOf(logBody));
    }

    public Database.QueryLocator getAccounts() {
        return Database.getQueryLocator([
            SELECT Id, Name, AccountNumber, Phone, CreatedDate,
                Website, Integration_Key__c, Legacy_ID_Account__c, BillingState
            FROM Account
            ORDER BY CreatedDate
            DESC
            LIMIT 200
        ]);
    }
}