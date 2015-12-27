/*
 * @description This class defines a set of constants used through out the application.
 */
public with sharing class MATAppConstants {

	/*
	 * Location and Section constants are defined here in case they get updated,
	 * it will be easier to change in one place.
	*/
	public static final String LOCATION_BOSTON = 'Boston';
	public static final String LOCATION_CHICAGO = 'Chicago';
	public static final String LOCATION_LA = 'Los Angeles';
	public static final String LOCATION_NY = 'New York';
	public static final String LOCATION_ORLANDO = 'Orlando';
	public static final String LOCATION_SANJOSE = 'San Jose';
	public static final String LOCATION_ALL = 'all';

	public static final String SECTION_10 = '$10 - Pauper';
	public static final String SECTION_15 = '$15 - Duke & Duchess';
	public static final String SECTION_20 = '$20 - Princess & Prince';
	public static final String SECTION_25 = '$25 - Queen & King';

	public static final String MEAL_LUNCH = 'Lunch';
	public static final String MEAL_DINNER = 'Dinner';

	public static final String RESERVATION_TAKER_PROFILE = 'Reservation Taker';
	public static final String MARKETING_MANAGER_PROFILE = 'Marketing Manager';
}