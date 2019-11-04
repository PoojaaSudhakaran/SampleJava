/* *****************************************************************************************
* NAME         :  KYCC_CourseCreditInformationCtrl
* DESCRIPTION  :  This is the Apex controller for KYCC_CourseCreditInformation Lightning Component. 
					Aims to check the eligibility of the Citizen to register for a course.
* @AUTHOR      : Suyash Singhal
*/
public without sharing class KYCC_CourseCreditInformationCtrl {
    
    /*
    *Method Name: getCourse
    *Description: Method to fetch course Details by Passing the Course Id from the Component.
    *Author: Suyash Singhal
    */
    @AuraEnabled
    public static  Map<String, redwing__Training_Plan__c> getCourse(String courseId) {
        Map<String, redwing__Training_Plan__c> mapEligibilityCheckWithCourse = new Map<String, redwing__Training_Plan__c>();
        try {            
            String sEligible = checkEligibility() ? 'true' : 'false';
            if (courseId != null) {
                
                redwing__Training_Plan__c course = courseQuery(courseId) ;
                
                if (GlobalConstant.ELI_CHECK_COURSE_TYPE.contains(course.CourseType__c)) {
                    mapEligibilityCheckWithCourse.put(sEligible, course);
                } else {                    
                    // If only SNAP Individual, Eligibility check Logic needs to be added for other Course Types.In R2 we have only "My Rewards" Courses.
                    mapEligibilityCheckWithCourse.put('true', course);
                }
            }                        
        } catch (Exception e) {            
            mapEligibilityCheckWithCourse = null;   
            LOG_LogMessageUtility.logMessage(e, 'KYCC_CourseCreditInformationCtrl','getCourse', 'Eligibility Check Failed', true);
        }
        return mapEligibilityCheckWithCourse; 
    }
    
    
     /*
    *Method Name: checkEligibility
    *Description: Method to Check Eligibilty for the Citizen to Register for the Course.
    *Author: Suyash Singhal
    */
    public static Boolean checkEligibility(){
        Boolean isEligible = false;
        String conId = getIndividualId();
        
        if (conId != null && conId != '') {
            List<EnrolledPrograms__c> lstEnrollProgrms = [SELECT Id, BenefitProgram__c, Individual__c FROM EnrolledPrograms__c 
                                                          WHERE Individual__c = :conId 
                                                          AND BenefitProgram__c IN :GlobalConstant.ELIGIBLE_PROGRAMS_FOR_COURSES
                                                          AND Status__c NOT IN: GlobalConstant.INDIVIDUAL_ENROLL_PROGRAMS_NOT_ELI_STATUS];
            if (!lstEnrollProgrms.isEmpty()) { 
                isEligible = true;  
            }
        }
        return isEligible;
    }
  
   /*
    *Method Name: getvalidateMCO
    *Description: Method to Validate MCO Match for Individual's Plan and Course MCO.
    *Author: Suyash Singhal
    */ 
    @AuraEnabled
    public static String getvalidateMCO(String courseId){        
        String sMCOMatch = 'false';
        String conId = getIndividualId();
        if (courseId != null) {
        	redwing__Training_Plan__c course = courseQuery(courseId);        
            if (conId != null && conId != '') {                
                Contact objIndividual = [SELECT Id, Plan__c FROM Contact WHERE Id =:conId];
                if (course.MCO__c != null && objIndividual.Plan__c != null && objIndividual.Plan__c != course.MCO__c) {
                     sMCOMatch = 'false';
                } else {
                     sMCOMatch = 'true';
                }
            }
        }
        return sMCOMatch;        
    }
        
    
     /*
    *Method Name: courseQuery
    *Description: Method to Query Course.
    *Author: Suyash Singhal
    */ 
    public static redwing__Training_Plan__c courseQuery(Id courseId){
        
        redwing__Training_Plan__c course = [SELECT Id, MCO__c, CourseType__c, PotentialMyRewardsCredit__c FROM redwing__Training_Plan__c WHERE Id =:courseId];
        return course;
    }
     
    /*
    *Method Name: getIndividualId
    *Description: Method to get Current User's Individual Id.
    *Author: Suyash Singhal
    */ 
    public static string getIndividualId() {
        
        String conId = String.valueOf([SELECT  Id, ContactId FROM User 
                                       WHERE Id = :UserInfo.getUserId() 
                                       AND Profile.Name IN : GlobalConstant.CITIZEN_PROFILES 
                                       AND IsActive = TRUE].ContactId);
        
        return conId;
    }
    
    
    
    /*
    *Method Name: checkCourseType
    *Description: Method to check Course Type.
    *Author: Suyash Singhal
    */
    @AuraEnabled
    public static String checkCourseType(String courseId){        
        String sMyRewardsCourseType = 'false';  
         if (courseId != null) {
            redwing__Training_Plan__c course = courseQuery(courseId);             
             if (course.CourseType__c == GlobalConstant.MY_REWARDS) {
                    sMyRewardsCourseType =  'true';                 
             }
         }
        return sMyRewardsCourseType;
    }
    
}