@isTest
private class MATAppSettingsTest {
	
	private static testmethod void testTableLocations() {
		List<String> locations = MATAppSettings.tableLocations;

		Schema.DescribeFieldResult fieldResult = Table__c.Location__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    
   		for(Integer i = 0; i < ple.size(); i++){
   			System.assertEquals(ple[i].getValue(), locations[i]);
   		}      
	}
	
	private static testmethod void testTableSections() {
		List<String> sections = MATAppSettings.tableSections;

		Schema.DescribeFieldResult fieldResult = Table__c.Section__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    
   		for(Integer i = 0; i < ple.size(); i++){
   			System.assertEquals(ple[i].getValue(), sections[i]);
   		}      
	}
	
	private static testmethod void testShowTimeLocations() {
		List<String> locations = MATAppSettings.showTimeLocations;

		Schema.DescribeFieldResult fieldResult = Showtime__c.Location__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    
   		for(Integer i = 0; i < ple.size(); i++){
   			System.assertEquals(ple[i].getValue(), locations[i]);
   		}      
	}

	private static testmethod void testShowTimeMeals() {
		List<String> meals = MATAppSettings.showTimeMeals;

		Schema.DescribeFieldResult fieldResult = Showtime__c.Meal__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    
   		for(Integer i = 0; i < ple.size(); i++){
   			System.assertEquals(ple[i].getValue(), meals[i]);
   		}      
	}
}