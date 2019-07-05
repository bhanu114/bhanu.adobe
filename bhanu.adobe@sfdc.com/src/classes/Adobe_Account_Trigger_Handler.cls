/*****************************************************************************************
* @author       Bhanu Jangam   
* @date         02-July-2019
* @description  Helper class to process Account Trigger operations
*
*    --------------------------------------------------------------------------
*    Developer                  Date                Description
*    --------------------------------------------------------------------------
* 
******************************************************************************************/
public class Adobe_Account_Trigger_Handler {
    public static Boolean is_Adobe_Account_Trigger_Handler_Running = false;//THID FLAG PREVENT RECRESIVE UPDATE IN ACCOUNT AND ASSIGNMENT RULES OBJECT
    public static final Integer queryLimit = 50000;
	
	/******************************************************************************************
	* Method Name : reEvaluateSharing
	* Parameters  : Map<Id,Account> - Old map of Accounts from Trigger
				    Map<Id,Account> - new map of Accounts from Trigger
	* Return Type : void
	* Description : This method used to find the changes of Account Owner OR BillingPostalCode changes and insert/Update/delete ATM and OTM records related to Account
	******************************************************************************************/
    public static void reEvaluateSharing(Map<Id,Account> oldAccMap,Map<Id,Account> newAccMap){
        is_Adobe_Account_Trigger_Handler_Running = true;//Used to aboid recressive process of trigger execution
        
        //CHECK IF ASSIGNMENT RULE TRIGGER NOT STARTED THE PROCESS
        if(Adobe_Account_Assignment_Rules_Helper.is_Adobe_Account_Assignment_Rules_Helper == false){//Used to aboid recressive process of trigger execution
            /* Map<String,String> oldZipCodeNewZipCodeMap = new Map<String, String>(); */
			//Precess variables
            Map<String, Id> newAccountZipCodeIdMap = new Map<String, Id>();//Used to Identify for which Account related ATM's should be deleted
            Map<String, Id> zipCodeNewOwnerIdMap = new Map<String, Id>();//Used to update Sales Rep in Assignmet Rule record on Account Owner change
            Map<String, Id> zipCodeOldOwnerIdMap = new Map<String, Id>();//Used to Identify Sales Rep in Assignmet Rule record for Account Owner change
            Map<String, List<Account>> newAccZipCodeAccListMap = new Map<String, List<Account>>();
			Map<String, List<Id>> zipAccIdListMap = new Map<String, List<Id>>();//To re-evaluate OTM records
            
			//Helper variables
			String zipCode = null;//Used to check/assign Account.BillingPostalCode in for loop to speed up the process
            Boolean isIncludeAssignmentRecords = false;//Used to identify and avoid unwanted process execution
			Boolean isIncludeOwner = false;//Used to identify and avoid unwanted process execution
            List<Account> tempAccList = null;//Used to 
            List<Id> tempAccIdList = null;
			
            
            /* Set<Id> ownerChangeAccIdSet = new Set<Id>(); */
			
			/* PREPARE DATA STRUCTURE TO PERFORM INSERT UPDATE AND DELETE OPERATIONS BASED ON ACCOUNT RECORD UPDATE */
            for(Id newAccId : newAccMap.keySet()){
                zipCode = newAccMap.get(newAccId).BillingPostalCode;
                if(oldAccMap != null){//on Update
                  
					tempAccIdList = zipAccIdListMap.containsKey(zipCode) ? zipAccIdListMap.get(zipCode) : new List<Id>() ;
					tempAccIdList.add(newAccId);
					zipAccIdListMap.put(zipCode, tempAccIdList);
                    
					if(oldAccMap.get(newAccId).BillingPostalCode != newAccMap.get(newAccId).BillingPostalCode){
						isIncludeAssignmentRecords = true;
					      //oldZipCodeNewZipCodeMap.put(oldAccMap.get(newAccId).BillingPostalCode, newAccMap.get(newAccId).BillingPostalCode);
                        newAccountZipCodeIdMap.put(newAccMap.get(newAccId).BillingPostalCode, newAccId);
                        
                        //BULKIFY IF MULTIPLE ACCOUNTS HAS SAME ZIP CODE
                        tempAccList = newAccZipCodeAccListMap.containsKey(zipCode) ? newAccZipCodeAccListMap.get(zipCode) : new List<Account>{newAccMap.get(newAccId)};
						newAccZipCodeAccListMap.put(newAccMap.get(newAccId).BillingPostalCode, tempAccList);
                    }
                    if(oldAccMap.get(newAccId).OwnerId != newAccMap.get(newAccId).OwnerId){
                        isIncludeOwner = true;
                        zipCodeNewOwnerIdMap.put(zipCode, newAccMap.get(newAccId).OwnerId);
                        zipCodeOldOwnerIdMap.put(zipCode, oldAccMap.get(newAccId).OwnerId);
                        /* ownerChangeAccIdSet.add(newAccId); */
                    }
                } else {//On Account Create
                    //newAccountZipCodeIdMap.put(newAccMap.get(newAccId).BillingPostalCode, newAccId);
                    if(!String.isBlank(zipCode)){
						tempAccIdList = zipAccIdListMap.containsKey(zipCode) ? zipAccIdListMap.get(zipCode) : new List<Id>() ;
						tempAccIdList.add(newAccId);
						zipAccIdListMap.put(zipCode, tempAccIdList);
				
                        //zipCode = newAccMap.get(newAccId).BillingPostalCode;
                        //BULKIFY IF MULTIPLE ACCOUNTS HAS SAME ZIP CODE
                        tempAccList = newAccZipCodeAccListMap.containsKey(zipCode) ? newAccZipCodeAccListMap.get(zipCode) : new List<Account>();
                        tempAccList.add(newAccMap.get(newAccId));
                        newAccZipCodeAccListMap.put(newAccMap.get(newAccId).BillingPostalCode, tempAccList);
                        newAccountZipCodeIdMap.put(newAccMap.get(newAccId).BillingPostalCode, newAccId);
                    }
                }
            }
            
			/* BUSINESS LOGIC TO EXECUTE ON ACCOUNT ZIP-CODE UPDATE/CREATE */
            if(newAccZipCodeAccListMap.size() > 0 /* || ownerChangeAccIdSet.size() > 0 */){//DO BELOW OPERATIONS ONLY IF RECORDS FOUND TO INSERT/UPDATE
			    //Delete Account ATM records for old Zip Code - START
                if(newAccountZipCodeIdMap.size() > 0 && isIncludeAssignmentRecords == true){
                    List<AccountTeamMember> delATMList = [Select Id, AccountId From AccountTeamMember where AccountId IN: newAccountZipCodeIdMap.values() LIMIT:queryLimit];
                    delete delATMList;//TODO : Exception handling
			    }
                //Delete Account ATM records for old Zip Code - END
                
				//Create ATM records for new Zip Code - START
				Map<Id,Id> accIdNewOwnerIdMap = createATMRecordsOnZipChange(newAccZipCodeAccListMap);
				//Create ATM records for new Zip Code - START
			
				//UPDATE ACCOUNTS WITH NEW OWNER
                if(accIdNewOwnerIdMap.size() > 0) Adobe_Util.updateAccountsOwner(accIdNewOwnerIdMap);
            }
            
            /* BUSINESS LOGIC TO UPDATE ASSIGNMENT RULES RECORDS OWNER VALUE ON ACCOUNT OWNER CHANGE EVENT */
            if(zipCodeOldOwnerIdMap.size() > 0){
				updateAAARRecords(zipCodeOldOwnerIdMap, /* ownerChangeAccIdSet, */ zipCodeNewOwnerIdMap); 
            }
			
			/* Update OpportunityTeamMebers */
			Adobe_Util.processOTMRecords(zipAccIdListMap);
			
			/* On Owner change re-create ATM records from Assignment Rules related records */
			if(isIncludeOwner == true){//After Account Owner change, Salesforce by default removes the ATM records associated with that Account so, recreate respetive ATMs
				Adobe_Util.reCreateATMsByZipCodes(zipCodeNewOwnerIdMap.keySet());
			}
        }
    }
    
    /******************************************************************************************
	* Method Name : createATMRecordsOnZipChange
	* Parameters  : Map<String, List<Account>> - Map of new Account Zip-Code as Key and respective Account List as value
	* Return Type : Map<Id,Id> Map of each account ID and respective new Account Owner ID
	* Description : This method will create new ATM records for ZipCode changed Accounts
	******************************************************************************************/
    public static Map<Id,Id> createATMRecordsOnZipChange(Map<String, List<Account>> newAccZipCodeAccListMap){
		Map<Id,Id> accIdNewOwnerIdMap = new Map<Id,Id>();
        
        if(newAccZipCodeAccListMap.size() > 0){
            List<Adobe_Account_Assignment_Rules__c> aaarList = null;
            String zipCode = null;
            
            //RE-CREATE NEW ATM RECORDS ACCORDING TO NEW ZIP-CODE
            aaarList = [Select Id, ZIP_Code__c, Assigned_Rep__c, Role__c, Access_Level__c FROM Adobe_Account_Assignment_Rules__c where ZIP_Code__c IN:newAccZipCodeAccListMap.keySet() LIMIT:queryLimit];
            
			Map<String, List<Adobe_Account_Assignment_Rules__c>> zipCodeAAARListMap = Adobe_GenericOperationsHelper.getFieldValueKeyListOfObjectsFromList(aaarList,'ZIP_Code__c');
            List<AccountTeamMember> insertAccTeamList = new List<AccountTeamMember>();
			AccountTeamMember atm = null;
            
            /* Itirate thorugh each ZipCode and assign Assignment Rules to each Account assigned with respective ZipCode */
            for(String newZipCode : newAccZipCodeAccListMap.keySet()){
                if(zipCodeAAARListMap.containsKey(newZipCode)){
                    for(Account eachAcc : newAccZipCodeAccListMap.get(newZipCode)){
                        for(Adobe_Account_Assignment_Rules__c aaar : zipCodeAAARListMap.get(newZipCode)){
                            if(!aaar.Access_Level__c.equals('Owner')){//Identify the Owner record to update Account
                                atm = new AccountTeamMember(AccountId = eachAcc.Id, UserId = aaar.Assigned_Rep__c, TeamMemberRole = aaar.Role__c, AccountAccessLevel = aaar.Access_Level__c == 'Read/Write' ? 'Edit' : 'Read');
                                insertAccTeamList.add(atm);
                            } else {//COLLECT ACCOUNTS TO UPDATE OWNER
                                accIdNewOwnerIdMap.put(eachAcc.Id, aaar.Assigned_Rep__c);
                            }
                        }
                    }
                }
            }
            Database.SaveResult[] srList = Database.insert(insertAccTeamList, false);
            
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Fields that affected this error: ' + err.getFields());
                    }
                }
            }			
        }
		return accIdNewOwnerIdMap;
    }
	
	
    /******************************************************************************************
	* Method Name : updateAAARRecords
	* Parameters  : Map<String, Id> - Map of ZipCode as key and new Account old OwnerId as value
	*			    Map<String, Id> - Map of ZipCode as key and new Account new OwnerId as value
	* Return Type : void
	* Description : This method used to update AAAR record Sale Rep reference as Account new OwnerId on event of Account Owner Change
	******************************************************************************************/
	public static void updateAAARRecords(Map<String, Id> zipCodeOldOwnerIdMap, Map<String, Id> zipCodeNewOwnerIdMap){
		if(zipCodeOldOwnerIdMap.size() > 0){
			List<Adobe_Account_Assignment_Rules__c> updatableAAARList = new List<Adobe_Account_Assignment_Rules__c>();
			updatableAAARList = [Select Id, Assigned_Rep__c,ZIP_Code__c  From Adobe_Account_Assignment_Rules__c where ZIP_Code__c IN:zipCodeOldOwnerIdMap.keySet() AND Assigned_Rep__c IN:zipCodeOldOwnerIdMap.values() AND Access_Level__c ='Owner' LIMIT:queryLimit];
		   
			//UPDATE AAAR OWNER RECORD WITH NEW SALESE REP
			for(Adobe_Account_Assignment_Rules__c aaar  : updatableAAARList){
				aaar.Assigned_Rep__c = zipCodeNewOwnerIdMap.get(aaar.ZIP_Code__c);
			}
			update updatableAAARList;//TODO : Exception handling
		}
	}
}