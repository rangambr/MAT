/*
 * @description: This Utility Class provides a libarary to create test data for unit testing purposes.
 */
public with sharing class TestDataFactory {

	/*
	 * @description This method provides a list of Campaign instances
	 * @param Integer numberOfRecords - number of instances to create
	 * @return 	List<Campaign> - campaign instances.	
	 */
	public static List<Campaign> createCampaigns(Integer numberOfRecords){
		List<Campaign> campaigns = new List<Campaign> ();
		
		if(numberOfRecords != null && numberOfRecords > 0){
			for(Integer i = 0; i < numberOfRecords; i++){
				campaigns.add(new Campaign(Name = 'testCampaign '+i, Description = 'Test Description '+i, IsActive = true));
			}
		}
		return campaigns;
	}

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
				showTimes.add(new Showtime__c(Name = 'testShowTime '+i, Date__c = showdate, Location__c = location, Meal__c = meal));
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
				tables.add(new Table__c(Name = 'testTable '+i, Location__c = location, Section__c = section, Seats__c = seats));
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
				reservations.add(new Reservation__c(Table__c = table.Id, Showtime__c = showTime.Id, Referred_By__c = campaign.Id, Party_Size__c = partySize));
			}
		}
		
		return reservations;
	}
	
}