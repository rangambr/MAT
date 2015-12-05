@isTest
private class ReservationTriggerHelperTest {
	private static List<Reservation__c> reservations;
	@testSetup static void setupTestData(){
		List<String> showTimeLocations = MATAppSettings.showTimeLocations;
		List<String> showtimeMeals = MATAppSettings.showTimeMeals;
		List<String> tableLocations = MATAppSettings.tableLocations;
		List<String> tableSections = MATAppSettings.tableSections;

		Date showDate = System.today().addDays(100);

		List<Campaign> campaigns = TestDataFactory.createCampaigns(2);
		insert campaigns;

		List<ShowTime__c> showTimes = TestDataFactory.createShowTimes(50, showDate, showTimeLocations[0], showTimeMeals[0]);
		insert showTimes;

		List<Table__c> tables = TestDataFactory.createTables(50, tableSections[0], tableLocations[0], 3);
		insert tables;

		reservations = TestDataFactory.createReservations(tables, showTimes, campaigns[0], 2);
		MATAppSettings.IsReservationTriggerEnabled = false;
		insert reservations;
	}

	@isTest static void testCalculateRevenueAndReferralsOnInsertion() {
		System.debug('===='+reservations);
		System.debug('===='+[SELECT Id FROM Reservation__c].size());

		Test.startTest();
		
		Test.stopTest();
	}
	
	@isTest static void test_method_two() {
		// Implement test code
	}
	
}