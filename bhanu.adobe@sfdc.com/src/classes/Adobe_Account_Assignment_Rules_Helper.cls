public class Adobe_Account_Assignment_Rules_Helper {
	public static Boolean is_Adobe_Account_Assignment_Rules_Helper = false;//THID FLAG PREVENT RECRESIVE UPDATE IN ACCOUNT AND ASSIGNMENT RULES OBJECT

    enum AccessLevel {
		
	}
    public static void performAccountATMEvaluation(Map<Id, Adobe_Account_Assignment_Rules__c> oldAAARMap,Map<Id, Adobe_Account_Assignment_Rules__c> newAAARMap){
		is_Adobe_Account_Assignment_Rules_Helper = true;
		
		//CHECK IF ACCOUNT TRIGGER NOT STARTED THE PROCESS
		if(Adobe_Account_Trigger_Handler.is_Adobe_Account_Trigger_Handler_Running == false){
			Map<String, String> accessMap = new Map<String, String>();
			accessMap.put('Read/Write', 'Edit');
			
			Set<String> oldZipCodeSet = new Set<String>();
			Set<String> oldUserIdSet = new Set<String>();
			Set<String> oldRoleSet = new Set<String>();
			Set<String> oldLevelSet = new Set<String>();
			
			Set<String> newZipCodeSet = new Set<String>();
			Boolean isIncludeAssignmentRecords = false;
			Boolean isIncludeOwner = false;
			
			String zipCode = null;
			List<Adobe_Account_Assignment_Rules__c> tempAAARList = null;
			Map<String, List<Adobe_Account_Assignment_Rules__c>> zipUpdatedAAARListMap = new Map<String, List<Adobe_Account_Assignment_Rules__c>>();
			
			Map<String,Id> zipUpdatedOwnerIdMap = new Map<String,Id>();
			
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
					System.debug('*** tempAAARList = ' + tempAAARList);
					zipUpdatedAAARListMap.put(zipCode, tempAAARList);
					System.debug('**** setting isIncludeAssignmentRecords = true');
					isIncludeAssignmentRecords = true;	
				} else {//Owner logic
					zipUpdatedOwnerIdMap.put(zipCode, newAAARMap.get(newaaarId).Assigned_Rep__c);
					System.debug('**** setting isIncludeOwner = true');
					isIncludeOwner = true;
				}
			}
			
			System.debug('*** isIncludeAssignmentRecords = ' + isIncludeAssignmentRecords);
			System.debug('*** isIncludeOwner = ' + isIncludeOwner);
			System.debug('*** zipUpdatedOwnerIdMap = ' + zipUpdatedOwnerIdMap);
			System.debug('*** zipUpdatedAAARListMap = ' + zipUpdatedAAARListMap);
			
			System.debug('*** oldZipCodeSet = ' + oldZipCodeSet);
			System.debug('*** oldUserIdSet = ' + oldUserIdSet);
			System.debug('*** oldRoleSet = ' + oldRoleSet);
			System.debug('*** oldLevelSet = ' + oldLevelSet);
			
			
			if(zipUpdatedOwnerIdMap.size() > 0){
				
				//for(String newAccOwnerId : zipUpdatedOwnerIdMap.keySet()){
					newZipCodeSet.addAll(zipUpdatedOwnerIdMap.keySet());
				//}
			}
			
			if(zipUpdatedAAARListMap.size() > 0){
				newZipCodeSet = zipUpdatedAAARListMap.keySet();
			}
			System.debug('*** newZipCodeSet = ' + newZipCodeSet);
			String ownerFilter = '';
			
			
			String dynaQuery = 'Select a.Id, a.BillingPostalCode, (Select Id, AccountId From AccountTeamMembers WHERE UserId IN :oldUserIdSet AND ' +
			'TeamMemberRole IN: oldRoleSet AND AccountAccessLevel IN: oldLevelSet) team From Account a Where a.BillingPostalCode IN:newZipCodeSet';
			
			List<Account> updatableAccs = null;
			try{
				updatableAccs = Database.query(dynaQuery);
			}catch(QueryException qex){
				System.debug('###### Exception while Querying Accounts : ' + qex.getMessage());
			}
			System.debug('**** updatableAccs = ' + updatableAccs);
			
			List<AccountTeamMember> delAccTeamList = new List<AccountTeamMember>();
			AccountTeamMember atm = null;
			
			List<AccountTeamMember> insertAccTeamList = new List<AccountTeamMember>();
			List<Account> newOwnerAccList = new List<Account>();
			
			//Set<String> processZipCodeSet = new Set<String>();
			List<Id> tempAccIdList = null;
			Map<String, List<Id>> zipAccIdListMap = new Map<String, List<Id>>();
			//for(Account acc : updatableAccs){
			for(Account acc : updatableAccs){
				//processZipCodeSet.add(acc.BillingPostalCode);
				if(isIncludeAssignmentRecords == true){
					tempAccIdList = zipAccIdListMap.containsKey(acc.BillingPostalCode) ? zipAccIdListMap.get(acc.BillingPostalCode) : new List<Id>() ;
					tempAccIdList.add(acc.Id);
					
					zipAccIdListMap.put(acc.BillingPostalCode, tempAccIdList);
					
					if(acc.AccountTeamMembers.size() > 0){
						for(AccountTeamMember delatm : acc.AccountTeamMembers){
							delAccTeamList.add(delatm);
						}
					}
					System.debug('*** acc.BillingPostalCode = ' + acc.BillingPostalCode);
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
			System.debug('**** delAccTeamList = ' + delAccTeamList);
			if(!delAccTeamList.isEmpty()) delete delAccTeamList;
			
			System.debug('**** insertAccTeamList = ' + insertAccTeamList);
			insert insertAccTeamList;
			
			
			//System.debug('**** atmIdATMMap = ' + atmIdATMMap);
			System.debug('**** newOwnerAccList = ' + newOwnerAccList);
			if(newOwnerAccList.size() > 0){
				update newOwnerAccList;
			}
			/* Update OpportunityTeamMebers */
			Adobe_Util.processOTMRecords(zipAccIdListMap);
			
		}//if(Adobe_Account_Trigger_Handler.is_Adobe_Account_Trigger_Handler_Running == false) - end
    }
	
	public static void performAccountATMDeletion(Map<Id, Adobe_Account_Assignment_Rules__c> oldAAARMap,Map<Id, Adobe_Account_Assignment_Rules__c> newAAARMap){
		Map<String, String> accessMap = new Map<String, String>();
		accessMap.put('Read/Write', 'Edit');
		
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
		
		System.debug('*** oldZipCodeSet = ' + oldZipCodeSet);
		System.debug('*** oldUserIdSet = ' + oldUserIdSet);
		System.debug('*** oldRoleSet = ' + oldRoleSet);
		System.debug('*** oldLevelSet = ' + oldLevelSet);
		
		String dynaQuery = 'Select a.Id, a.BillingPostalCode, (Select Id, AccountId From AccountTeamMembers WHERE UserId IN :oldUserIdSet AND ' +
		'TeamMemberRole IN: oldRoleSet AND AccountAccessLevel IN: oldLevelSet) team From Account a Where a.BillingPostalCode IN:delATMZipCodeSet';
		
		List<Account> updatableAccs = null;
		try{
			updatableAccs = Database.query(dynaQuery);
		}catch(QueryException qex){
			System.debug('###### Exception while Querying Accounts : ' + qex.getMessage());
		}
		System.debug('**** updatableAccs = ' + updatableAccs);
		
		List<AccountTeamMember> delAccTeamList = new List<AccountTeamMember>();
		AccountTeamMember atm = null;
		
		List<AccountTeamMember> insertAccTeamList = new List<AccountTeamMember>();
		List<Account> newOwnerAccList = new List<Account>();
		
		//for(Account acc : updatableAccs){
		for(Account acc : updatableAccs){
			if(acc.AccountTeamMembers.size() > 0){
				for(AccountTeamMember delatm : acc.AccountTeamMembers){
					delAccTeamList.add(delatm);
				}
			}
			System.debug('*** acc.BillingPostalCode = ' + acc.BillingPostalCode);
			
		}
		System.debug('**** delAccTeamList = ' + delAccTeamList);
		delete delAccTeamList;
		
    }
        
}