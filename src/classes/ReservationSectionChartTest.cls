/*
 * @description Unit test for RervationSectionChart controller.
 *				This this tests data matrix is correctly populated.
 */
@isTest
private class ReservationSectionChartTest {
	/*
	 * @description Test data setup method.
	 */
	@testSetup
	private static void setupReservations(){

		Showtime__c show = TestDataFactory.createShowTime('Test', System.today().addDays(100),
		 MATAppConstants.LOCATION_SANJOSE, MATAppConstants.MEAL_DINNER);
		insert show;

		List<Table__c> tables1 = TestDataFactory.createTables(20, MATAppConstants.SECTION_10, 
			MATAppConstants.LOCATION_SANJOSE, 5);
		insert tables1;

		List<Table__c> tables2 = TestDataFactory.createTables(10, MATAppConstants.SECTION_15, 
			MATAppConstants.LOCATION_SANJOSE, 5);
		insert tables2;

		List<Table__c> tables3 = TestDataFactory.createTables(10, MATAppConstants.SECTION_25, 
			MATAppConstants.LOCATION_SANJOSE, 5);
		insert tables3;

		List<Reservation__c> reservations = new List<Reservation__c>();

		for(Table__c tb : tables1){
			//SECTION_10 - 20 Tables - Party Size is 2 -> SECTION_10 has 40 Attendance
			reservations.add(new Reservation__c(Party_Size__c = 2, Table__c = tb.Id, Showtime__c = show.Id));
		}

		for(Table__c tb : tables2){
			//SECTION_15 - 10 Tables - Party Size is 3 -> SECTION_15 has 30 Attendance
			reservations.add(new Reservation__c(Party_Size__c = 3, Table__c = tb.Id, Showtime__c = show.Id));
		}

		for(Table__c tb : tables3){
			//SECTION_25 - 10 Tables - Party Size is 4 -> SECTION_25 has 40 Attendance
			reservations.add(new Reservation__c(Party_Size__c = 4, Table__c = tb.Id, Showtime__c = show.Id));
		}
		insert reservations;
	}
	
	/*
	 * @description Tests the initial instantiation is correct.
	 */
	private static testmethod void testInitiation() {
		//get setup test data - 40 reservations expected
		List<Reservation__c> reservations = [SELECT Id, Table__r.Section__c, Party_Size__c FROM Reservation__c];
		System.assertEquals(40, reservations.size());

		Test.startTest();

		//check all sections are present in chart data. No of sections should be equal to no of data rows.
		System.assertEquals(MATAppSettings.tableSections.size(), 
			ReservationSectionChart.getChartData(reservations).size());

		Test.stopTest();
	}
	
	/*
	 * @description Test the grouped data matrix is correctly populated.
	 */
	private static testmethod void testGroupingOfSections() {
		//get setup test data - 40 reservations expected
		List<Reservation__c> reservations = [SELECT Id, Table__r.Section__c, Party_Size__c FROM Reservation__c];
		
		Test.startTest();

		for(ReservationSectionChart.Data row : ReservationSectionChart.getChartData(reservations)){
			if(row.section == MATAppConstants.SECTION_10){
				System.assertEquals(40, row.attendance);
			}
			else if(row.section == MATAppConstants.SECTION_15){
				System.assertEquals(30, row.attendance);
			}
			else if(row.section == MATAppConstants.SECTION_20){
				System.assertEquals(0, row.attendance);
			}
			else if(row.section == MATAppConstants.SECTION_25){
				System.assertEquals(40, row.attendance);
			}
		}
		
		Test.stopTest();
	}

	/*
	 * @description Tests for negative cases. If the current reservation is null.
	 */
	private static testmethod void testWithoutReservationsSections() {
		
		Test.startTest();

		//this should return an emapty list
		System.assertEquals(0, ReservationSectionChart.getChartData(null).size());

		Test.stopTest();
	}

	/*
	 * @description Test if Section field is not included in the query.
	 */
	private static testmethod void testForExceptions() {
		//get setup test data - 40 reservations expected
		List<Reservation__c> reservations = [SELECT Id, Table__c, Party_Size__c FROM Reservation__c];
		
		Test.startTest();

		List<ReservationSectionChart.Data> chartData = ReservationSectionChart.getChartData(reservations);
		System.assertEquals(0, chartData.size());
		
		List<Apexpages.Message> msgs = ApexPages.getMessages();

		System.assertEquals(Label.QueryErrorChart,msgs[0].getDetail());
		
		Test.stopTest();
	}

	/*
	 * @description Test for null party size.
	 */
	private static testmethod void testForNullPartySize() {
		//get setup test data - 40 reservations expected
		List<Reservation__c> reservations = [SELECT Id, Table__r.Section__c, Party_Size__c FROM Reservation__c];
		
		//Mark 2 SECTION_10 tables partysize to null. - 
		reservations[0].Party_Size__c = null;
		reservations[1].Party_Size__c = null;
		
		Test.startTest();

		for(ReservationSectionChart.Data row : ReservationSectionChart.getChartData(reservations)){
			if(row.section == MATAppConstants.SECTION_10){
				System.assertEquals(36, row.attendance);
			}
		}
		
		Test.stopTest();
	}
}