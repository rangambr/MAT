/*
 * @description This is the controller for RervationSectionChart component.
 *				This class provides a data matrix for drawing a chart of
 *				Attendance vs Table Sections.
 */
public with sharing class ReservationSectionChart {
	
	/*
	 * @description Getter method for chart data matrix. This method
	 *				sorts reservations by section to calculate total
	 *				party size per section. Then builds the data matrix
	 *				for each picklist value defined in the Table__c
	 *				object.
	 * @param List<Reservation__c> currentReservations - List of Reservations per 
	 *		  showtime. 
	 */
	public static List<Data> getChartData(List<Reservation__c> currentReservations){

		List<Data> chartData = new List<Data>();

		if(currentReservations != null && currentReservations.size() > 0){	
			//Get a list of table sections defined in Table__c.Section__c
			//picklist field dyanmically so that if admin changes the picklist
			//this functionality still works.
			List<String> tableSections = MATAppSettings.tableSections;

			//Section by total party size maping for the current reservations.
			Map<String, Double> attendanceBySection = new Map<String, Double>();
			
			try{
				//populate attendanceBySection map by grouping reservations by section.
				for(Reservation__c reservation : currentReservations){

					if(! attendanceBySection.containsKey(reservation.Table__r.Section__c)){
						attendanceBySection.put(reservation.Table__r.Section__c, 0);
					}
					//Default reservation party size to 0 incase if the party size is null.
					Double reservationPartySize = reservation.Party_Size__c == null ? 0 : reservation.Party_Size__c;

					//Add this sections's reservation party size to existing to get the total.
					Double totalPartySize = attendanceBySection.get(reservation.Table__r.Section__c) 
						+ reservationPartySize;
					//populate map.
					attendanceBySection.put(reservation.Table__r.Section__c, totalPartySize);
				}
			} catch(SObjectException ex){
				ApexPages.Message errormsg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.QueryErrorChart);
            	ApexPages.addMessage(errormsg);
            	return chartData;
			}
			
			//Finally create the Data Matrix for the chart.
			for(String tableSection : tableSections){
				Double attendance = 0;
				
				if(attendanceBySection.containsKey(tableSection)){
					attendance = attendanceBySection.get(tableSection);
				}
				chartData.add(new Data(tableSection, attendance));
			}
		}
		return chartData;
	}

	/*
	 * @description Simple data wrapper which represents the Chart Data matrix.
	 * 				Chart is drawn Section vs. Attendance. x-axis is Section and 
	 *				y-axis is Attendance(Total Party Size).
	 */
	public class Data{

		public String section {get;set;}
		public Double attendance {get;set;}

		/*
		 * @description Overriden constructor.
		 */
		public Data(String section, Double attendance){
			this.section = section;
			this.attendance = attendance;
		}
	}
}