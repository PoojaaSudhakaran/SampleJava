/**
* Name : MonthlyTrackingNotificatcationSchedular 
* Description: This class is used to iterate over all the 'Work Participation Progress' ActivityTracking__c and creats notifications 
* 
* @author Varun Singh 
* @date 02/01/2018
* MODIFICATION LOG:
* DEVELOPER                         DATE                               DESCRIPTION
* ----------------------------------------------------------------------------   
*/
global class MonthlyTrackingNotificationBatch implements Database.Batchable<SObject>, Database.Stateful{
    
    global String sQuery;
    
    global MonthlyTrackingNotificationBatch(String sQuery) {        
        this.sQuery = sQuery;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(sQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        if (scope != null && scope.size() > 0) {
            List<ActivityTracking__c> lstActivities = (List<ActivityTracking__c>) scope;
            MonthlyTrackingNotificationBatchService.createNotificationForMonthlyTracking(lstActivities);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Any post batch processign on ResultSet
    }
}