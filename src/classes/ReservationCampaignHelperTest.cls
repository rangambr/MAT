@isTest
private class ReservationCampaignHelperTest {
	
	@testSetup
	private static void setupTestData(){

		Campaign campaign1 = TestDataFactory.createCampaign('campaign1','Desc1');
		insert campaign1;

		Campaign campaign2 = TestDataFactory.createCampaign('campaign2', 'Desc2');
		insert campaign2;

		List<Showtime__c> shows = TestDataFactory.createShowTimes(80, System.today().addDays(50), 
			MATAppConstants.LOCATION_SANJOSE, MATAppConstants.MEAL_DINNER);
		insert shows;

		List<Table__c> tables = TestDataFactory.createTables(80, MATAppConstants.SECTION_10, 
			MATAppConstants.LOCATION_SANJOSE, 5);
		insert tables;

		//Create 6400 Reservations 
		List<Reservation__c> reservations = TestDataFactory.createReservations(tables, shows, null, 3);

		//3500 referred by campaign1
		for(Integer i = 0; i < 3500; i++){
			reservations[i].Referred_By__c = campaign1.Id;
		}

		//1500 referred by campaign2 and 1400 reservations do not have a referred by
		for(Integer i= 3500; i < 5000; i++){
			reservations[i].Referred_By__c = campaign2.Id;
		}
		//Turn off the Reservation Trigger to avoid any limit are being hit while loading
		//5000 Reservations in one go.
		MATAppSettings.IsReservationTriggerEnabled = false;
		insert reservations;

	}

	@isTest static void testWithNoCampaigns(){

		Test.startTest();

		AggregateResult[] reservationsByCampaigns = ReservationCampaignHelper.getAllReservationsByCampaign(null);

		System.assertEquals(null, reservationsByCampaigns);

		Test.stopTest();
	}

	@isTest static void testGetAllReservationsByCampaign() {
		
		Campaign[] campaign1 = [SELECT Id FROM Campaign WHERE Name = 'campaign1'];
		Campaign[] campaign2 = [SELECT Id FROM Campaign WHERE Name = 'campaign2'];

		System.assertEquals(1, campaign1.size());
		System.assertEquals(1, campaign2.size());

		Test.startTest();

		Set<Id> campaigns = new Set<Id>{campaign1[0].Id, campaign2[0].Id};

		AggregateResult[] reservationsByCampaigns = ReservationCampaignHelper.getAllReservationsByCampaign(campaigns);

		for(AggregateResult reservationsByCampaign : reservationsByCampaigns){
			//campaign 1 should have 3500 rervations
			if((Id)reservationsByCampaign.get('Referred_By__c') == campaign1[0].Id){
				System.assertEquals(3500, reservationsByCampaign.get('totalReferrals'));
			}
			//campaign 2 should have 1500 reservations
			if((Id)reservationsByCampaign.get('Referred_By__c') == campaign2[0].Id){
				System.assertEquals(1500, reservationsByCampaign.get('totalReferrals'));
			}
		}
		
		System.assertEquals(5000, LIMITS.getQueryRows());

		Test.stopTest();
	}

	@isTest static void testReferralCountForTestTaker(){
		
		Campaign[] campaign1 = [SELECT Id FROM Campaign WHERE Name = 'campaign1'];
		
		System.assertEquals(1, campaign1.size());

		Set<Id> campaigns = new Set<Id>{campaign1[0].Id};

		User testTaker = TestDataFactory.createUser(MATAppConstants.RESERVATION_TAKER_PROFILE);

		Test.startTest();

		//create a new reservation as a test taker and validate referral count in the query.
		//this is to validate all records are getting queried to calculate Total No of Referrals on
		//Campaign.
		System.runAs(testTaker){

			Showtime__c show = TestDataFactory.createShowTime('test show 2', System.today().addDays(10),
			MATAppConstants.LOCATION_SANJOSE, MATAppConstants.MEAL_DINNER);

			insert show;

			Table__c table = TestDataFactory.createTable('table 2', MATAppConstants.SECTION_10,
			MATAppConstants.LOCATION_SANJOSE, 2);

			insert table;

			Reservation__c reservation = TestDataFactory.createReservation(table.Id, show.Id, campaign1[0].Id, 2);
			insert reservation;

			AggregateResult[] reservationsByCampaigns = ReservationCampaignHelper.getAllReservationsByCampaign(campaigns);

			for(AggregateResult reservationsByCampaign : reservationsByCampaigns){
				//campaign 1 should have 3501 rervations
				if((Id)reservationsByCampaign.get('Referred_By__c') == campaign1[0].Id){
					System.assertEquals(3501, reservationsByCampaign.get('totalReferrals'));
				}
			}
		}

		Test.stopTest();

	}
}