@isTest
public with sharing class MergeBatchesTest {

	static void init() {
		
		Account acc = new Account(
			Name = 'name',
			Phone = '123'
		);
		insert acc;

		Account acc2 = new Account(
			Name = 'name',
			BillingState = 'AT'
		);
		insert acc2;

		Account acc3 = new Account(
			Name = 'name',
			BillingState = 'AT',
			Phone = '123'
		);
		insert acc3;

		Contact con = new Contact(
			AccountId = acc.Id,
			LastName ='lastname',
			Email = 'ema@gmail.com'
		);
		insert con;

		Contact con2 = new Contact(
			AccountId = acc.Id,
			LastName ='lastname',
			FirstName = 'firstname',
			MailingState = 'AT'
		);
		insert con2;

		Contact con3 = new Contact(
			AccountId = acc.Id,
			LastName ='lastname',
			FirstName = 'firstname',
			Phone = '111'
		);
		insert con3;

		Contact con4 = new Contact(
			AccountId = acc.Id,
			LastName ='lastname',
			FirstName = 'firstname',
			Email = 'ema@gmail.com',
			Phone = '111',
			MailingState = 'AT'
		);
		insert con4;

	}

	@isTest
	static void checkMergeFlow()
	{
		init();
		Test.startTest();

		system.schedule('Merge duplicates', '0 0 22 * * ? *', new MergeContactsScheduler()); 

		Test.stopTest();
	}
}