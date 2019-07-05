/*****************************************************************************************
* @author       Bhanu Jangam   
* @date         02-July-2019
* @description  Helper class to process Assessment Rules trigger 
*
*    --------------------------------------------------------------------------
*    Developer                  Date                Description
*    --------------------------------------------------------------------------
* 
******************************************************************************************/

public class Adobe_Account_Assignment_Rules_Helper {
	public static Boolean is_Adobe_Account_Assignment_Rules_Helper = false;//THID FLAG PREVENT RECRESIVE UPDATE IN ACCOUNT AND ASSIGNMENT RULES OBJECT
	public static final Integer queryLimit = 50000;
    
	/******************************************************************************************
	* Method Name : performAccountATMEvaluation
	* Parameters  : Map<Id, Adobe_Account_Assignment_Rules__c> - Map of old AAAR record Id as key and old AAAR record as value
				    Map<Id, Adobe_Account_Assignment_Rules__c> - Map of new AAAR record Id as key and new AAAR record as value
	* Return Type : void
	* Description : This method is used to update Account records to update OwnerId, to create/update/delete ATM records respectively 
	******************************************************************************************/
    public static void performAccountATMEvaluation(Map<Id, Adobe_Account_Assignment_Rules__c> oldAAARMap,Map<Id, Adobe_Account_Assignment_Rules__c> newAAARMap){
		is_Adobe_Account_Assignment_Rules_Helper = true;
		
		//CHECK IF ACCOUNT TRIGGER NOT STARTED THE PROCESS
		if(Adobe_Account_Trigger_Handler.is_Adobe_Account_Trigger_Handler_Running == false){
			
			Set<String> oldZipCodeSet = new Set<String>();
			Set<String> oldUserIdSet = new Set<String>();
			Set<String> oldRoleSet = new Set<String>();
			Set<String> oldLevelSet = new Set<String>();
			Map<String,Id> zipUpdatedOwnerIdMap = new Map<String,Id>();
			
			Set<String> newZipCodeSet = new Set<String>();
			Map<String, List<Id>> zipAccIdListMap = new Map<String, List<Id>>();
			Boolean isIncludeAssignmentRecords = false;
			Boolean isIncludeOwner = false;
			
			List<Account> updatableAccs = null;
			AccountTeamMember atm = null;
			
			String zipCode = null;
			List<Adobe_Account_Assignment_Rules__c> tempAAARList = null;
			Map<String, List<Adobe_Account_Assignment_Rules__c>> zipUpdatedAAARListMap = new Map<String, List<Adobe_Account_Assignment_Rules__c>>();
			
			
			for(Id newaaarId : newAAARMap.keySet()){
				zipCode = newAAARMap.get(newaaarId).ZIP_Code__c;
				
				if(!newAAARMap.get(newaaarId).Access_Level__c.equals('Owner')){//Identify the old AccountTeam record to delete
					if(oldAAARMap != null){//On Update Activity only
						oldZipCodeSet.add(oldAAARMap.get(newaaarId).ZIP_Code__c);
						oldUserIdSet.add(oldAAARMap.get(newaaarId).Assigned_Rep__c);
						oldRoleSet.add(oldAAARMap.get(newaaarId).Role__c);
						oldLevelSet.add(oldAAARMap.get(newaaarId).Access_Level__c  == 'Read/Write' ? 'Edit' : oldAAARMap.get(newaaarId).Access_Level__c);
					}
					
					tempAAARList = zipUpdatedAAARListMap.containsKey(zipCode) ? zipUpdatedAAARListMap.get(zipCode) : new List<Adobe_Account_Assignment_Rules__c>{newAAARMap.get(newaaarId)};
					zipUpdatedAAARListMap.put(zipCode, tempAAARList);
					isIncludeAssignmentRecords = true;	
				} else {//Owner logic
					zipUpdatedOwnerIdMap.put(zipCode, newAAARMap.get(newaaarId).Assigned_Rep__c);
					isIncludeOwner = true;
				}
			}
			
			if(zipUpdatedOwnerIdMap.size() > 0){
				newZipCodeSet.addAll(zipUpdatedOwnerIdMap.keySet());
			}
			
			if(zipUpdatedAAARListMap.size() > 0){
				newZipCodeSet = zipUpdatedAAARListMap.keySet();
			}
			
			String dynaQuery = 'Select a.Id, a.BillingPostalCode From Account a Where a.BillingPostalCode IN:newZipCodeSet Limit:queryLimit';
			
			try{
				updatableAccs = Database.query(dynaQuery);
			}catch(QueryException qex){
				System.debug('###### Exception while Querying Accounts : ' + qex.getMessage());
			}
			
			List<AccountTeamMember> delAccTeamList = [Select Id, AccountId From AccountTeamMember WHERE UserId IN :oldUserIdSet AND TeamMemberRole IN: oldRoleSet AND AccountAccessLevel IN: oldLevelSet];
			
			List<AccountTeamMember> insertAccTeamList = new List<AccountTeamMember>();
			List<Account> newOwnerAccList = new List<Account>();
			
			List<Id> tempAccIdList = null;
			for(Account acc : updatableAccs){
				if(isIncludeAssignmentRecords == true){
					tempAccIdList = zipAccIdListMap.containsKey(acc.BillingPostalCode) ? zipAccIdListMap.get(acc.BillingPostalCode) : new List<Id>() ;
					tempAccIdList.add(acc.Id);
					
					zipAccIdListMap.put(acc.BillingPostalCode, tempAccIdList);
					
					if(zipUpdatedAAARListMap.containsKey(acc.BillingPostalCode)){
						for(Adobe_Account_Assignment_Rules__c aaar : zipUpdatedAAARListMap.get(acc.BillingPostalCode)){
							atm = new AccountTeamMember(AccountId = acc.Id, UserId = aaar.Assigned_Rep__c, TeamMemberRole = aaar.Role__c, AccountAccessLevel = aaar.Access_Level__c == 'Read/Write' ? 'Edit' : 'Read');
							insertAccTeamList.add(atm);
						}
					}
				}
				if(zipUpdatedOwnerIdMap.containsKey(acc.BillingPostalCode) && isIncludeOwner){
					acc.OwnerId = zipUpdatedOwnerIdMap.get(acc.BillingPostalCode);
					newOwnerAccList.add(acc);
				}
			}
			if(!delAccTeamList.isEmpty()) delete delAccTeamList;//TODO : Exception handling
			
			insert insertAccTeamList;//TODO : Exception handling
			
			if(newOwnerAccList.size() > 0){
				update newOwnerAccList;//TODO : Exception handling
			}
			/* Update OpportunityTeamMebers */
			Adobe_Util.processOTMRecords(zipAccIdListMap);
			
		}//if(Adobe_Account_Trigger_Handler.is_Adobe_Account_Trigger_Handler_Running == false) - end
    }
	 /******************************************************************************************
	* Method Name : performAccountATMDeletion
	* Parameters  : Map<Id, Adobe_Account_Assignment_Rules__c> - Map of old AAAR record Id as key and old AAAR record as value
				    Map<Id, Adobe_Account_Assignment_Rules__c> - Map of new AAAR record Id as key and new AAAR record as value
	* Return Type : void
	* Description : This method is used to update Account records to update OwnerId, to create/update/delete ATM records respectively 
	******************************************************************************************/
	public static void performAccountATMDeletion(Map<Id, Adobe_Account_Assignment_Rules__c> oldAAARMap){
		
		Set<String> oldZipCodeSet = new Set<String>();
		Set<String> oldUserIdSet = new Set<String>();
		Set<String> oldRoleSet = new Set<String>();
		Set<String> oldLevelSet = new Set<String>();
		
		Set<String> delATMZipCodeSet = new Set<String>();
		
		Set<String> newZipCodeSet = new Set<String>();
		
		String zipCode = null;
		List<Adobe_Account_Assignment_Rules__c> tempAAARList = null;
		Map<String, List<Adobe_Account_Assignment_Rules__c>> zipUpdatedAAARListMap = new Map<String, List<Adobe_Account_Assignment_Rules__c>>();
		
		Map<String,Id> zipUpdatedOwnerIdMap = new Map<String,Id>();
		
        for(Id oldaaarId : oldAAARMap.keySet()){
			zipCode = oldAAARMap.get(oldaaarId).ZIP_Code__c;
			delATMZipCodeSet.add(zipCode);
			if(oldAAARMap != null){//On Update Activity only
				oldZipCodeSet.add(oldAAARMap.get(oldaaarId).ZIP_Code__c);
				oldUserIdSet.add(oldAAARMap.get(oldaaarId).Assigned_Rep__c);
				oldRoleSet.add(oldAAARMap.get(oldaaarId).Role__c);
				oldLevelSet.add(oldAAARMap.get(oldaaarId).Access_Level__c  == 'Read/Write' ? 'Edit' : oldAAARMap.get(oldaaarId).Access_Level__c);
			}	
		}
		
		/*String dynaQuery = 'Select a.Id, a.BillingPostalCode From Account a Where a.BillingPostalCode IN:delATMZipCodeSet LIMIT:queryLimit';
		
		 List<Account> updatableAccs = null;
		try{
			updatableAccs = Database.query(dynaQuery);
		}catch(QueryException qex){
			System.debug('###### Exception while Querying Accounts : ' + qex.getMessage());
		}
		System.debug('**** updatableAccs = ' + updatableAccs); */
		
		List<AccountTeamMember> delAccTeamList = [Select Id, AccountId From AccountTeamMember WHERE UserId IN :oldUserIdSet AND TeamMemberRole IN: oldRoleSet AND AccountAccessLevel IN: oldLevelSet];
		/* AccountTeamMember atm = null;
		
		List<AccountTeamMember> insertAccTeamList = new List<AccountTeamMember>();
		List<Account> newOwnerAccList = new List<Account>();
		 */
		delete delAccTeamList;//TODO : Exception handling
	
		//TODO : Update OTM records also
    }
	
}