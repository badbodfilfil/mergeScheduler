global class MergeContactsScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		//system.schedule('Merge duplicates', '0 0 22 * * ? *', new MergeContactsScheduler());
		database.executebatch(new MergeContactsBatch(), 70);
	}
}