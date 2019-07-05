/*****************************************************************************************
* @author       Bhanu Jangam   
* @date         02-July-2019
* @description  This Utility class with have methods that repeatedly used in diferent classes
*
*    --------------------------------------------------------------------------
*    Developer                  Date                Description
*    --------------------------------------------------------------------------
* 
******************************************************************************************/
public class Adobe_Util {
    public static final Integer queryLimit = 50000;
    
    /******************************************************************************************
    * Method Name : updateAccountsOwner
    * Parameters  : Map<Id,Id> - Map of Account Id and respective new ownerId
    * Return Type : void
    * Description : This method queries Accounts and updates the new Account Owner
    ******************************************************************************************/
     @future
    public static void updateAccountsOwner(Map<Id,Id> accIdNewOwnerIdMap){
        //QUERY ACCOUNTS TO UPDATE OWNER
        List<Account> accsToUpdateOwnerList = [Select Id, OwnerId From Account where Id IN:accIdNewOwnerIdMap.keySet() LIMIT:queryLimit];
        for(Account acc : accsToUpdateOwnerList){
            acc.OwnerId = accIdNewOwnerIdMap.get(acc.Id);
        }
        update accsToUpdateOwnerList;//TODO : Exception handling
    }
    /******************************************************************************************
    * Method Name : processOTMRecords
    * Parameters  : Map<String, List<Id>> - Map of ZipCode and respective Account IDs List
    * Return Type : void
    * Description : This method deletes OTM records and creates new OTM record on various events occured in AAAR object and Account
    ******************************************************************************************/
    //@future
    public static void processOTMRecords(Map<String, List<Id>> zipAccIdListMap){
        
        if(!zipAccIdListMap.isEmpty()){
            //QUERY ALL OPPORTUNITIES RELATED TO SELECTED ACCOUNTS
            Map<String, Set<Id>> zipCodeOpptyIdSet = new Map<String, Set<Id>>();
            List<Opportunity> opptyList = [Select Id, AccountId from Opportunity where AccountId IN (Select Id From Account where BillingPostalCode IN:zipAccIdListMap.keySet()) AND StageName NOT IN( 'Closed Won', 'Closed Lost') LIMIT:queryLimit];
            //PREPARE ACCOUNT ID AND OPPORTUNITY ID LIST MAP
            Map<Id, Set<Id>> accIdOppIdSetMap = new Map<Id, Set<Id>>();
            Set<Id> oppIdSet = null;
             for(Opportunity oppty : opptyList){
                oppIdSet = accIdOppIdSetMap.containsKey(oppty.AccountId) ? accIdOppIdSetMap.get(oppty.AccountId) : new Set<Id>();
                oppIdSet.add(oppty.Id);
                accIdOppIdSetMap.put(oppty.AccountId, oppIdSet);
            } 
            //Delete all OTP recods related to zipcode related Accounts
            List<OpportunityTeamMember> deleteOTMList = [Select Id From OpportunityTeamMember where OpportunityId IN :opptyList LIMIT:queryLimit];
            delete deleteOTMList;//TODO : Exception handling
            
            //Query all AAAR records to create new OTP records
            List<Adobe_Account_Assignment_Rules__c> aaarList = [Select Id,ZIP_Code__c,Assigned_Rep__c,Role__c,Access_Level__c  from Adobe_Account_Assignment_Rules__c where ZIP_Code__c IN: zipAccIdListMap.keySet() LIMIT:queryLimit];
            Map<String, List<Adobe_Account_Assignment_Rules__c>> zipAAARListMap = Adobe_GenericOperationsHelper.getFieldValueKeyListOfObjectsFromList(aaarList,'ZIP_Code__c');
            List<OpportunityTeamMember> insertOTMList = new List<OpportunityTeamMember>();
            OpportunityTeamMember otm = null;
            for(String zc : zipAccIdListMap.keySet()){//Iterate for each zip-code
            if(zipAccIdListMap.containsKey(zc))
                for(Id accId : zipAccIdListMap.get(zc)){//Iterate for each Account
                if(accIdOppIdSetMap.containsKey(accId))
                    for(Id oppId : accIdOppIdSetMap.get(accId)){
                        if(zipAAARListMap.containsKey(zc))
                        for(Adobe_Account_Assignment_Rules__c aaar : zipAAARListMap.get(zc)){
                            //CREATE OTM ONLY FOR READ/WRITE AND READ PERMISSION RECORDS AND SKIP OWNER RECORDS
                            if(!aaar.Access_Level__c.equals('Owner')){
                                otm = new OpportunityTeamMember(OpportunityId = oppId, UserId = aaar.Assigned_Rep__c, TeamMemberRole = aaar.Role__c, OpportunityAccessLevel = aaar.Access_Level__c  == 'Read/Write' ? 'Edit' : 'Read' );
                                insertOTMList.add(otm);
                            }
                        }
                    }
                }
            }
            
            if(!insertOTMList.isEmpty()){
                insert insertOTMList;//TODO : Exception handling
            }
        }
        
    }
    /******************************************************************************************
    * Method Name : reCreateATMsByZipCodes
    * Parameters  : Set<String> - Map of ZipCode and respective Account IDs List
    * Return Type : void
    * Description : This method takes Set of ZipCodes and queries on respective Accounts and AAAR records and creates ATM records to each Accounts as per AAAR records count
    ******************************************************************************************/
    public static void reCreateATMsByZipCodes(Set<String> zipCodeSet){
        
        List<Adobe_Account_Assignment_Rules__c> aaarList =  [Select Id, ZIP_Code__c,Assigned_Rep__c,Role__c,Access_Level__c   From Adobe_Account_Assignment_Rules__c where ZIP_Code__c IN:zipCodeSet AND Access_Level__c !='Owner' LIMIT:queryLimit];
        //PREPARE MAP OF ZIPCODE AND List of related Adobe_Account_Assignment_Rules__c records
        
        Map<String,List<Adobe_Account_Assignment_Rules__c>> zipCodeAAARListMap =  Adobe_GenericOperationsHelper.getFieldValueKeyListOfObjectsFromList(aaarList,'ZIP_Code__c');
        
        //Fetch Account records by ZipCode
        List<Account> accList = [Select Id,BillingPostalCode  from Account where BillingPostalCode IN:zipCodeSet Limit: queryLimit ];
        //PREPARE MAP OF ZIPCODE AND List of related Adobe_Account_Assignment_Rules__c records
        
        Map<String,List<Account>> zipCodeAccListMap = Adobe_GenericOperationsHelper.getFieldValueKeyListOfObjectsFromList(accList,'BillingPostalCode');
        
        List<AccountTeamMember> insertAccTeamList = new List<AccountTeamMember>();
         AccountTeamMember atm = null;
        /* Itirate thorugh each ZipCode and assign Assignment Rules to each Account assigned with respective ZipCode */
        for(String zipCode : zipCodeSet){
            if(zipCodeAAARListMap.containsKey(zipCode)){
                for(Account eachAcc : zipCodeAccListMap.get(zipCode)){
                    for(Adobe_Account_Assignment_Rules__c aaar : zipCodeAAARListMap.get(zipCode)){
                            atm = new AccountTeamMember(AccountId = eachAcc.Id, UserId = aaar.Assigned_Rep__c, TeamMemberRole = aaar.Role__c, AccountAccessLevel = aaar.Access_Level__c == 'Read/Write' ? 'Edit' : 'Read');
                            insertAccTeamList.add(atm);
                        
                    }
                }
            }
        }
        insert insertAccTeamList;//TODO : Exception handling
    }
}