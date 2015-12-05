/*
 * @description: This is a utility class to support app fucntionality.
 * 				 App related settings can be specified here.
 */
public with sharing class MATAppSettings {
	//Reservation Trigger can be enabled and disabled using this variable. This is 
	//set to true by default. Used in unit testing so that we can create test data
	//without invoking triggers.
	public static Boolean IsReservationTriggerEnabled = true;

	public static List<String> tableLocations{
		get{
			if(tableLocations == null){
				tableLocations = new List<String>();
				Schema.DescribeFieldResult fieldResult = Table__c.Location__c.getDescribe();
   				List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
		   		for( Schema.PicklistEntry f : ple){
		      		tableLocations.add(f.getValue());
		   		}      
			}
			return tableLocations;
		} set;
	}

	public static List<String> tableSections{
		get{
			if(tableSections == null){
				tableSections = new List<String>();
				Schema.DescribeFieldResult fieldResult = Table__c.Section__c.getDescribe();
   				List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
		   		for( Schema.PicklistEntry f : ple){
		      		tableSections.add(f.getValue());
		   		}      
			}
			return tableSections;
		} set;
	}

	public static List<String> showTimeLocations{
		get{
			if(showTimeLocations == null){
				showTimeLocations = new List<String>();
				Schema.DescribeFieldResult fieldResult = ShowTime__c.Location__c.getDescribe();
   				List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
		   		for( Schema.PicklistEntry f : ple){
		      		showTimeLocations.add(f.getValue());
		   		}      
			}
			return showTimeLocations;
		} set;
	}

	public static List<String> showTimeMeals{
		get{
			if(showTimeMeals == null){
				showTimeMeals = new List<String>();
				Schema.DescribeFieldResult fieldResult = ShowTime__c.Meal__c.getDescribe();
   				List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
		   		for( Schema.PicklistEntry f : ple){
		      		showTimeMeals.add(f.getValue());
		   		}      
			}
			return showTimeMeals;
		} set;
	}
}