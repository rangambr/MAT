/*
 * @description: Reservation trigger populates "Total_Revenue__c" on "Show_Time__c" and "Total_Number_Referrals__c"
 *				 on "Campaign" when users create, edit, delete and undelete "Reservations".
 *				 "Total_Revenue__c" on "Show_Time__c" is calculated by summing the "Revenue__c" of all the associated 
 *				 "Reservations".
 *				 "Total_Number_Referrals__c" on "Campaign" is calculated by counting "Reservations" belong to each
 *				 "Campaign".
 */
trigger ReservationTrigger on Reservation__c (after insert, after update, after delete, after undelete) {
	//Revenues/Referrals are cacluated in after triggers to ensure data integrety.
	//Also check MATAppSettings to ensure trigger is enabled. This can be overritten during unit testing
	//to ensure trigger is not executing during test data creation.
	if(Trigger.isAfter && MATAppSettings.IsReservationTriggerEnabled){
		
		if(Trigger.isInsert || Trigger.isUndelete){
			ReservationTriggerHelper.calculateRevenueAndReferrals(Trigger.newMap);

		} else if(Trigger.isUpdate){
			ReservationTriggerHelper.calculateRevenueAndReferrals(Trigger.newMap, Trigger.oldMap);

		} else if(Trigger.isDelete){
			ReservationTriggerHelper.calculateRevenueAndReferrals(Trigger.oldMap);

		}
	}
}