/**
* Controller class for the Account statement PDF page.
* @author Anand
* @date 11/23/2017 
*/
public class AccountStatementPDFCtrl{
    
    public string fromDate{get;set;}
    public string toDate{get;set;}
    public Contact Individual{get;set;}
    public double amount{get;set;}
    public List<Activitytracking__c> activityTrackingList{get;set;}
    public date frmdt {get;set;}
    public date todt {get;set;}
    public string sortOrder {get;set;}
    public string sortColumn {get;set;}
    public string query_select = MyRewardsSettings__c.getOrgDefaults().MRAQueryString1__c + MyRewardsSettings__c.getOrgDefaults().MRAQueryString2__c;//'SELECT Individual__r.MRAStatus__c,Individual__r.AvailableBalance__c,Individual__r.AccountBalance__c,Individual__r.CurrentlyOnHold__c,Individual__r.Name,Individual__r.MailingStreet1__c,Individual__r.MailingStreet2__c, Individual__r.CityMailing__c,Individual__r.StateMailing__c,Individual__r.ZipMailing__c,';// StartDate__C, Activitytype__c,activityDescription__c,PostedDate__c, Activitystatus__c, Reason__c,EarnedValue__c,enddate__c FROM activitytracking__c WHERE (enddate__c >=: frmdt AND enddate__c <=: todt) AND Individual__c =: getContactId AND MRAStatusOnCompletion__c!=null';
    public string query_sorting = '';
    public static FINAL string groupName = 'My Rewards Account Statement';
    public static FINAL string WRKPART_RECDTYPE = 'Work Participation Progress';
    public string mrastatus {get;set;}
    public Date dispDate {get;set;}
    public void generateAccStatement()
    {  //Initialising Amount to zero
        amount = 0.00;
        
        //List<Activitytracking__c> acttrk = new List<Activitytracking__c>();
        try{
            
            dispDate = TimeTravelSetting__c.getInstance().Today__c != null? TimeTravelSetting__c.getInstance().Today__c : System.today();
            //fetching userId to get the Individual's Contact ID
            id userId = UserInfo.getUserId();
            User u = [select id, contactId from User where id = : userId LIMIT 1];
            if(u.contactId !=null){
                id getContactId = u.contactId;
                mrastatus = GeneralUtility.getMRAStatus(getContactId);
                //getting date parameters from the request URL
                fromDate  = apexpages.currentpage().getparameters().get('fromDate');
                toDate  = apexpages.currentpage().getparameters().get('toDate');
                sortOrder  = apexpages.currentpage().getparameters().get('sortOrder');
                sortColumn  = apexpages.currentpage().getparameters().get('sortColumn');
                
                if((String.isNotBlank(fromDate) && (fromDate != 'null') )&& (String.isNotBlank(toDate) && (toDate != 'null'))){
                    
                    frmdt =date.valueOf(fromDate);
                    todt =date.valueOf(toDate);
                }
                //else if(fromDate == 'null' && toDate == 'null')
                else //if((fromDate == 'null' && toDate == 'null')||(fromDate != 'null' && toDate == 'null')||(fromDate == 'null' && toDate != 'null')){
                    if((fromDate == 'null' || toDate == 'null') || (fromDate == '' || toDate == '')) {
                    toDate = String.valueOf(TimeTravelSetting__c.getInstance().Today__c != null? TimeTravelSetting__c.getInstance().Today__c : System.today()); //String.valueOf(System.today());
                    fromDate = System.Label.MRAAccountStatementStartDate;
                    frmdt =date.valueOf(fromDate);
                    todt =date.valueOf(toDate);
                }
                if(String.isBlank(sortColumn) && String.isBlank(sortOrder)){
                    sortColumn = 'enddate__c';
                    sortOrder = 'DESC';
                }else{
                    if(sortOrder == 'arrowup'){
                        sortOrder = 'ASC';
                    }
                    else if(sortOrder == 'arrowdown'){
                        sortOrder = 'DESC';
                    }
                }
                //query to get Metadata__c object fileds to be queried
                MetaData__c objMetadata = [SELECT Id, Name, AvailableForDashboard__c, FieldName__c  , DisplayColumns__c, ObjectName__c
                                           FROM MetaData__c 
                                           WHERE Name=:groupName LIMIT 1];
               // System.debug('****split list '+objMetadata.DisplayColumns__c.split(','));
                for(String field : objMetadata.DisplayColumns__c.replaceAll( '\\s+', '').split(',')) {
                    Schema.DisplayType fieldType = Schema.getGlobalDescribe().get(objMetadata.ObjectName__c).getDescribe().fields.getMap().get(field).getDescribe().getType();
                    if (fieldType == Schema.DisplayType.PICKLIST) {
                        query_select +=  'toLabel(' + field + ')'+',';
                    }
                    else{
                        query_select += field+',';
                    }
                }      
                
                string wrkPartRecdTyp = Schema.SObjectType.ActivityTracking__c.getRecordTypeInfosByName().get(WRKPART_RECDTYPE).getRecordTypeId();
                //adding query fields and bject from metadata__c   //objMetadata.DisplayColumns__c+ ','
                query_select +=   objMetadata.FieldName__c +' FROM '+ objMetadata.ObjectName__c+' '+String.escapeSingleQuotes(MyRewardsSettings__c.getOrgDefaults().MRAQueryStringWhereClause__c);
               
                //Query to get activity tracking records associated with the Individual
                
                query_sorting = ' ORDER BY '+sortColumn+' '+sortOrder;
                
                string query = query_select+query_sorting;
                System.debug('***query:: '+query);
                activityTrackingList = Database.query(query);
                System.debug('***activityTrackingList:: '+activityTrackingList);
                /*activityTrackingList= [SELECT Individual__r.MRAStatus__c,Individual__r.AvailableBalance__c,Individual__r.AccountBalance__c,Individual__r.CurrentlyOnHold__c,
Individual__r.Name,Individual__r.MailingStreet1__c,Individual__r.MailingStreet2__c, Individual__r.CityMailing__c,
Individual__r.StateMailing__c,Individual__r.ZipMailing__c, StartDate__C, Activitytype__c,
activityDescription__c,PostedDate__c, Activitystatus__c, EarnedValue__c,enddate__c 
FROM activitytracking__c
WHERE (enddate__c >=: frmdt AND enddate__c <=: todt) AND Individual__c =: getContactId AND MRAStatusOnCompletion__c!=null
ORDER BY enddate__c DESC LIMIT 10000];*/
                
                if(activityTrackingList.size()>0){
                    
                    //Calculate the total amount for the earned activities
                    for(Activitytracking__c act:activityTrackingList){
                        if(act.EarnedValue__c != null && act.ActivityStatus__c == 'Earned')
                            amount+=act.EarnedValue__c;
                    }
                    
                }
                
            }
        }
        catch(Exception e){
            System.debug('Error has Occured: '+e.getMessage());
        }
        
    }
}