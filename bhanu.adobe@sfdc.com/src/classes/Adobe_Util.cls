public class Adobe_Util {
	
	 @future
    public static void updateAccountsOwner(Map<Id,Id> accIdNewOwnerIdMap){
        System.debug('**** updateAccountsOwner, accIdNewOwnerIdMap = ' + accIdNewOwnerIdMap);
        //QUERY ACCOUNTS TO UPDATE OWNER
        List<Account> accsToUpdateOwnerList = [Select Id, OwnerId From Account where Id IN:accIdNewOwnerIdMap.keySet() Limit 50000];
        for(Account acc : accsToUpdateOwnerList){
            acc.OwnerId = accIdNewOwnerIdMap.get(acc.Id);
        }
        System.debug('**** updateAccountsOwner, updating accounts = ' );
        update accsToUpdateOwnerList;
    }
	
	//@future
	public static void processOTMRecords(Map<String, List<Id>> zipAccIdListMap){
		
		if(!zipAccIdListMap.isEmpty()){
			//QUERY ALL OPPORTUNITIES RELATED TO SELECTED ACCOUNTS
			Map<String, Set<Id>> zipCodeOpptyIdSet = new Map<String, Set<Id>>();
			List<Opportunity> opptyList = [Select Id, AccountId from Opportunity where AccountId IN (Select Id From Account where BillingPostalCode IN:zipAccIdListMap.keySet()) ];
			System.debug('**** processOTMRecords, opptyList size = ' + opptyList.size());
			System.debug('**** processOTMRecords, opptyList = ' + opptyList);
			//PREPARE ACCOUNT ID AND OPPORTUNITY ID LIST MAP
			Map<Id, Set<Id>> accIdOppIdSetMap = new Map<Id, Set<Id>>();
			Set<Id> oppIdSet = null;
			
			for(Opportunity oppty : opptyList){
				oppIdSet = accIdOppIdSetMap.containsKey(oppty.AccountId) ? accIdOppIdSetMap.get(oppty.AccountId) : new Set<Id>();
				oppIdSet.add(oppty.Id);
				
				accIdOppIdSetMap.put(oppty.AccountId, oppIdSet);
			}
			System.debug('**** accIdOppIdSetMap = ' + accIdOppIdSetMap);
			
			//Delete all OTP recods related to zipcode related Accounts
			List<OpportunityTeamMember> deleteOTMList = [Select Id From OpportunityTeamMember where OpportunityId IN :opptyList];
			System.debug('**** processOTMRecords, deleteOTMList = ' + deleteOTMList);
			delete deleteOTMList;
			
			
			//Query all AAAR records to create new OTP records
			List<Adobe_Account_Assignment_Rules__c> aaarList = [Select Id,ZIP_Code__c,Assigned_Rep__c,Role__c,Access_Level__c  from Adobe_Account_Assignment_Rules__c where ZIP_Code__c IN: zipAccIdListMap.keySet()];
			
			Map<String, List<Adobe_Account_Assignment_Rules__c>> zipAAARListMap = new Map<String, List<Adobe_Account_Assignment_Rules__c>>();
			List<Adobe_Account_Assignment_Rules__c> tempAAARList = null;
			
			for(Adobe_Account_Assignment_Rules__c aaar : aaarList){
				tempAAARList = zipAAARListMap.containsKey(aaar.ZIP_Code__c) ? zipAAARListMap.get(aaar.ZIP_Code__c) : new List<Adobe_Account_Assignment_Rules__c>();
				tempAAARList.add(aaar);
				
				zipAAARListMap.put(aaar.ZIP_Code__c, tempAAARList);
			}
			System.debug('**** processOTMRecords, zipAAARListMap .size()= ' + zipAAARListMap.size());
			System.debug('**** processOTMRecords, zipAAARListMap = ' + zipAAARListMap);
			List<OpportunityTeamMember> insertOTMList = new List<OpportunityTeamMember>();
			OpportunityTeamMember otm = null;
			for(String zc : zipAccIdListMap.keySet()){//Iterate for each zip-code
			if(zipAccIdListMap.containsKey(zc))
				for(Id accId : zipAccIdListMap.get(zc)){//Iterate for each Account
				if(accIdOppIdSetMap.containsKey(accId))
					for(Id oppId : accIdOppIdSetMap.get(accId)){
						if(zipAAARListMap.containsKey(zc))
						for(Adobe_Account_Assignment_Rules__c aaar : zipAAARListMap.get(zc)){
							System.debug('**** processOTMRecords , aaar = ' + aaar);
							//CREATE OTM ONLY FOR READ/WRITE AND READ PERMISSION RECORDS AND SKIP OWNER RECORDS
							if(!aaar.Access_Level__c.equals('Owner')){
								otm = new OpportunityTeamMember(OpportunityId = oppId, UserId = aaar.Assigned_Rep__c, TeamMemberRole = aaar.Role__c, OpportunityAccessLevel = aaar.Access_Level__c  == 'Read/Write' ? 'Edit' : 'Read' );
								insertOTMList.add(otm);
							}
						}
					}
				}
			}
			System.debug('***** insertOTMList size = ' + insertOTMList.size());
			System.debug('***** insertOTMList = ' + insertOTMList);
			
			if(!insertOTMList.isEmpty()){
				insert insertOTMList;
			}
		}
		
	}
}