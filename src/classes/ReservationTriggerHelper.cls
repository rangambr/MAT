/*
 * @description: This is a Helper Class for ReservationTrigger. This class provides methods to calculate
 *				 "Total_Revenue__c" on "ShowTime__c" and "Total_Number_Referrals__c"
 *				 on "Campaign" when users create, edit, delete and undelete "Reservations".
 *				 "Total_Revenue__c" on "ShowTime__c" is calculated by summing the "Revenue__c" of all the associated 
 *				 "Reservations".
 *				 "Total_Number_Referrals__c" on "Campaign" is calculated by counting "Reservations" belong to each
 *				 "Campaign".
 */
public with sharing class ReservationTriggerHelper {

	/* @description: This method identifies ShowTimes to calculate Revenue and Campaigns to count Referrals
	 *				 during an insert or undelete.
	 * @param:       Map<Id, Reservation__c> newMap - New Reservations inserted or undeleted.
	 * @return:      void
	 */
	public static void calculateRevenueAndReferrals(Map<Id, Reservation__c> newMap){
		
		Set<Id> showTimesToRecalculate = new Set<Id>();
		Set<Id> campaignIds = new Set<Id>();

		for(Reservation__c reservation : newMap.values()){
			//during an insert or undelete - if there is a ShowTime__c and a Party_Size__c revenue should be
			//recalculated.
			if(reservation.ShowTime__c != null && (reservation.Party_Size__c != null &&  reservation.Party_Size__c > 0)){
				showTimesToRecalculate.add(reservation.ShowTime__c);
			}

			//identify referrals inserted or undeleted per campaign.
			if(reservation.Referred_By__c != null){
				campaignIds.add(reservation.Referred_By__c);
			}
		}

		//recalculate Total_Revenue__c on ShowTimes
		reCalculateShowTimeRevenue(showTimesToRecalculate, newMap.values());

		//Setup Total_Number_Referrals__c on Campaign. 
		setupTotalNumberofReferrals(campaignIds, newMap.values());
	}

	/* @description: This method identifies ShowTimes to calculate Revenue and Campaigns to count Referrals
	 *				 during an update or delete.
	 * @param:       Map<Id, Reservation__c> newMap - New Reservations updated or deleted.
	 * @param:       Map<Id, Reservation__c> oldMap - Old Reservations update or deleted.
	 * @return:      void
	 */
	public static void calculateRevenueAndReferrals(Map<Id, Reservation__c> newMap, Map<Id, Reservation__c> oldMap){
		
		Set<Id> showTimesToRecalculate = new Set<Id>();
		Set<Id> campaignIds = new Set<Id>();

		for(Reservation__c newReservation : newMap.values()){
			//Identify Showtimes needs calculating Total_Revenue__c
			if(newReservation.ShowTime__c != oldMap.get(newReservation.Id).ShowTime__c
				|| (newReservation.Party_Size__c != oldMap.get(newReservation.Id).Party_Size__c)){
				showTimesToRecalculate.add(newReservation.ShowTime__c);
			}
			
			//New Referral is added
			if(newReservation.Referred_By__c != null && oldMap.get(newReservation.Id).Referred_By__c == null) {
				campaignIds.add(newReservation.Referred_By__c);
			} 
			//Referral is removed
			else if(newReservation.Referred_By__c == null && oldMap.get(newReservation.Id).Referred_By__c != null){
				campaignIds.add(oldMap.get(newReservation.Id).Referred_By__c);
			} 
			//Referral is changed from one Campaign to another
			else if(newReservation.Referred_By__c != oldMap.get(newReservation.Id).Referred_By__c){
				campaignIds.add(newReservation.Referred_By__c);
				campaignIds.add(oldMap.get(newReservation.Id).Referred_By__c);
			}
		}
		//recalculate revenue on ShowTimes
		reCalculateShowTimeRevenue(showTimesToRecalculate, newMap.values());

		//Setup Total_Number_Referrals__c on Campaign. 
		setupTotalNumberofReferrals(campaignIds, newMap.values());

	}

	/* @description: This method recalculates the Totla Revenue of  ShowTimes according to their Reservations.
	 *				 As there can be up to 50 Reservations per ShowTime, revenue can be efficiently recalculated
	 *				 with an Aggregate Query. 
	 * @param:       Set<Id> showTimeIds - ShowTimeIds which Revenue needs recalculating.  				
	 * @return:      void
	 */
	@testvisible
	private static void reCalculateShowTimeRevenue(Set<Id> showTimeIds, List<Reservation__c> reservations){
		
		if(! showTimeIds.isEmpty()){
			List<ShowTime__c> showTimesToUpdate = new List<ShowTime__c>();
			Map<Id, Double> totalRevPerShowTime = new Map<Id, Double> ();

			AggregateResult[] reservationsByShowTime;

			try {
				reservationsByShowTime = [SELECT ShowTime__c, SUM(Revenue__c) totalRevenue 
																FROM Reservation__c 
																WHERE ShowTime__c =:showTimeIds GROUP BY ShowTime__c];

				for (AggregateResult reservationByShowTime : reservationsByShowTime)  {
					totalRevPerShowTime.put((Id)reservationByShowTime.get('ShowTime__c'), 
						(Decimal)reservationByShowTime.get('totalRevenue'));
				}

				for(Id showTimeId : showTimeIds){
					if(totalRevPerShowTime.containsKey(showTimeId)){
						showTimesToUpdate.add(new Showtime__c(Id = showTimeId, 
							Total_Revenue__c = totalRevPerShowTime.get(showTimeId)));
					} else {
						showTimesToUpdate.add(new Showtime__c(Id = showTimeId, Total_Revenue__c = 0.00));
					}
				}

				if(showTimesToUpdate.size() > 0){
					update showTimesToUpdate;
				}
			} catch(Exception ex) {
				//If any other exception occurs, display the message to the end user.
				for(Reservation__c reservation : reservations) {
					reservation.addError(Label.Reservation_Save_Error+':'+ex.getMessage());
				}
			}
		}
	}

	/* @description: This method calculates the Total_Number_Referrals__c on Campaigns. As there can be up to
	 *				 10000 Referrals per Campaign, there is a possibility that Aggregate Query could reach limits if 
	 *				 there are more than 5 Campaingns with 10000 Referrals get updated in the same transaction.
	 *				 In case if there is an exception, reservation records will not be updated or inserted and error
	 *				 message will be displayed to the user.
	 *				 
	 *				 <NOTE> ReservationCampaignHelper is made "WITHOUT SHARING" so that all Reservations for each
	 *				 campaign get counted regardless of "Reservation Takers'"" record level read permissions for Reservations.
	 *				 Alternative way of implementation would be to only increment or decrement Referrals when users add/
	 *				 remove Referrals but as existing data is not up-to-date with correct number of referrals, this 
	 *				 approach is not feasible.
	 *				
	 * @param:       Set<Id> campaignIds - Campaigns which needs calculating number of referrals.
	 * @param:       List<Reservation__c> reservations - List of Reservations being inserted/updated. Used to add
	 *				 error message if there is any.
	 * @return:      void
	 */
	@testvisible
	private static void setupTotalNumberofReferrals(Set<Id> campaignIds, List<Reservation__c> reservations){
		
		if(! campaignIds.isEmpty()){

			List<Campaign> campaignsToUpdate = new List<Campaign>();
			AggregateResult[] reservationsByCampaigns;
			
			try {
				reservationsByCampaigns = ReservationCampaignHelper.getAllReservationsByCampaign(campaignIds);
			 
				Map<Id, Integer> currentReferralsPerCampaign = new Map<Id, Integer> ();
				
				//Get count of existing referals per campaign.
				for (AggregateResult reservationsByCampaign : reservationsByCampaigns)  {
					currentReferralsPerCampaign.put((Id)reservationsByCampaign.get('Referred_By__c'), 
						(Integer)reservationsByCampaign.get('totalReferrals'));
				}
				//validate existing campaigns has correct count.
				for(Id campaignId : campaignIds){
					//If the campaign has any reservations referred by update with the latest.
					if(currentReferralsPerCampaign.containsKey(campaignId)){
						campaignsToUpdate.add(new Campaign(Id = campaignId, 
							Total_Number_Referrals__c = currentReferralsPerCampaign.get(campaignId)));
					}
					//If the campaign do not have any referrals, i.e referral is removed from the Reservation;
					//set the total number of referrals to zero.
					 else {
						campaignsToUpdate.add(new Campaign(Id = campaignId, Total_Number_Referrals__c = 0));
					}
				}

				if(campaignsToUpdate.size() > 0){
					update campaignsToUpdate;
				
				}
			} catch(LimitException ex){
				for(Reservation__c reservation : reservations){
					reservation.addError(Label.Reservation_Aggregate_Query_Error_Referrals+':'+ex.getMessage());
				}
			} catch(Exception ex){
				//If there are any exceptions notify user.
				for(Reservation__c reservation : reservations){
					reservation.addError(Label.Reservation_Save_Error+':'+ex.getMessage());
				}
			}
		}
	}
}