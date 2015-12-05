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
		//This map holds how many Referrals made per Campaign.
		Map<Id, Integer> referralsPerCampaign = new Map<Id, Integer>();

		for(Reservation__c reservation : newMap.values()){
			//during an insert or undelete - if there is a ShowTime__c and a Party_Size__c revenue should be
			//recalculated.
			if(reservation.ShowTime__c != null || reservation.Party_Size__c != null){
				showTimesToRecalculate.add(reservation.ShowTime__c);
			}

			//identify referrals inserted or undeleted per campaign.
			if(reservation.Referred_By__c != null){
				referralsPerCampaign = incrementReferralsPerCampaign(referralsPerCampaign, reservation.Referred_By__c);
			}
		}

		//recalculate revenue on ShowTimes
		reCalculateShowTimeRevenue(showTimesToRecalculate);

		//Setup Total_Number_Referrals__c on Campaign. During an insertion or undeletion there will always
		//increments to the number of referrals per campaign hence a new empty map is passed to the helper method.
		setupTotalNumberofReferrals(referralsPerCampaign, new Map<Id, Integer>());
	}

	/* @description: This method identifies ShowTimes to calculate Revenue and Campaigns to count Referrals
	 *				 during an update or delete.
	 * @param:       Map<Id, Reservation__c> newMap - New Reservations updated or deleted.
	 * @param:       Map<Id, Reservation__c> oldMap - Old Reservations update or deleted.
	 * @return:      void
	 */
	public static void calculateRevenueAndReferrals(Map<Id, Reservation__c> newMap, Map<Id, Reservation__c> oldMap){
		
		Set<Id> showTimesToRecalculate = new Set<Id>();
		Map<Id, Integer> referralsPerCampaignToAdd = new Map<Id, Integer>();
		Map<Id, Integer> referralsPerCampaignToRemove = new Map<Id, Integer>();

		for(Reservation__c newReservation : newMap.values()){
			//setup Revenue on ShowTime
			if(newReservation.ShowTime__c != oldMap.get(newReservation.Id).ShowTime__c
				|| newReservation.Party_Size__c != oldMap.get(newReservation.Id).Party_Size__c){
				showTimesToRecalculate.add(newReservation.ShowTime__c);
			}
			//New Referral is added
			if(newReservation.Referred_By__c != null && oldMap.get(newReservation.Id).Referred_By__c == null) {
				incrementReferralsPerCampaign(referralsPerCampaignToAdd, newReservation.Referred_By__c);
			} 
			//Referral is removed
			else if(newReservation.Referred_By__c == null && oldMap.get(newReservation.Id).Referred_By__c != null){
				incrementReferralsPerCampaign(referralsPerCampaignToRemove, oldMap.get(newReservation.Id).Referred_By__c);
			} 
			//Referral is changed from one Campaign to another
			else if(newReservation.Referred_By__c != oldMap.get(newReservation.Id).Referred_By__c){
				incrementReferralsPerCampaign(referralsPerCampaignToAdd, newReservation.Referred_By__c);
				incrementReferralsPerCampaign(referralsPerCampaignToRemove, oldMap.get(newReservation.Id).Referred_By__c);
			}
		}
		//recalculate revenue on ShowTimes
		reCalculateShowTimeRevenue(showTimesToRecalculate);

		//Setup Total_Number_Referrals__c on Campaign. During an insertion or undeletion there will always
		//increments to the number of referrals per campaign hence a new empty map is passed to the helper method.
		setupTotalNumberofReferrals(referralsPerCampaignToAdd, referralsPerCampaignToRemove);

	}

	/* @description: This method recalculates the Totla Revenue of  ShowTimes according to their Reservations.
	 *				 As there can be up to 50 Reservations per ShowTime, revenue can be efficiently recalculated
	 *				 with an Aggregate Query. 
	 * @param:       Set<Id> showTimeIds - ShowTimeIds which Revenue needs recalculating.  				
	 * @return:      void
	 */
	private static void reCalculateShowTimeRevenue(Set<Id> showTimeIds){
		
		if(! showTimeIds.isEmpty()){
			List<ShowTime__c> showTimesToUpdate = new List<ShowTime__c>();

			AggregateResult[] reservationsByShowTime = [SELECT ShowTime__c, SUM(Revenue__c) totalRevenue 
															FROM Reservation__c 
															WHERE ShowTime__c=:showTimeIds GROUP BY ShowTime__c];
			
			for (AggregateResult reservationByShowTime : reservationsByShowTime)  {
			    showTimesToUpdate.add(new ShowTime__c(Id = (Id)reservationByShowTime.get('ShowTime__c'), 
			    	Total_Revenue__c = (Decimal)reservationByShowTime.get('totalRevenue')));
			}

			if(showTimesToUpdate != null && showTimesToUpdate.size() > 0){
				update showTimesToUpdate;
			}
		}
	}

	/* @description: This method calculates the Total_Number_Referrals__c on Campaigns. As there can be up to
	 *				 10000 Referrals per Campaign, this method identifies the changes to Referrals and updates
	 * 				 only affected Campaigns rather than recalculating total number of referrals per Campaign.
	 * @param:       Map<Id, Integer> referralsPerCampaignToAdd - Referrals added per Campaign
	 * @param:       Map<Id, Integer> referralsPerCampaignToRemove - Referrals removed per Campaign
	 * @return:      void
	 */
	private static void setupTotalNumberofReferrals(Map<Id, Integer> referralsPerCampaignToAdd, 
		Map<Id, Integer> referralsPerCampaignToRemove){

		//Get a set of all affected Campaigns
		Set<Id> campaignIdsToUpdate = new Set<Id>(referralsPerCampaignToAdd.keySet());
		campaignIdsToUpdate.addAll(referralsPerCampaignToRemove.keySet());

		if(!campaignIdsToUpdate.isEmpty()){
			
			List<Campaign> campaignsToUpdate = [SELECT Id, Total_Number_Referrals__c 
														FROM Campaign 
														WHERE Id=:campaignIdsToUpdate];

			for(Campaign campaignToUpdate : campaignsToUpdate){
				//If Total_Number_Referrals__c is null default to zero.
				Decimal totalReferrals = campaignToUpdate.Total_Number_Referrals__c == null ? 0
				 : campaignToUpdate.Total_Number_Referrals__c;

				if(referralsPerCampaignToAdd.containsKey(campaignToUpdate.Id)){
					totalReferrals +=  referralsPerCampaignToAdd.get(campaignToUpdate.Id);
				}
				if(referralsPerCampaignToRemove.containsKey(campaignToUpdate.Id)){
					totalReferrals -=  referralsPerCampaignToRemove.get(campaignToUpdate.Id);
				}
				campaignToUpdate.Total_Number_Referrals__c = totalReferrals;
			}
			update campaignsToUpdate;
		}
	}

	/* @description: This helper method increments the number of referrals per each campaign by one.
	 * @param: Map<Id, Integer> referralsPerCampaign - Mapping of Campaign to number of referrals
	 * @param: Id campaignId - Id of the campaign to increment the number.
	 * @return: Map<Id, Integer>
	 */
	@testVisible
	private static Map<Id, Integer> incrementReferralsPerCampaign(Map<Id, Integer> referralsPerCampaign, Id campaignId){
		
		if(referralsPerCampaign.containsKey(campaignId)){
			referralsPerCampaign.put(campaignId,
				referralsPerCampaign.get(campaignId) + 1);
		} else {
			referralsPerCampaign.put(campaignId, 1);
		}
		return referralsPerCampaign;
	}
}