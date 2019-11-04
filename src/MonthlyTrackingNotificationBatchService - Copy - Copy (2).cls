public with sharing class MonthlyTrackingNotificationBatchService {
    
     /**
    * @author: Varun Singh
    * @method: createNotificationForMonthlyTracking
    * @desc  This method does the following:
    * 		1. iterates over the passed list of ActivityTracking__c and creates notifications 
    * @param activities  
    * @return void
    * */
    public static void createNotificationForMonthlyTracking(List<ActivityTracking__c> lstOfactivitie) {          
        Map<String, ActivityTracking__c> activityIndividualMap = new Map<String, ActivityTracking__c>();
        Map<String, Decimal> individualHrsMap = new Map<String, Decimal>();
        List<NotificationRequest__c> lstNotifications = new List<NotificationRequest__c>();
        Map<String, List<EnrolledPrograms__c>> IndToPrograms;
        
        for (ActivityTracking__c activity : lstOfactivitie) {            
            if (activityIndividualMap.containsKey(activity.Individual__c)) {
                Decimal dhours = activityIndividualMap.get(activity.Individual__c).TotalHours__c;
                Decimal individualHrs =  individualHrsMap.get(activity.Individual__c);
                individualHrs += dhours;
            } else {
                activityIndividualMap.put(activity.Individual__c, activity);
                individualHrsMap.put(activity.Individual__c,activity.TotalHours__c);
            }
        }
        //fetching the nudge data
        String[] sNudges = new String[]{'N000004','N000005','N000006'};
        Map<String, NotificationSetting__mdt> nudgeDataMap = new Map<String, NotificationSetting__mdt>();
        try {
            
            List<NotificationSetting__mdt> nudgeDataList = new List<NotificationSetting__mdt>([SELECT DeveloperName, ArchivalDays__c, DisplayEnglish__c, DisplaySpanish__c, ExpiryCalculation__c, Id, Label, 
                                                                                               Language, MasterLabel, NamespacePrefix, NudgeName__c, QualifiedApiName, Severity__c, TargetScreen__c
                                                                                               FROM NotificationSetting__mdt WHERE DeveloperName IN :sNudges]);
            
            for (NotificationSetting__mdt mdtNotification : nudgeDataList) {
                nudgeDataMap.put(mdtNotification.DeveloperName, mdtNotification);			
            }
            
        } catch (Exception e) {
            LOG_LogMessageUtility.logMessage(e, 'MonthlyTrackingNotificationBatchService','createNotificationForMonthlyTracking','Cannot fetch NotificationSetting for : ' + sNudges + '. Passed from process builder.',true);
        }
        
        // calculate total Hours for individuals 
        IndToPrograms = EnrolledProgramsAccessor.getEnrolledPrograms(individualHrsMap.keySet(), GlobalConstant.SNAP_PROGRAM); // get individual with there dispositions
        
        for (String individual : individualHrsMap.keySet()) {
            Decimal dTotalHours;
            if (IndToPrograms != null && IndToPrograms.containsKey(individual)) {
                EnrolledPrograms__c progToConsider = EnrolledProgramsAccessor.getDispositionToConsider(activityIndividualMap.get(individual).StartDate__c,IndToPrograms.get(individual));
                if (progToConsider != null) {
                    dTotalHours = progToConsider.MonthlyGoalHours__c;
                } else{
                    dTotalHours = GlobalConstant.DEFAULT_HOURS;
                }
            } else {
                dTotalHours = GlobalConstant.DEFAULT_HOURS;
            }
            if (individualHrsMap.get(individual) < dTotalHours) {
                String sInput;
                List<String> lstInput = new List<string>();
                Date dtStartDate = activityIndividualMap.get(individual).StartDate__c;
                String sMonth = Datetime.newInstance(dtStartDate.year(), dtStartDate.month(),dtStartDate.day()).format('MMMMM');
                Date dtToday = SystemUtil.today();
                if (dtToday.day() == 1) {
                    sInput = 'N000004;' + individual + ';' + dtToday.addDays(6).format() + ';' + sMonth + ';' + dTotalHours + ';';
                } else if (dtToday.day() == 3) {
                    sInput = 'N000005;' + individual + ';' + dtToday.addDays(4).format() + ';' + sMonth + ';' + dTotalHours + ';';
                } else if (dtToday.day() == 19) {
                    sInput = 'N000006;' + individual + ';' + sMonth + ';' + dTotalHours + ';';
                }
                
                if (sInput != null && String.isNotEmpty(sInput)){                    
                    lstNotifications.add(buildNotificationRequest(sInput, nudgeDataMap.get(sInput.split(';')[0])));
                }
            }
        }
        if (lstNotifications != null && !lstNotifications.isEmpty()) {
            try {                       
                List<Database.SaveResult> lstSaveResults = Database.insert(lstNotifications, false);
                if (lstSaveResults != null && !lstSaveResults.isEmpty()) {
                    for (Database.SaveResult saveResult : lstSaveResults) {
                        LOG_LogMessageUtility.logMessage(LOG_LogMessageUtility.LOG_LogLevel.Error, 'MonthlyTrackingNotificationBatchService', 'createNotificationForMonthlyTracking', 'notification batch failes on record : '+saveResult.getId()+'error message: '+saveResult.getErrors(), true) ;
                    }
                }
                
            } catch (Exception e) {
                LOG_LogMessageUtility.logMessage(e, 'MonthlyTrackingNotificationBatchService', 'createNotificationForMonthlyTracking', 'Cannot insert Notification Request ', true);                    
            }                        
        }
    }
    
    /**
    * @author: Varun Singh
    * @method: buildNotificationRequest
    * @desc  This method does the following:
    * 		1. This method builds notification request object for the passed nudge value  
    * @param sInput  
    * @param mdtNotification
    * @return void
    * */
    public static NotificationRequest__c buildNotificationRequest(String sInput, NotificationSetting__mdt mdtNotification) {    	
        NotificationRequest__c objNotificationRequest = new NotificationRequest__c();
        List<String> lstParameters = sInput.split(';');        
        //Check if the passed parameters are not empty 
        if (lstParameters != null && lstParameters.size() >= 2) {            
            String sNudgeCode = lstParameters[0];
            String sIndividualId = lstParameters[1];
            
            if (mdtNotification != null) {                                
                objNotificationRequest.NudgeCode__c = mdtNotification.DeveloperName;
                objNotificationRequest.RecordTypeId = GeneralUtility.fetchRecordType('Notification', 'NotificationRequest__c').Id;
                objNotificationRequest.Individual__c = sIndividualId;
                objNotificationRequest.Title__c = mdtNotification.NudgeName__c;
                objNotificationRequest.ArchivalType__c = mdtNotification.ExpiryCalculation__c;                
                objNotificationRequest.Severity__c = mdtNotification.Severity__c;                
                objNotificationRequest.DisplayDays__c = mdtNotification.ArchivalDays__c;
                objNotificationRequest.Status__c = 'Active';
                
                //If the expiration calculation is 'Creation' then the start date will be stamped to current day
                if (mdtNotification.ExpiryCalculation__c == 'Creation') {                    
                    objNotificationRequest.StartDate__c = SystemUtil.today();
                    objNotificationRequest.EndDate__c = SystemUtil.today() + (Integer) objNotificationRequest.DisplayDays__c;
                }
                
                String sEnglishText = mdtNotification.DisplayEnglish__c;
                String sSpanishText = mdtNotification.DisplaySpanish__c;
                //Populate the merge fields on the message
                if (lstParameters.size() > 2) {
                    for (Integer i = 2; i < lstParameters.size(); i++) {
                        sEnglishText = sEnglishText.replace('{'+ (i - 2) +'}', lstParameters[i]);//For English Language
                        sSpanishText = sSpanishText.replace('{'+ (i - 2) +'}', lstParameters[i]);//For Spanish Language
                    }
                }
                
                objNotificationRequest.MessageEn__c = sEnglishText;
                objNotificationRequest.MessageEs__c = sSpanishText;                
                objNotificationRequest.IsRead__c = false;                               
            } else {     
                LOG_LogMessageUtility.logMessage(LOG_LogMessageUtility.LOG_LogLevel.Debug,'MonthlyTrackingNotificationBatchService', 'buildNotificationRequest','Cannot find Notification Settings for the inputs: ' + sInput, true);
            }
        } else {
            LOG_LogMessageUtility.logMessage(LOG_LogMessageUtility.LOG_LogLevel.Error,'MonthlyTrackingNotificationBatchService', 'buildNotificationRequest','All Params are not passed from process builder. '+ lstParameters, true);            
        }
        return objNotificationRequest;
    }
    
}