/*
 * @description Test the logic for creating, and editing of showtimes. Also test the 
 *				create, edit delete of reservations for a showtime.
 *				Business logic is validated against "Reservation Takers" seperately.
 */
@isTest
private class ShowtimeManagerTest {

	/*
	 * @description Test data setup method. This method creates following:
	 *				1. Showtime - 1
	 *				2. Tables - 40
	 *				3. Reservations - 30
	 */
	@testSetup
	private static void setupTestData(){

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
			reservations.add(new Reservation__c(Party_Size__c = 2, Table__c = tb.Id, Showtime__c = show.Id));
		}

		for(Table__c tb : tables2){
			reservations.add(new Reservation__c(Party_Size__c = 3, Table__c = tb.Id, Showtime__c = show.Id));
		}
		insert reservations;
	}
	
	private static testmethod void testInitailSetupOnCreateNewShowtime() {

		Test.startTest();

		Test.setCurrentPage(Page.ShowTimeManager);

		//New showtime is created.
		Showtime__c showtime = new Showtime__c();
		ApexPages.StandardController std = new ApexPages.StandardController(showtime);
		ShowTimeManager showManager = new ShowTimeManager(std);

		//validated instantiantion of variables.
		System.assertEquals(5, showManager.pageSize, 'Default page size should be 5.');
		System.assertEquals('all', showManager.selectedSection, 'Default section should be set to all.');
		
		//there should be 40 tables
		System.assertEquals(40, showManager.totalNoOfRecords, 'Total number of pages is incorrect.');

		//Fist five reservations should be in the list.
		List<Reservation__c> reservations = showManager.getReservations();
		System.assertEquals(5, reservations.size());
		//there should be 5 reservations - because first page size is 5.
		System.assertEquals(5, showManager.tableReservation.size(),'Map should have 5 reservations as per page size.');
		//validate identity map. Reservation map should have each current table.
		for(Reservation__c rs : reservations){
			System.assertEquals(true, showManager.tableReservation.containsKey(rs.Table__c));
		}
		Test.stopTest();
	}

	private static testmethod void testInitailSetupOnExistingShowtime() {
		Test.startTest();

		Test.setCurrentPage(Page.ShowTimeManager);

		//Existing showtime is edited.
		Showtime__c showtime = [SELECT Id, Location__c FROM Showtime__c LIMIT 1];
		System.assertNotEquals(null, showtime);
		ApexPages.StandardController std = new ApexPages.StandardController(showtime);
		ShowTimeManager showManager = new ShowTimeManager(std);

		System.assertEquals(5, showManager.pageSize);

		//There should be 30 existing reservations.
		System.assertEquals(30, showManager.tableReservation.size());

		List<Reservation__c> existingReservations = [SELECT Id, Table__c FROM Reservation__c];
		//Validate reservations-table map.
		for(Reservation__c res : existingReservations){
			System.assertEquals(true, showManager.tableReservation.containsKey(res.Table__c), 
				'Existing reservations are not setup.');
		}

		Test.stopTest();
	}

	private static testmethod void testNavigationOfReservations(){
		Test.startTest();

		Test.setCurrentPage(Page.ShowTimeManager);

		//New showtime is created.
		Showtime__c showtime = [SELECT Id, Location__c FROM Showtime__c LIMIT 1];
		System.assertNotEquals(null, showtime);
		ApexPages.StandardController std = new ApexPages.StandardController(showtime);
		ShowTimeManager showManager = new ShowTimeManager(std);

		List<Reservation__c> rs1 = showManager.getReservations();
		Set<Id> tableIds = new Set<Id>();
		
		for(Reservation__c res : rs1){
			tableIds.add(res.Table__c); 
		}
		//first page.
		System.assertEquals(1, showManager.pageNumber);
		//check has more records
		System.assertEquals(true, showManager.hasNext, 'Cannot navigate forward');
		
		//Get next 5 records.
		showManager.next();
		//second page.
		System.assertEquals(2, showManager.pageNumber);

		List<Reservation__c> rs2 = showManager.getReservations();
		//check next set of records are for different tables.
		for(Reservation__c res : rs2){
			System.assertEquals(false, tableIds.contains(res.Table__c), 'Reservation not found');
		}
		//check can navigate back.
		System.assertEquals(true, showManager.hasPrevious, 'Cannot navigate back');

		//get previous 5 records.
		showManager.previous();
		//first page.
		System.assertEquals(1, showManager.pageNumber);

		List<Reservation__c> rs3 = showManager.getReservations();
		//check this set of records are for same as first set of tables.
		for(Reservation__c res : rs3){
			System.assertEquals(true, tableIds.contains(res.Table__c), 'Reservation not found');
		}

		showManager.last();
		List<Reservation__c> rs4 = showManager.getReservations();
		//check last set of records are for different tables.
		for(Reservation__c res : rs4){
			System.assertEquals(false, tableIds.contains(res.Table__c), 'Last page not correct.');
		}

		showManager.first();
		//first page.
		System.assertEquals(1, showManager.pageNumber);
		List<Reservation__c> rs5 = showManager.getReservations();
		//check first set of records are for same as previous first set of tables.
		for(Reservation__c res : rs5){
			System.assertEquals(true, tableIds.contains(res.Table__c), 'Reservation not found');
		}
		Test.stopTest();
	}

	private static testmethod void testSectionFilter(){
		Test.startTest();

		Test.setCurrentPage(Page.ShowTimeManager);

		//Showtime is created.
		ApexPages.StandardController std = new ApexPages.StandardController(new Showtime__c());
		ShowTimeManager showManager = new ShowTimeManager(std);

		List<SelectOption> sections = showManager.getSectionFilter();
		//Fist option is all.
		System.assertEquals('all', sections[0].getValue());
		System.assertEquals(Label.AllTableSections, sections[0].getLabel());

		//all other options should match Table__c.Section__c picklist values.
		for(Integer i = 0; i < MATAppSettings.tableSections.size(); i++){
			System.assertEquals(MATAppSettings.tableSections[i], sections[i+1].getValue(), 
				'Filter option not matching picklist.');
			System.assertEquals(MATAppSettings.tableSections[i], sections[i+1].getLabel(), 
				'Filter option not matching picklist.');  
        }

		Test.stopTest();
	}

	private static testmethod void testGetChartData(){
		Test.startTest();

		Test.setCurrentPage(Page.ShowTimeManager);

		//Showtime is created.
		ApexPages.StandardController std = new ApexPages.StandardController(new Showtime__c());
		ShowTimeManager showManager = new ShowTimeManager(std);

		//Add new reservation by changing the party size.
		showManager.getReservations()[0].Party_Size__c = 10;
		//get chart data
		List<ReservationSectionChart.Data> chartData = showManager.getChartData();
		//Four data points available.
		System.assertEquals(4, chartData.size());
		//Attendance is set to 10 for the chart data item. Otherwise 0.
		for(ReservationSectionChart.Data dt : chartData){
			if(showManager.getReservations()[0].Table__r.Section__c == dt.section){
				System.assertEquals(10, dt.attendance);
			} else {
				System.assertEquals(0, dt.attendance);
			}
		}
		System.assertEquals(10, chartData[0].attendance);
		Test.stopTest();
	}

	private static testmethod void testSaveNew(){
		Test.startTest();

		Test.setCurrentPage(Page.ShowTimeManager);

		//Showtime is created.
		ApexPages.StandardController std = new ApexPages.StandardController(
			new Showtime__c(Name = 'testx1', Location__c = MATAppConstants.LOCATION_SANJOSE,
							Date__c = System.today().addDays(10), Meal__c = MATAppConstants.MEAL_DINNER));
		
		ShowTimeManager showManager = new ShowTimeManager(std);

		//Add new reservation by changing the party size.
		showManager.getReservations()[0].Party_Size__c = 10;

		PageReference pg = showManager.save();

		Showtime__c showtime = [SELECT Id FROM Showtime__c WHERE Name = 'testx1' LIMIT 1];
		System.assertNotEquals(null, showtime);

		Reservation__c reservation = [SELECT Id, Party_Size__c FROM Reservation__c 
										WHERE Showtime__c =:showtime.Id LIMIT 1];
		System.assertNotEquals(null, reservation);
		System.assertEquals(10, reservation.Party_Size__c);
		
		System.assertEquals(true, pg.getUrl().containsIgnoreCase(showtime.Id), 
			'Not redirected to Showtime record.');
	}

	private static testmethod void testDeleteReservation(){
		Test.startTest();

		Test.setCurrentPage(Page.ShowTimeManager);

		Showtime__c showtime = [SELECT Id, Location__c FROM Showtime__c LIMIT 1];
		System.assertNotEquals(null, showtime);

		ApexPages.StandardController std = new ApexPages.StandardController(showtime);
		ShowTimeManager showManager = new ShowTimeManager(std);

		//get one of existing reservations in the system for this showtime
		Reservation__c[] reservation = [SELECT Id, Table__c
					 FROM Reservation__c WHERE Showtime__c=: showtime.Id LIMIT 1];
		
		//set the party size of this reservation to zero.
		showManager.tableReservation.get(reservation[0].Table__c).Party_Size__c = 0;

		//save the modifications
		showManager.save();

		//check reservation is deleted.
		Reservation__c[] reservationDeleted = [SELECT Id FROM Reservation__c WHERE Id=:reservation[0].Id LIMIT 1];
		System.assertEquals(0, reservationDeleted.size(),'Reservation is not deleted after setting the party size to 0.');
		Test.stopTest();

	}
	
	private static testmethod void testQueryString() {
		
		Test.startTest();

		Test.setCurrentPage(Page.ShowTimeManager);

		//Showtime is created.
		ApexPages.StandardController std = new ApexPages.StandardController(new Showtime__c());
		ShowTimeManager showManager = new ShowTimeManager(std);

		System.assertEquals(false, showManager.getQueryString().containsIgnoreCase('WHERE'), 
			'Where clause should not available');

		showManager.selectedSection = MATAppConstants.SECTION_10;

		System.assertEquals(true, showManager.getQueryString().containsIgnoreCase('WHERE'),
			'Where clause should present');
		System.assertEquals(true, showManager.getQueryString().containsIgnoreCase(MATAppConstants.SECTION_10),
			'Section filter should present');

		//Showtime with location
		std = new ApexPages.StandardController(new Showtime__c(Location__c = MATAppConstants.LOCATION_BOSTON));
		showManager = new ShowTimeManager(std);
		showManager.selectedSection = MATAppConstants.SECTION_10;

		System.assertEquals(true, showManager.getQueryString().containsIgnoreCase('WHERE'),
			'Where clause should present');
		System.assertEquals(true, showManager.getQueryString().containsIgnoreCase(MATAppConstants.SECTION_10),
			'Section filter should present');
		System.assertEquals(true, showManager.getQueryString().containsIgnoreCase('AND'),
			'AND operator should present');
		System.assertEquals(true, showManager.getQueryString().containsIgnoreCase(MATAppConstants.LOCATION_BOSTON),
			'Location filter should present');

		Test.stopTest();
	}

	private static testmethod void testQueryStringExceptions() {
		
		Test.startTest();

		Test.setCurrentPage(Page.ShowTimeManager);

		//Showtime is created. inject single quotes to location field.
		ApexPages.StandardController std = new ApexPages.StandardController(new Showtime__c(Location__c = '\'xx\''));
		ShowTimeManager showManager = new ShowTimeManager(std);

		//exception is expected.
		showManager.setupReservations();

		List<Apexpages.Message> errorMsgs = ApexPages.getMessages();
		System.assertEquals(true, errorMsgs[0].getDetail().contains(Label.ShowtimeManagerQueryError),
			'Error message for the query exception not available.');

		Test.stopTest();
	}

	private static testmethod void testReservationDMLException(){
		Test.startTest();

		Test.setCurrentPage(Page.ShowTimeManager);

		Showtime__c showtime = [SELECT Id, Name, Location__c FROM Showtime__c LIMIT 1];
		System.assertNotEquals(null, showtime);
		System.assertEquals('Test', showtime.Name);

		ApexPages.StandardController std = new ApexPages.StandardController(showtime);
		ShowTimeManager showManager = new ShowTimeManager(std);

		//get one of existing reservations in the system for this showtime
		Reservation__c[] reservation = [SELECT Id, Table__c
					 FROM Reservation__c WHERE Showtime__c=: showtime.Id LIMIT 1];
		

		//Overwrite existing reservation with a new Reservation without showtime or table.
		//As table and showtime are required fields, exception should occur while inserting this reservation.
		showManager.tableReservation.put(reservation[0].Table__c, new Reservation__c(Party_Size__c = 10));

		//to test the save point and roll-back, change the name of the showtime as well
		//duirng this transaction. As the exception occurs while saving reservations,
		//changes to Showtime is expected to roll back.
		showtime.Name = 'test roll-back';

		//save the showtime and reservation
		showManager.save();

		//test the roll-back.
		showtime = [SELECT Id, Name, Location__c FROM Showtime__c LIMIT 1];
		System.assertEquals('Test', showtime.Name, 'Transaction did not roll-back to original state.');
		
		Test.stopTest();
	}

	private static testmethod void testShowtimeException(){
		Test.startTest();

		Test.setCurrentPage(Page.ShowTimeManager);

		Showtime__c showtime = [SELECT Id, Name, Location__c FROM Showtime__c LIMIT 1];
		System.assertNotEquals(null, showtime);

		ApexPages.StandardController std = new ApexPages.StandardController(showtime);
		ShowTimeManager showManager = new ShowTimeManager(std);

		showManager.showtime = null;
		PageReference pg = showManager.save();

		System.assertEquals(null, pg);

		List<Apexpages.Message> errorMsgs = ApexPages.getMessages();

		System.assertEquals(true, errorMsgs[0].getDetail().contains(Label.ShowtimeSaveError),
			'Error message for the showtime save exception not available.');

		Test.stopTest();

	}

	private static testmethod void testReservationTakerCreateShowtimeAndAddReservations(){

		User reservationTaker = TestDataFactory.createUser(MATAppConstants.RESERVATION_TAKER_PROFILE);

		System.runAs(reservationTaker){

			Test.startTest();

			Test.setCurrentPage(Page.ShowTimeManager);

			ApexPages.StandardController std = new ApexPages.StandardController(
				new Showtime__c(Name = 'test show test taker', Location__c = MATAppConstants.LOCATION_SANJOSE,
					Meal__c = MATAppConstants.MEAL_DINNER, Date__c = System.today().addDays(10)));

			ShowTimeManager showManager = new ShowTimeManager(std);

			//get first 5 reservations
			List<Reservation__c> reservations = showManager.getReservations();
			//set party size to 2
			for(Reservation__c reservation : reservations){
				reservation.Party_Size__c = 2;
			}

			//save Showtime and Reservations
			PageReference pg = showManager.save();

			Showtime__c[] show = [SELECT Id, Name, Location__c, Meal__c, Date__c 
						FROM Showtime__c WHERE Name = 'test show test taker' LIMIT 1];

			System.assertEquals(1, show.size());

			//validate save
			System.assertEquals('test show test taker', show[0].Name);
			System.assertEquals(MATAppConstants.LOCATION_SANJOSE, show[0].Location__c);
			System.assertEquals(MATAppConstants.MEAL_DINNER, show[0].Meal__c);
			System.assertEquals(System.today().addDays(10), show[0].Date__c);

			List<Reservation__c> showReservations = [SELECT Id, Name, Party_Size__c 
						FROM Reservation__c WHERE Showtime__c =: show[0].Id];

			System.assertEquals(5, showReservations.size());

			for(Reservation__c reservation : showReservations){
				System.assertEquals(2, reservation.Party_Size__c);
			}
			Test.stopTest();
		}
	}

	private static testmethod void testReservationTakerUpdateOfExistingShowtime(){
		
		User reservationTaker = TestDataFactory.createUser(MATAppConstants.RESERVATION_TAKER_PROFILE);

		System.runAs(reservationTaker){
			//create a showtime and a reservation.
			Showtime__c show = TestDataFactory.createShowTime('test show test taker', System.today().addDays(10),
			 MATAppConstants.LOCATION_BOSTON, MATAppConstants.MEAL_DINNER);
			insert show;

			Table__c table = TestDataFactory.createTable('test table 1', MATAppConstants.SECTION_10, 
				MATAppConstants.LOCATION_BOSTON, 1);
			insert table;

			Reservation__c reservation = TestDataFactory.createReservation(table.Id, show.Id, null, 1);
			insert reservation;

			//test the update to existing showtime
			Test.startTest();

			Test.setCurrentPage(Page.ShowTimeManager);

			ApexPages.StandardController std = new ApexPages.StandardController(show);

			ShowTimeManager showManager = new ShowTimeManager(std);

			//test the existing reservation is correctly populated
			Boolean reservationFound = false;
			
			while(! reservationFound){

				List<Reservation__c> reservations = showManager.getReservations();
				//set party size to 2
				for(Reservation__c res : reservations){
					if(res.Id == res.Id){
						reservationFound = true;
						//set party size to 2
						res.Party_Size__c = 2;
						break;
					}
				}
				if(! reservationFound){
					showManager.next();
				}
			}

			System.assertEquals(true, reservationFound, 'Unable to find existing reservation.');

			showManager.showtime.Location__c = MATAppConstants.LOCATION_CHICAGO;
			showManager.showtime.Meal__c = MATAppConstants.MEAL_LUNCH;
			showManager.showtime.Date__c = System.today().addDays(20);

			//save Showtime and Reservations.
			PageReference pg = showManager.save();

			Showtime__c[] existingShow = [SELECT Id, Name, Location__c, Meal__c, Date__c 
						FROM Showtime__c WHERE Name = 'test show test taker' LIMIT 1];

			System.assertEquals(1, existingShow.size());

			//validate update to showtime and reservation.
			System.assertEquals('test show test taker', existingShow[0].Name);
			System.assertEquals(MATAppConstants.LOCATION_CHICAGO, existingShow[0].Location__c);
			System.assertEquals(MATAppConstants.MEAL_LUNCH, existingShow[0].Meal__c);
			System.assertEquals(System.today().addDays(20), existingShow[0].Date__c);

			List<Reservation__c> showReservations = [SELECT Id, Name, Party_Size__c 
						FROM Reservation__c WHERE Showtime__c =: existingShow[0].Id];

			System.assertEquals(1, showReservations.size());
			System.assertEquals(2, showReservations[0].Party_Size__c);
			
			Test.stopTest();
		}
	}
}