/* 
 *	@description: <NOTE:> This helper class has been implemented as WITHOUT SHARING to allow the visibility of
 *			all the Reservation__c records accors the organisation. As the Showtime__c OWD is set to
 *			private and the visibility of Reservation__c records is controlled by Showtime__c, 
 *			Reservation Takers only have access to the records owned by them. In order to calculate the 
 *			the total number of referrals per Campaign, full visiblity of reservations related to each
 *			Campaign is required. 
 */
public without sharing class ReservationCampaignHelper {

	public static List<AggregateResult> getAllReservationsByCampaign(Set<Id> campaignIds){
		AggregateResult[] reservationsByCampaigns;
		if(campaignIds != null && !campaignIds.isEmpty()){
		
			reservationsByCampaigns = [SELECT Referred_By__c, COUNT(Id) totalReferrals 
																FROM Reservation__c 
																WHERE Referred_By__c =:campaignIds 
																GROUP BY Referred_By__c];
		}
		return reservationsByCampaigns;
	}
}