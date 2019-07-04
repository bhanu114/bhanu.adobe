/*  */
public class Adobe_Account_Trigger_Handler {
    public static Boolean is_Adobe_Account_Trigger_Handler_Running = false;//THID FLAG PREVENT RECRESIVE UPDATE IN ACCOUNT AND ASSIGNMENT RULES OBJECT
    
	/*  */
    public static void reEvaluateSharing(Map<Id,Account> oldAccMap,Map<Id,Account> newAccMap){
        is_Adobe_Account_Trigger_Handler_Running = true;
        
        //CHECK IF ASSIGNMENT RULE TRIGGER NOT STARTED THE PROCESS
        if(Adobe_Account_Assignment_Rules_Helper.is_Adobe_Account_Assignment_Rules_Helper == false){
            Map<String,String> oldZipCodeNewZipCodeMap = new Map<String, String>();
            Map<String, Id> newAccountZipCodeIdMap = new Map<String, Id>();//Used to Identify for which Account related ATM's should be deleted
            String zipCode = null;
            Boolean isIncludeAssignmentRecords = false;
			Boolean isIncludeOwner = false;
			
            List<Account> tempAccList = null;
            Map<String, List<Account>> newAccZipCodeAccListMap = new Map<String, List<Account>>();
            
            Map<String, Id> zipCodeNewOwnerIdMap = new Map<String, Id>();
            Map<String, Id> zipCodeOldOwnerIdMap = new Map<String, Id>();
            Set<Id> ownerChangeAccIdSet = new Set<Id>();
            List<Id> tempAccIdList = null;
			Map<String, List<Id>> zipAccIdListMap = new Map<String, List<Id>>();
			
			/* PREPARE DATA STRUCTURE TO PERFORM INSERT UPDATE AND DELETE OPERATIONS BASED ON ACCOUNT RECORD UPDATE */
            for(Id newAccId : newAccMap.keySet()){
                zipCode = newAccMap.get(newAccId).BillingPostalCode;
                if(oldAccMap != null){//on Update
                    System.debug('*** ITs Update event');
                    if(oldAccMap.get(newAccId).BillingPostalCode != newAccMap.get(newAccId).BillingPostalCode){
                        System.debug('*** Account ZipCode is Changed');
						isIncludeAssignmentRecords = true;
						tempAccIdList = zipAccIdListMap.containsKey(zipCode) ? zipAccIdListMap.get(zipCode) : new List<Id>() ;
						tempAccIdList.add(newAccId);
						zipAccIdListMap.put(zipCode, tempAccIdList);
						
                        //oldZipCodeNewZipCodeMap.put(oldAccMap.get(newAccId).BillingPostalCode, newAccMap.get(newAccId).BillingPostalCode);
                        newAccountZipCodeIdMap.put(newAccMap.get(newAccId).BillingPostalCode, newAccId);
                        
                        //BULKIFY IF MULTIPLE ACCOUNTS HAS SAME ZIP CODE
                        tempAccList = newAccZipCodeAccListMap.containsKey(zipCode) ? newAccZipCodeAccListMap.get(zipCode) : new List<Account>{newAccMap.get(newAccId)};
                            newAccZipCodeAccListMap.put(newAccMap.get(newAccId).BillingPostalCode, tempAccList);
                    }
                    if(oldAccMap.get(newAccId).OwnerId != newAccMap.get(newAccId).OwnerId){
                        System.debug('*** Account Owner changed');
                        isIncludeOwner = true;
                        zipCodeNewOwnerIdMap.put(zipCode, newAccMap.get(newAccId).OwnerId);
                        zipCodeOldOwnerIdMap.put(zipCode, oldAccMap.get(newAccId).OwnerId);
                        ownerChangeAccIdSet.add(newAccId);
                    }
                } else {//On Account Create
                    System.debug('*** Account is creating');
                    //newAccountZipCodeIdMap.put(newAccMap.get(newAccId).BillingPostalCode, newAccId);
                    if(!String.isBlank(zipCode)){
						tempAccIdList = zipAccIdListMap.containsKey(zipCode) ? zipAccIdListMap.get(zipCode) : new List<Id>() ;
						tempAccIdList.add(newAccId);
						zipAccIdListMap.put(zipCode, tempAccIdList);
				
                        System.debug('*** new Account has zip code populated');
                        //zipCode = newAccMap.get(newAccId).BillingPostalCode;
                        //BULKIFY IF MULTIPLE ACCOUNTS HAS SAME ZIP CODE
                        tempAccList = newAccZipCodeAccListMap.containsKey(zipCode) ? newAccZipCodeAccListMap.get(zipCode) : new List<Account>();
                        tempAccList.add(newAccMap.get(newAccId));
                        newAccZipCodeAccListMap.put(newAccMap.get(newAccId).BillingPostalCode, tempAccList);
                        newAccountZipCodeIdMap.put(newAccMap.get(newAccId).BillingPostalCode, newAccId);
                    }
                }
            }
            //System.debug('**** oldZipCodeNewZipCodeMap = ' + oldZipCodeNewZipCodeMap);
            System.debug('**** newAccountZipCodeIdMap = ' + newAccountZipCodeIdMap);
            
            System.debug('**** zipCodeNewOwnerIdMap = ' + zipCodeNewOwnerIdMap);
            System.debug('**** zipCodeOldOwnerIdMap = ' + zipCodeOldOwnerIdMap);
            System.debug('**** ownerChangeAccIdSet = ' + ownerChangeAccIdSet);
            System.debug('**** zipAccIdListMap = ' + zipAccIdListMap);
            
            
            
            /* BUSINESS LOGIC TO EXECUTE ON ACCOUNT ZIP-CODE UPDATE/CREATE */
            if(newAccZipCodeAccListMap.size() > 0){//DO BELOW OPERATIONS ONLY IF RECORDS FOUND TO INSERT/UPDATE
			
                //Delete Account ATM records for old Zip Code - START
                if(newAccountZipCodeIdMap.size() > 0 && isIncludeAssignmentRecords == true){
                    List<AccountTeamMember> delATMList = [Select Id, AccountId From AccountTeamMember where AccountId IN: newAccountZipCodeIdMap.values()];
                    System.debug('**** delATMList size = ' + delATMList.size());
                    
                    delete delATMList;
					
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
				updateAAARRecords(zipCodeOldOwnerIdMap, ownerChangeAccIdSet, zipCodeNewOwnerIdMap); 
            }
			
			/* Update OpportunityTeamMebers */
			Adobe_Util.processOTMRecords(zipAccIdListMap);
        }
    }
    /* This method will create new ATM records for ZipCode changed Accounts */
    public static Map<Id,Id> createATMRecordsOnZipChange(Map<String, List<Account>> newAccZipCodeAccListMap){
		Map<Id,Id> accIdNewOwnerIdMap = new Map<Id,Id>();
        
        if(newAccZipCodeAccListMap.size() > 0){
            List<Adobe_Account_Assignment_Rules__c> aaarList = null;
            String zipCode = null;
            
            //RE-CREATE NEW ATM RECORDS ACCORDING TO NEW ZIP-CODE
            aaarList = [Select Id, ZIP_Code__c, Assigned_Rep__c, Role__c, Access_Level__c FROM Adobe_Account_Assignment_Rules__c where ZIP_Code__c IN:newAccZipCodeAccListMap.keySet() ];
            System.debug('**** aaarList size = ' + aaarList.size());
            
            Map<String, List<Adobe_Account_Assignment_Rules__c>> zipCodeAAARListMap = new Map<String, List<Adobe_Account_Assignment_Rules__c>>();
            List<Adobe_Account_Assignment_Rules__c> tempAAARList = null;
            
            
            for(Adobe_Account_Assignment_Rules__c aaar : aaarList){
                zipCode = aaar.ZIP_Code__c;
                System.debug('**** in for, zipCodeAAARListMap.containsKey(zipCode) = ' + zipCodeAAARListMap.containsKey(zipCode));
                tempAAARList = zipCodeAAARListMap.containsKey(zipCode) ? zipCodeAAARListMap.get(zipCode) : new List<Adobe_Account_Assignment_Rules__c>();
                /*if(zipCodeAAARListMap.containsKey(zipCode)){
System.debug('*** adding aaar to implicit temp list ' );
zipCodeAAARListMap.get(zipCode).add(aaar);
}else {
System.debug('*** Creating new Map record and adding aaar to new temp list ' );
zipCodeAAARListMap.put(zipCode, new List<Adobe_Account_Assignment_Rules__c>{aaar});
}*/
                tempAAARList.add(aaar);
                System.debug('*** tempAAARList .size()= ' + tempAAARList.size());
                System.debug('*** tempAAARList = ' + tempAAARList);
                zipCodeAAARListMap.put(zipCode, tempAAARList);
            }
            System.debug('**** zipCodeAAARListMap key size = ' + zipCodeAAARListMap.keySet().size());
            System.debug('**** zipCodeAAARListMap value size = ' + zipCodeAAARListMap.values().size());
            System.debug('**** zipCodeAAARListMap value  = ' + zipCodeAAARListMap.values());
            List<AccountTeamMember> insertAccTeamList = new List<AccountTeamMember>();
			
            AccountTeamMember atm = null;
            
            
            /* Itirate thorugh each ZipCode and assign Assignment Rules to each Account assigned with respective ZipCode */
            for(String newZipCode : newAccZipCodeAccListMap.keySet()){
                System.debug('**** for, newZipCode = ' + newZipCode);
                if(zipCodeAAARListMap.containsKey(newZipCode)){
                    System.debug('**** for, zipCodeAAARListMap.containsKey(newZipCode) = ' + zipCodeAAARListMap.containsKey(newZipCode));
                    System.debug('**** for, newAccZipCodeAccListMap.get(newZipCode) = ' + newAccZipCodeAccListMap.get(newZipCode));
                    for(Account eachAcc : newAccZipCodeAccListMap.get(newZipCode)){
                        System.debug('*** For each Account with Same Zip-Code');
                        for(Adobe_Account_Assignment_Rules__c aaar : zipCodeAAARListMap.get(newZipCode)){
                            System.debug('**** for, aaar = ' + aaar);
                            if(!aaar.Access_Level__c.equals('Owner')){//Identify the Owner record to update Account
                                atm = new AccountTeamMember(AccountId = eachAcc.Id, UserId = aaar.Assigned_Rep__c, TeamMemberRole = aaar.Role__c, AccountAccessLevel = aaar.Access_Level__c == 'Read/Write' ? 'Edit' : 'Read');
                                insertAccTeamList.add(atm);
                            } else {//COLLECT ACCOUNTS TO UPDATE OWNER
                                //eachAcc.OwnerId = aaar.Assigned_Rep__c;
                                accIdNewOwnerIdMap.put(eachAcc.Id, aaar.Assigned_Rep__c);
                            }
                        }
                    }
                }
            }
            
            System.debug('**** insertAccTeamList size = ' + insertAccTeamList.size());
            System.debug('**** insertAccTeamList  = ' + insertAccTeamList);
            System.debug('**** accIdNewOwnerIdMap size = ' + accIdNewOwnerIdMap.size());
            System.debug('**** accIdNewOwnerIdMap  = ' + accIdNewOwnerIdMap);
            //insert insertAccTeamList;
            Database.SaveResult[] srList = Database.insert(insertAccTeamList, false);
            
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
			if(insertAccTeamList.size() > 0){
				
			}
        }
		return accIdNewOwnerIdMap;
    }
	
	
    
	public static void updateAAARRecords(Map<String, Id> zipCodeOldOwnerIdMap, Set<Id> ownerChangeAccIdSet,  Map<String, Id> zipCodeNewOwnerIdMap){
		if(zipCodeOldOwnerIdMap.size() > 0){
                List<Adobe_Account_Assignment_Rules__c> updatableAAARList = new List<Adobe_Account_Assignment_Rules__c>();
                updatableAAARList = [Select Id, Assigned_Rep__c,ZIP_Code__c  From Adobe_Account_Assignment_Rules__c where ZIP_Code__c IN:zipCodeOldOwnerIdMap.keySet() AND Assigned_Rep__c IN:zipCodeOldOwnerIdMap.values() AND Access_Level__c ='Owner'];
                System.debug('**** updatableAAARList.size() = ' + updatableAAARList.size());
                System.debug('**** updatableAAARList = ' + updatableAAARList);
                //TODO: DELETE ATM RECORD FOR OLD OWNER
                List<AccountTeamMember> atmList = [Select Id From AccountTeamMember where AccountId IN:ownerChangeAccIdSet AND UserId IN:zipCodeOldOwnerIdMap.values() AND AccountAccessLevel='Edit'];
                System.debug('**** atmList = ' + atmList);
                
                List<AccountShare> accShareList = [Select Id From AccountShare where AccountId IN:ownerChangeAccIdSet AND UserOrGroupId IN:zipCodeOldOwnerIdMap.values()];
                System.debug('**** accShareList = ' + accShareList);
                //UPDATE AAAR OWNER RECORD WITH NEW SALESE REP
                for(Adobe_Account_Assignment_Rules__c aaar  : updatableAAARList){
                    aaar.Assigned_Rep__c = zipCodeNewOwnerIdMap.get(aaar.ZIP_Code__c);
                }
                update updatableAAARList;
            }
	}
   
}