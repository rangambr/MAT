/*
 * @description Controller extension for ShowtimeManager page. Allows users to create/edit showtime,
 *              create/edit Reservations for a showtime and view total attendance vs. table section
 *              chart.
 *              Asumptions: 
 *              1. When users create a new Showtime, all the Tables in the system are available to select
 *              and Tables are not filtered by the location of the showtime.
 *              
 *              2. While editing exiting showtime, if users change the location of the showtime,
 *              listed tables are not getting updated for the new location. It is assumed that users always
 *              save the location and of the showtime first and then add reservations for it.
 */
public with sharing class ShowTimeManager {

    //Number of table records displayed at a time
    public final Integer pageSize{get;set;}
    //Total number of Tables in the system - filtered by the location(if available)
    public Integer totalNoOfRecords{get;set;}
    //Table Section selected by the user so that they can filter the tables list.
    public String selectedSection{get;set;}

    //Showtime record 
    @testvisible
	private Showtime__c showtime;
    //Reservations by the Table. Behaves as an identity map. 
    //Maps Table to Reservation created/edited for this showtime.
    @testvisible
    private Map<Id, Reservation__c> tableReservation;

    private ApexPages.StandardController stdShowtime;
    //StandardSetController for tables for this showtime.
    private ApexPages.StandardSetController tableSet;

    /*
     * @description Overriden constructor. Initialises showtime and tablereservation map.
     *              Also populates current Reservations and setup default value for 
     *              Table Section filter.
     */
    public ShowTimeManager(ApexPages.StandardController stdShowtime) {
        
        this.stdShowtime = stdShowtime;
        this.showtime = (Showtime__c)stdShowtime.getRecord();

        this.tableReservation = new Map<Id, Reservation__c>();
        this.selectedSection = MATAppConstants.LOCATION_ALL;

        setupReservations();

        pageSize = 5;

        //setup the tables standard set controller.
        setupTableSet();
    }

    /*
     * @description Provides a list of available Table Sections. Default is --Any Type--.
     *              Sections are dynamically populated from Section__c picklist on Table__c
     *              so that this would support future changes.
     */
    public List<SelectOption> getSectionFilter(){
        List<SelectOption> sections = new List<SelectOption>();
        
        sections.add(new SelectOption(MATAppConstants.LOCATION_ALL, Label.AllTableSections));
        
        for(String section : MATAppSettings.tableSections){
            sections.add(new SelectOption(section, section));
        }
        return sections;
    }

    /*
     * @description Refresh StandardSetController for tables. This method is executed if user
     *              changes the filter criteria (Location/Table Section)
     */
    public PageReference setupTableSet(){

        String queryString = getQueryString();
        
        try{
            tableSet = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
            tableSet.setPageSize(pageSize);
            totalNoOfRecords = tableSet.getResultSize();
        } catch(Exception ex){
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                Label.ShowtimeManagerQueryError);
            ApexPages.addMessage(errormsg);
        }
        return null;
    }

    /*
     * @description Provides list of reservations to be displayed.
     */
    public List<Reservation__c> getReservations(){

        List<Reservation__c> resList = new List<Reservation__c>();

        for(Table__c t : (List<Table__c>)tableSet.getRecords()){
            if(tableReservation.containsKey(t.Id)){
                resList.add(tableReservation.get(t.Id));
            } else {
                Reservation__c res = new Reservation__c(Showtime__c = showtime.Id, 
                    Table__c = t.Id, Party_Size__c = 0, Table__r = t);

                resList.add(res);
                tableReservation.put(t.Id, res);
            }
            
        }
        return resList;
    }

    /*
     * @description Provides data for total party size vs. table section chart.
     */
    public List<ReservationSectionChart.Data> getChartData(){
        
        List<Reservation__c> resList = new List<Reservation__c>();

        for(Id resId : tableReservation.keySet()){
            if(tableReservation.get(resId).Party_Size__c > 0){
                resList.add(tableReservation.get(resId));
            }
        }

        return ReservationSectionChart.getChartData(resList);
    }

    /*
     * @description Saves Showtime and associated Reservations.
     */
    public PageReference save(){

        List<Reservation__c> reservationsToUpsert = new List<Reservation__c>();
        List<Reservation__c> reservationsToDelete = new List<Reservation__c>();

        //Create a save point before saving the showtime so that if an exception
        //occurs while saving Reservations, we can roll back to any changes to the
        //showtime.
        Savepoint sp = Database.setSavepoint();
        try{
            //save the Showtime.
            upsert showtime;

        } catch(Exception ex){
            //catch any exception while dml - future validation rules etc.
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                Label.ShowtimeSaveError);
            ApexPages.addMessage(errormsg);
            return null;
        }

        //save Reservations
        for(Id tableId : tableReservation.keySet()){
            
            if(tableReservation.get(tableId).Party_Size__c > 0){
                //assign showtime Id - incase this is a new record
                if(tableReservation.get(tableId).Showtime__c == null){
                    tableReservation.get(tableId).Showtime__c = showtime.Id;
                }
                reservationsToUpsert.add(tableReservation.get(tableId));
            } else if(tableReservation.get(tableId).Party_Size__c != null &&
                tableReservation.get(tableId).Party_Size__c < 0){
                //catch any exception while dml - future validation rules etc.
                ApexPages.Message errormsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                Label.Party_Size_Error);
                ApexPages.addMessage(errormsg);
                return null;
            }

            if(tableReservation.get(tableId).Party_Size__c == 0
                && tableReservation.get(tableId).Id != null){
                reservationsToDelete.add(tableReservation.get(tableId));
            }
        }

        try{
            if(! reservationsToUpsert.isEmpty()){
                upsert reservationsToUpsert;
            }
            if(! reservationsToDelete.isEmpty()){
                delete reservationsToDelete;
            }

        }  catch(Exception ex) {
            //Undo Saving of save to Showtime if Reservations cannot be saved.
            Database.rollback(sp);
            
            //catch any exception while dml - future validation rules etc.
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                Label.ReservationSaveError);
            ApexPages.addMessage(errormsg);
            return null;
        }

        //redirect users to Showtime after saving.
        return new PageReference('/'+this.showtime.Id);
    }

    /*
     * @description Table navigation. Can the user navigate forward?
     */
    public Boolean hasNext {
        get {
            return tableSet.getHasNext();
        }
        set;
    }

    /*
     * @description Table navigation. Can the user navigate back?
     */
    public Boolean hasPrevious {
        get {
            return tableSet.getHasPrevious();
        }
        set;
    }
  
    /*
     * @description Provides the current page number of the table list.
     */
    public Integer pageNumber {
        get {
            return tableSet.getPageNumber();
        }
        set;
    }
  
    /*
     * @description Table navigation first.
     */
    public void first() {
        tableSet.first();
    }
  
    /*
     * @description Table naviagation last.
     */
    public void last() {
        tableSet.last();
    }
  
    /*
     * @description Table naviation previous.
     */
    public void previous() {
        tableSet.previous();
    }
  
    /*
     * @description Table navigation next.
     */
    public void next() {
        tableSet.next();
    }

    /*
     * @description Load existing reservations for the showtime and populate the identity map initially.
     */
    @testvisible
    private void setupReservations(){
        
        if(showtime != null && showtime.Id != null){
            List<Reservation__c> reservations = [SELECT Id, Table__c, Table__r.Section__c, Table__r.Seats__c,
                                Table__r.Location__c, Party_Size__c, Referred_By__c, Table__r.Name, Showtime__c 
                                FROM Reservation__c WHERE Showtime__c=:showtime.Id];

            for(Reservation__c reservation : reservations){
                tableReservation.put(reservation.Table__c, reservation);
            }
        }
    }

    /*
     * @description Provides a query stirng with filtered applied according to current user selection.
     */
    @testvisible
    private String getQueryString(){
        
        //escape any single quotes
        selectedSection = String.escapeSingleQuotes(selectedSection);

        String locationFilter = showtime.Location__c != null ? ' Location__c = \''+showtime.Location__c+'\'' : '';
        String sectionFilter = selectedSection != 'all' ? ' Section__c = \''+selectedSection+'\'' : '';

        String filterString;

        if(locationFilter != '' && sectionFilter != ''){
           filterString = ' WHERE '+locationFilter+' AND '+sectionFilter;
        } else if(locationFilter != '' && sectionFilter == ''){
            filterString = ' WHERE '+locationFilter;
        } else if(locationFilter == '' && sectionFilter != ''){
            filterString = ' WHERE '+sectionFilter;
        } else {
            filterString = '';
        }
        
        String queryString = 'SELECT Id, Name, Seats__c, Section__c, Location__c FROM '+
                                'Table__c '+filterString+' '+
                                    ' ORDER BY Seats__c, Section__c ';
        return queryString;
    }
}