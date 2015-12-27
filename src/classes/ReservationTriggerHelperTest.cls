/*
 * @description: This test class includes unit-tests for ReservationTriggerHelper. Logic and caluclations
 *				 are initially tested with small number of records. Then the handling of bulk data is 
 *				 tested seperately against "Reservation Taker" user to simulate realtime data handling of
 *				 Reservations.
 *				 
 */
@isTest
private class ReservationTriggerHelperTest {
	
	private static Showtime__c showTime;
	private static Campaign campaign;

	/*
	 * @description: This method creates Reservation for a ShowTime. If the there is existing ShowTime,
	 *				 Reservation is created for the existing Showtime.
	 */
	private static Reservation__c createReservationForShowTime(){

		//If there isn't existing showtime, create. Otherwise use existing.
		if(showTime == null){
			showTime = TestDataFactory.createShowTime('test shw', System.today().addDays(100),
		 MATAppConstants.LOCATION_BOSTON, MATAppConstants.MEAL_LUNCH);
		 insert showTime;
		}
	
		Table__c table = TestDataFactory.createTable('test table', MATAppConstants.SECTION_10, 
			MATAppConstants.LOCATION_BOSTON, 3);
		insert table;

		Reservation__c reservation = TestDataFactory.createReservation(table.Id, showTime.Id, null, 2);
		return reservation;
	}

	/*
	 * @description Bulk insert Tables and Reservations per Showtime.
	 */
	private static List<Reservation__c> createReservationForShowTimeBulk(){
		
		List<ShowTime__c> showTimes = TestDataFactory.createShowTimes(50, System.today().addDays(100),
		MATAppConstants.LOCATION_NY, MATAppConstants.MEAL_DINNER);
		insert showTimes;

		List<Table__c> tables = TestDataFactory.createTables(50, MATAppConstants.SECTION_25, 
			MATAppConstants.LOCATION_NY, 3);
		insert tables;

		List<Reservation__c> reservations = TestDataFactory.createReservations(tables, showTimes, null, 2);

		return reservations;
	}

	/*
	 * @description: This method creates Reservation for a Campaign. If the there is existing Campaign,
	 *				 Reservation is created for the existing Campaign.
	 */
	private static Reservation__c createReservationForCampaign(){

		if(campaign == null){
			campaign = TestDataFactory.createCampaign('test cmp', 'Test Desc');
			insert campaign;
		}
		
		Showtime__c	show = TestDataFactory.createShowTime('test shw', System.today().addDays(100),
		 MATAppConstants.LOCATION_BOSTON, MATAppConstants.MEAL_LUNCH);
		 insert show;
	
		Table__c table = TestDataFactory.createTable('test table', MATAppConstants.SECTION_10, 
			MATAppConstants.LOCATION_BOSTON, 3);
		insert table;

		//Set the party size to zero so that Revenue calcuation Showtime is not calculated during insertion.
		Reservation__c reservation = TestDataFactory.createReservation(table.Id, show.Id, campaign.Id, 0);
		return reservation;
	}

	/*
	 * @description Bulk insert ShowTimes, Tables and Reservations.
	 */
	private static List<Reservation__c> createReservationsForCampaignBulk(){
		//Assign all Reservations to one Campaign.
		if(campaign == null){
			campaign = TestDataFactory.createCampaign('test cmp', 'Test Desc');
			insert campaign;
		}

		List<ShowTime__c> showTimes = TestDataFactory.createShowTimes(50, System.today().addDays(100),
		 MATAppConstants.LOCATION_SANJOSE, MATAppConstants.MEAL_DINNER);
		insert showTimes;

		List<Table__c> tables = TestDataFactory.createTables(50, MATAppConstants.SECTION_20, 
			MATAppConstants.LOCATION_NY, 3);
		insert tables;

		List<Reservation__c> reservations = TestDataFactory.createReservations(tables, showTimes, campaign, 2);

		return reservations;
	}

	/*
	 * @description: This unit tests the calculation of Total_Revenue__c of ShowTime__c during 
	 *				 an insertion of Reservation__c
	 */
	private static testmethod void testCalculateRevenueOnInsert() {

		Reservation__c reservation = createReservationForShowTime();

		Test.startTest();

		//insert Reservation - ReservationTriggerHelper.calculateRevenueAndReferrals() is executed via trigger.
		insert reservation;

		//Only one DML row is expected
		System.assertEquals(1, LIMITS.getDMLRows(), 'Invalid number of DML rows.');

		//Only one Query row is expected
		System.assertEquals(1, LIMITS.getQueryRows(), 'Invalid number of Query rows.');
		
		//Total Revenue of Showtime should set to: Section Value x Party Size = 10 x 2 = 20.00
		ShowTime__c show = [SELECT Id, Total_Revenue__c FROM ShowTime__c WHERE Id =:showTime.Id LIMIT 1];
		System.assertEquals(20, show.Total_Revenue__c, 'Total Revenue is incorrect.');

		Test.stopTest();

	}
	
	/*
	 * @description: This unit tests the recalculation of Total_Revenue__c of ShowTime__c during 
	 *				 deletion of Reservation__c
	 */
	private static testmethod void testCalculateRevenueOndelete() {
		
		//create Two Reservations for the same ShowTime and and Tables, each has Revenue of 20.00
		Reservation__c resWith20Revenue1 = createReservationForShowTime();
		insert resWith20Revenue1;

		Reservation__c resWith20Revenue2 = createReservationForShowTime();
		insert resWith20Revenue2;

		Test.startTest();
		//Validate initial Total_Revenue__c for the ShowTime__c is 40.00 (20.00 x 2)
		ShowTime__c show = [SELECT Id, Total_Revenue__c FROM ShowTime__c WHERE Id =:showTime.Id LIMIT 1];
		System.assertEquals(40, show.Total_Revenue__c, 'Total Revenue is incorrect.');
		
		delete resWith20Revenue1;

		//Only one DML row is expected
		System.assertEquals(1, LIMITS.getDMLRows(), 'Invalid number of DML rows.');

		//Only one Query row is expected
		System.assertEquals(1, LIMITS.getQueryRows(), 'Invalid number of Query rows.');
		
		//Total Revenue of Showtime should set to: Section Value x Party Size = 10 x 2 = 20.00
		show = [SELECT Id, Total_Revenue__c FROM ShowTime__c WHERE Id =:showTime.Id LIMIT 1];
		System.assertEquals(20, show.Total_Revenue__c, 'Total Revenue is incorrect.');

		Test.stopTest();		
		
	}

	/*
	 * @description: This unit tests the recalculation of Total_Revenue__c of ShowTime__c during 
	 *				 undelete of Reservation__c.
	 */
	private static testmethod void testCalculateRevenueOnunDelete() {
		
		//create Two Reservations for the same ShowTime and and Tables, each has Revenue of 20.00
		Reservation__c resWith20Revenue1 = createReservationForShowTime();
		insert resWith20Revenue1;

		Reservation__c resWith20Revenue2 = createReservationForShowTime();
		insert resWith20Revenue2;

		//delete one Reservation so that it can be undeleted during the test.
		delete resWith20Revenue1;

		Test.startTest();

		//Validate initial Total_Revenue__c for the ShowTime__c is 20.00: (20.00 x 2) - 20.00 = 20.00
		ShowTime__c show = [SELECT Id, Total_Revenue__c FROM ShowTime__c WHERE Id =:showTime.Id LIMIT 1];
		System.assertEquals(20, show.Total_Revenue__c, 'Total Revenue is incorrect.');

		undelete resWith20Revenue1;
		
		//Only one DML row is expected
		System.assertEquals(1, LIMITS.getDMLRows(), 'Invalid number of DML rows.');

		//Only two Query rows are expected
		System.assertEquals(2, LIMITS.getQueryRows(), 'Invalid number of Query rows.');
		
		//Total Revenue of Showtime should set to: (Section Value x Party Size) x2 = 2(10 x 2) = 40.00
		show = [SELECT Id, Total_Revenue__c FROM ShowTime__c WHERE Id =:showTime.Id LIMIT 1];
		System.assertEquals(40, show.Total_Revenue__c, 'Total Revenue is incorrect.');

		Test.stopTest();
	}
	
	/*
	 * @description: This unit tests the recalculation of Total_Revenue__c of ShowTime__c during 
	 *				 update of Reservation Party_Size__c.
	 */
	private static testmethod void testCalculateRevenueOnUpdate() {
		
		//Create a Reservation with Party Size of 2.
		Reservation__c reservation = createReservationForShowTime();
		insert reservation;

		Test.startTest();

		//Validate initial Total_Revenue__c for the ShowTime__c is 20.00: (10.00 x 2) = 20.00
		ShowTime__c show = [SELECT Id, Total_Revenue__c FROM ShowTime__c WHERE Id =:showTime.Id LIMIT 1];
		System.assertEquals(20, show.Total_Revenue__c, 'Total Revenue is incorrect.');

		//Increase the Party_Size__c to 3 from 2.
		reservation.Party_Size__c = 3;
		update reservation;
		
		//Only one DML row is expected
		System.assertEquals(1, LIMITS.getDMLRows(), 'Invalid number of DML rows.');

		//Only one Query row is expected
		System.assertEquals(1, LIMITS.getQueryRows(), 'Invalid number of Query rows.');
		
		//Total Revenue of Showtime should set to: (Section Value x Party Size) = (10 x 3) = 30.00
		show = [SELECT Id, Total_Revenue__c FROM ShowTime__c WHERE Id =:showTime.Id LIMIT 1];
		System.assertEquals(30, show.Total_Revenue__c, 'Total Revenue is incorrect.');

		Test.stopTest();
	}

	/*
	 * @description: This unit tests the recalculation of Total_Number_Referrals__c of Campaign during 
	 *				 insert of Reservation__c.
	 */
	private static testmethod void testCalculateTotalReferralsOnInsert() {
		
		Reservation__c reservation = createReservationForCampaign();

		Test.startTest();

		Campaign cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
		System.assertEquals(null, cmp.Total_Number_Referrals__c);

		//insert Reservation - ReservationTriggerHelper.calculateRevenueAndReferrals() is executed via trigger.
		insert reservation;

		//Only one DML row is expected
		System.assertEquals(1, LIMITS.getDMLRows(), 'Invalid number of DML rows.');

		//Only one Query row is expected
		System.assertEquals(1, LIMITS.getQueryRows(), 'Invalid number of Query rows.');
		
		//Total Number of Referrals should set to: 1.
		cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
		System.assertEquals(1, cmp.Total_Number_Referrals__c, 'Total Referrals No is incorrect.');

		Test.stopTest();
	}

	/*
	 * @description: This unit tests the recalculation of Total_Number_Referrals__c of Campaign during 
	 *				 delete of Reservation__c.
	 */
	private static testmethod void testCalculateTotalReferralsOnDelete() {
		//Create two Reservations with same Campaign.
		Reservation__c reservation1 = createReservationForCampaign();
		insert reservation1;

		Reservation__c reservation2 = createReservationForCampaign();
		insert reservation2;

		Test.startTest();

		//validate initial Total_Number_Referrals__c is two.
		Campaign cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
		System.assertEquals(2, cmp.Total_Number_Referrals__c);

		//delete Reservation - ReservationTriggerHelper.calculateRevenueAndReferrals() is executed via trigger.
		delete reservation1;

		//Only one DML row is expected
		System.assertEquals(1, LIMITS.getDMLRows(), 'Invalid number of DML rows.');

		//Only one Query row is expected
		System.assertEquals(1, LIMITS.getQueryRows(), 'Invalid number of Query rows.');
		
		//Total Number of Referrals should reduced to: 1.
		cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
		System.assertEquals(1, cmp.Total_Number_Referrals__c, 'Total Referrals No is incorrect.');

		Test.stopTest();
	}

	/*
	 * @description: This unit tests the recalculation of Total_Number_Referrals__c of Campaign during 
	 *				 undelete of Reservation__c.
	 */
	private static testmethod void testCalculateTotalReferralsOnUndelete() {
		//Create two Reservations with same Campaign.
		Reservation__c reservation1 = createReservationForCampaign();
		insert reservation1;

		Reservation__c reservation2 = createReservationForCampaign();
		insert reservation2;

		//delete reservation1 so that it can be undeleted during the test.
		delete reservation1;

		Test.startTest();

		//validate initial Total_Number_Referrals__c is one.
		Campaign cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
		System.assertEquals(1, cmp.Total_Number_Referrals__c);

		//delete Reservation - ReservationTriggerHelper.calculateRevenueAndReferrals() is executed via trigger.
		undelete reservation1;

		//Only one DML row is expected
		System.assertEquals(1, LIMITS.getDMLRows(), 'Invalid number of DML rows.');

		//Only two Query row are expected
		System.assertEquals(2, LIMITS.getQueryRows(), 'Invalid number of Query rows.');
		
		//Total Number of Referrals should reduced to: 2.
		cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
		System.assertEquals(2, cmp.Total_Number_Referrals__c, 'Total Referrals No is incorrect.');

		Test.stopTest();
	}

	/*
	 * @description: This unit tests the recalculation of Total_Number_Referrals__c of Campaign during 
	 *				 clearing Reffered_By__c of a Reservation__c.
	 */
	private static testmethod void testCalculateTotalReferralsOnUpdateClearValue() {

		Reservation__c reservation = createReservationForCampaign();
		insert reservation;

		Test.startTest();

		Campaign cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
		System.assertEquals(1, cmp.Total_Number_Referrals__c);

		//Clear out Referred_By__c on the Reservation.
		reservation.Referred_By__c = null;
		update reservation;

		//Only one DML row is expected
		System.assertEquals(1, LIMITS.getDMLRows(), 'Invalid number of DML rows.');

		//No Query Rows are expected as there are no Reservations for the Campaign.
		System.assertEquals(0, LIMITS.getQueryRows(), 'Invalid number of Query rows.');
		
		//Total Number of Referrals should set to: 0.
		cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
		System.assertEquals(0, cmp.Total_Number_Referrals__c, 'Total Referrals No is incorrect.');

		Test.stopTest();
	}

	/*
	 * @description: This unit tests the recalculation of Total_Number_Referrals__c of Campaign during 
	 *				 reasignment of Reffered_By__c of a Reservation__c.
	 */
	private static testmethod void testCalculateTotalReferralsOnUpdateReasignment() {
		Reservation__c reservation = createReservationForCampaign();
		insert reservation;

		Campaign alternateCampaign = TestDataFactory.createCampaign('Alternate', 'Test desc');
		insert alternateCampaign;

		Test.startTest();

		//Validate Total_Number_Referrals__c on initial campaign - Before
		Campaign initialCampaign = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
		System.assertEquals(1, initialCampaign.Total_Number_Referrals__c);

		//Validate Total_Number_Referrals__c on second campaign - Before
		Campaign altCampaign = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:alternateCampaign.Id LIMIT 1];
		System.assertEquals(null, altCampaign.Total_Number_Referrals__c);

		//Reassign Referred_By__c on the Reservation.
		reservation.Referred_By__c = alternateCampaign.Id;
		update reservation;

		//Two DML Rows are expected - Old and New
		System.assertEquals(2, LIMITS.getDMLRows(), 'Invalid number of DML rows.');

		//Only one Query row is expected - Initial Campaign doesn't have a Reservation.
		System.assertEquals(1, LIMITS.getQueryRows(), 'Invalid number of Query rows.');
		
		//Validate Total_Number_Referrals__c on initial campaign - After
		initialCampaign = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
		System.assertEquals(0, initialCampaign.Total_Number_Referrals__c);

		//Validate Total_Number_Referrals__c on second campaign - After
		altCampaign = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:alternateCampaign.Id LIMIT 1];
		System.assertEquals(1, altCampaign.Total_Number_Referrals__c);

		Test.stopTest();
	}

	/*
	 * @description: This unit tests the recalculation of Total_Number_Referrals__c of Campaign during 
	 *				 adding a new Reffered_By__c of a Reservation__c.
	 */
	private static testmethod void testCalculateTotalReferralsOnUpdateNewValue() {

		Reservation__c reservation = createReservationForCampaign();
		//set Referred_By__c to null to start with
		reservation.Referred_By__c = null;
		insert reservation;

		Test.startTest();

		Campaign cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
		System.assertEquals(null, cmp.Total_Number_Referrals__c);

		//Set Referred_By__c on the Reservation.
		reservation.Referred_By__c = campaign.Id;
		update reservation;

		//Only one DML row is expected
		System.assertEquals(1, LIMITS.getDMLRows(), 'Invalid number of DML rows.');

		//Only one Reservation for the Campaign exists.
		System.assertEquals(1, LIMITS.getQueryRows(), 'Invalid number of Query rows.');
		
		//Total Number of Referrals should set to: 1.
		cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
		System.assertEquals(1, cmp.Total_Number_Referrals__c, 'Total Referrals No is incorrect.');

		Test.stopTest();
	}

	/*
	 * @description: This tests the bulk deletion of Reservation and calculation of Total Referrals.
	 */
	private static testmethod void testCalculateTotalReferralsOnBulkInsertAndDelete() {

		User reservationTaker = TestDataFactory.createUser(MATAppConstants.RESERVATION_TAKER_PROFILE);

		System.runAs(reservationTaker){

			Test.startTest();

			List<Reservation__c> reservations = createReservationsForCampaignBulk();
			insert reservations;

			//Total Number of Referrals should set to: 2500.
			Campaign cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
			System.assertEquals(2500, cmp.Total_Number_Referrals__c, 'Total Referrals No is incorrect.');

			cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
			System.assertEquals(2500, cmp.Total_Number_Referrals__c, 'Total Referrals No is incorrect.');
			
			delete reservations;
			
			//Total Number of Referrals should set to: 0.
			cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
			System.assertEquals(0, cmp.Total_Number_Referrals__c, 'Total Referrals No is incorrect.');

			Test.stopTest();
		}
	}

	/*
	 * @description: This tests the bulk update of Reservation and calculation of Total Referrals.
	 *				 This tests bulk clearing, reasigning while updating Reservations.
	 */
	private static testmethod void testCalculateTotalReferralsOnBulkUpdate() {
		
		User reservationTaker = TestDataFactory.createUser(MATAppConstants.RESERVATION_TAKER_PROFILE);

		System.runAs(reservationTaker){

			List<Reservation__c> reservations = createReservationsForCampaignBulk();
			//set first 500 Reservations Referred_By__c to null to start with
			for(Integer i = 0; i < 500; i++){
				reservations[i].Referred_By__c = null;
			}

			insert reservations;
			
			Test.startTest();

			//validate Total_Number_Referrals__c on initial Campaing - must be 2000.
			Campaign cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
			System.assertEquals(2000, cmp.Total_Number_Referrals__c, 'Total Referrals No is incorrect.');

			//set first 500 Reservations Referred_By__c to initial Campaign again.
			for(Integer i = 0; i < 500; i++){
				reservations[i].Referred_By__c = campaign.Id;
			}

			Campaign alternateCampaign = TestDataFactory.createCampaign('test alt', 'test alt desc');

			//set next 500 Reservation Referred_By__c to alternate Campaign.
			for(Integer i = 500; i < 1000; i++){
				reservations[i].Referred_By__c = alternateCampaign.Id;
			}

			//set next 500 Reservations Referred_By__c to null.
			for(Integer i = 1000; i < 1500; i++){
				reservations[i].Referred_By__c = null;
			}

			update reservations;
			
			//Total Number of Referrals should set to: 1500. (Initially 2500, 500 cleared and another 500 reasigned.)
			cmp = [SELECT Id, Total_Number_Referrals__c FROM Campaign WHERE Id =:campaign.Id LIMIT 1];
			System.assertEquals(1500, cmp.Total_Number_Referrals__c, 'Total Referrals No is incorrect.');

			Test.stopTest();
		}
	}

	/*
	 * @description: This tests the bulk insertion of Reservation and calculation of Total Revenue.
	 */
	private static testmethod void testCalculateTotalRevenueOnBulkInsertAndDelete() {

		User reservationTaker = TestDataFactory.createUser(MATAppConstants.RESERVATION_TAKER_PROFILE);

		Test.startTest();

		System.runAs(reservationTaker){

			List<Reservation__c> reservations = createReservationForShowTimeBulk();
			insert reservations;
		
			Set<Id> showtimeIds = new Set<Id>();
			
			for(Reservation__c res : reservations){
				showtimeIds.add(res.Showtime__c);
			}

			List<Showtime__c> shows = [SELECT Id, Total_Revenue__c FROM ShowTime__c WHERE Id =:showtimeIds];

			for(Showtime__c show : shows){
				//Total Revenue should set to: 2500 for all showtimes.
				System.assertEquals(2500, show.Total_Revenue__c, 'Total Revenue is incorrect.');
			}

			delete reservations;
			
			//Total Revenue should set to: 0 for all showtimes.
			shows = [SELECT Id, Total_Revenue__c FROM ShowTime__c WHERE Id =:showtimeIds];

			for(Showtime__c show : shows){
				System.assertEquals(0, show.Total_Revenue__c, 'Total Revenue is incorrect.');
			}
		}
		
		Test.stopTest();
	}

	/*
	 * @description: This tests the bulk insertion of Reservation and calculation of Total Revenue.
	 */
	private static testmethod void testCalculateTotalRevenueOnBulkUpdate() {

		User reservationTaker = TestDataFactory.createUser(MATAppConstants.RESERVATION_TAKER_PROFILE);

		System.runAs(reservationTaker){

			List<Reservation__c> reservations = createReservationForShowTimeBulk();
			insert reservations;
		
			Set<Id> showtimeIds = new Set<Id>();

			Test.startTest();
			//set party size to 3,
			for(Reservation__c res : reservations){
				showtimeIds.add(res.Showtime__c);
				res.Party_Size__c = 3;
			}
			update reservations;
			
			List<Showtime__c> shows = [SELECT Id, Total_Revenue__c FROM ShowTime__c WHERE Id =:showtimeIds];

			for(Showtime__c show : shows){
				//Total Revenue should set to: 3750 for all showtimes.
				System.assertEquals(3750, show.Total_Revenue__c, 'Total Revenue is incorrect.');
			}
			Test.stopTest();
		}
	}

	/*
	 * @description: This tests the exception handling when calculating showtime revenue.
	 */
	private static testmethod void testReCalculateShowTimeRevenueExceptions(){
		
		Reservation__c res = createReservationForCampaign();
		
		try{
			//first param is expecting a set of showtime Ids, instead pass a set of campaign Ids
			//so that invalid Id exception will be occured.
			ReservationTriggerHelper.reCalculateShowTimeRevenue(new Set<Id>{campaign.Id}, 
				new List<Reservation__c>{res});
		}catch(Exception ex){
			System.assertNotEquals(null, ex);
			System.assertEquals(true, ex.getmessage().contains(Label.Reservation_Save_Error),
				'Reservation save error is not available.');
		}
	}

	/*
	 * @description: This tests the exception handling when counting campaign referrals.
	 */
	private static testmethod void testSetupTotalNumberofReferrals(){
		
		Reservation__c res = createReservationForShowTime();
		
		try{
			//first param is expecting a set of campaign Ids, instead pass a set of show Ids
			//so that invalid Id exception will be occured.
			ReservationTriggerHelper.setupTotalNumberofReferrals(new Set<Id>{showTime.Id}, 
				new List<Reservation__c>{res});
		}catch(Exception ex){
			System.assertNotEquals(null, ex);
			System.assertEquals(true, ex.getmessage().contains(Label.Reservation_Save_Error),
				'Reservation save error is not available.');
		}
	}
}