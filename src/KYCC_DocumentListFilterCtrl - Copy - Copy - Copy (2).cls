/*****************************************************************************************
* NAME         :  c:KYCC_DocumentListFilterCtrl
* DESCRIPTION  :  This class is to get picklist values for aura component
* @AUTHOR      :  Varun Singh
* @DATE 16/11/17
*/
public class KYCC_DocumentListFilterCtrl{
    
    @AuraEnabled
    public static Wrapper auraInit(){
        Wrapper results = new Wrapper();
        Schema.DescribeFieldResult fieldResult = Document__c.DocumentType__c.getDescribe();
        List<Schema.PicklistEntry> lstEntryDefinition = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry ple : lstEntryDefinition) {
            if (ple.isActive()) {
                PicklistEntryDefinition entryDefinition = new PicklistEntryDefinition(ple); 
                results.documentType.add(entryDefinition);
            }
        }
        return results;
    }
    public class Wrapper{
        @AuraEnabled
        public List<PicklistEntryDefinition> documentType;
        Wrapper(){
            documentType = new List<PicklistEntryDefinition>();
        }
    }
}