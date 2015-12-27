/*
 * @description: This Utility Class provides a libarary to create test data for unit testing purposes.
 */
public with sharing class TestDataFactory {

	/*
	 * @description This method provides a list of Show Time instances
	 * @param Integer numberOfRecords - number of instances to create
	 * @param Date showdate - date of the Show Time
	 * @param String location - location of the Show Time
	 * @param String meal - meal - Lunch or Dinner at the Show Time
	 * @return 	List<Showtime__c> - show time instances.	
	 */
	public static List<Showtime__c> createShowTimes(Integer numberOfRecords, Date showdate, String location, String meal){
		List<Showtime__c> showTimes = new List<Showtime__c> ();
		
		if(numberOfRecords != null && numberOfRecords > 0){
			for(Integer i = 0; i < numberOfRecords; i++){
				showTimes.add(createShowTime('Test Name'+i,showdate, location, meal));
			}
		}
		return showTimes;
	}

	/*
	 * @description This method provides a list of Table instances
	 * @param Integer numberOfRecords - number of instances to create
	 * @param String section - Section of the $10 - Pauper, $15 - Duke & Duchess, $20 - Princess & Prince or $25 - Queen & King
	 * @param Integer seats - number of seats for the Table
	 * @return 	List<Table__c> - Table instances.	
	 */
	public static List<Table__c> createTables(Integer numberOfRecords, String section, String location, Integer seats){
		List<Table__c> tables = new List<Table__c> ();
		
		if(numberOfRecords != null && numberOfRecords > 0){
			for(Integer i = 0; i < numberOfRecords; i++){
				tables.add(createTable('Test Name'+i, section, location, seats));
			}
		}
		return tables;
	}

	/*
	 * @description This method provides a list of Reservation instances
	 * @param List<Table__c> tables - Tables which needs reserving
	 * @param List<Showtime__c> showTimes - ShowTimes for reserving
	 * @param Campaign campaign - Campaign which refered by
	 * @param Integer partySize - Number of guests for each reservation
	 * @return 	List<Reservation__c> - Reservation instances.	
	 */
	public static List<Reservation__c> createReservations(List<Table__c> tables, List<Showtime__c> showTimes, Campaign campaign, Integer partySize){
		List<Reservation__c> reservations = new List<Reservation__c> ();
		
		for(Table__c table : tables){
			for(Showtime__c showTime : showTimes){
				Id campaignId = campaign == null ? null : campaign.Id;
				reservations.add(createReservation(table.Id, showTime.Id, campaignId, partySize));
			}
		}
		
		return reservations;
	}

	/*
	 * @description This method provides of Campaign instance
	 * @param String name 
	 * @param String Description
	 * @return 	Campaign - campaign instance.	
	 */
	public static Campaign createCampaign(String name, String Description){
		Campaign campaign = new Campaign(Name = name, Description = description, IsActive = true);
		return campaign;
	}

	/*
	 * @description This method provides  of ShowTime instance
	 * @param Date showdate - date of the Show Time
	 * @param String location - location of the Show Time
	 * @param String meal - meal - Lunch or Dinner at the Show Time
	 * @return 	Showtime__c - show time instance.	
	 */
	public static Showtime__c createShowTime(String name, Date showDate, String location, String meal){
		Showtime__c showTime = new Showtime__c(Name = name, Date__c = showdate, Location__c = location, Meal__c = meal);
		return showTime;
	}

	/*
	 * @description This method provides of Table instance
	 * @param String section - Section of the $10 - Pauper, $15 - Duke & Duchess, $20 - Princess & Prince or $25 - Queen & King
	 * @param Integer seats - number of seats for the Table
	 * @return 	Table__c - Table instance.	
	 */
	public static Table__c createTable(String name, String section, String location, Integer seats){
		Table__c table = new Table__c(Name = name, Location__c = location, Section__c = section, Seats__c = seats);
		return table;
	}

	/*
	 * @description This method provides of Reservation instance
	 * @param Id table - Tables which needs reserving
	 * @param Id showtime showTimes - ShowTimes for reserving
	 * @param Id campaign - Campaign which refered by
	 * @param Integer partySize - Number of guests for each reservation
	 * @return 	Reservation__c - Reservation instance.	
	 */
	public static Reservation__c createReservation(Id table, Id showtime, Id campaign, Integer partySize){
		Reservation__c reservation = new Reservation__c(Showtime__c = showTime, Table__c = table, Referred_By__c = campaign, Party_Size__c = partySize);
		return reservation;
	}

	/*
	 * @description Create a test user
	 * @param String sProfile - profile name
	 * @return 	User - inserted user instance.	
	 */
	public static user createUser(String sProfile){

       Double randomNo = Math.random();

       Profile prof = [SELECT Id FROM Profile WHERE Name=: sProfile LIMIT 1];
       
       User usr = new User(Alias = 'test122',Email='test2@test.fca.gov.com',
                      EmailEncodingKey='UTF-8', LastName='Testing123', 
                      LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
                      ProfileId = prof.Id,TimeZoneSidKey='America/Los_Angeles',
                      UserName='matTest'+String.valueOf(randomNo).right(3)+'@matTestXY.com',
                      Title='Testing123');
       insert usr;
       return usr;
    }
}