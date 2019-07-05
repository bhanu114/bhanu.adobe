/*****************************************************************************************
* @author       Bhanu Jangam   
* @date         02-July-2019
* @description  Helper class to process Opportunity Trigger operations
*
*    --------------------------------------------------------------------------
*    Developer                  Date                Description
*    --------------------------------------------------------------------------
* 
******************************************************************************************/
public class Adobe_Opportunity_Trigger_Helper {

        /******************************************************************************************
    * Method Name : reEvaluateSharing
    * Parameters  : List<Opportunity> - (Newly created) Opportunity List
    * Return Type : void
    * Description : This method used to create and assign OTM records based on ATM records associated to parent Account
    ******************************************************************************************/
    public static void reEvaluateSharing(List<Opportunity> newOpptyList){
        
        Map<String,Set<String>> accIdOpptyIdSetMap = Adobe_GenericOperationsHelper.getFieldValueKeyListOfObjectIDSetFromList(newOpptyList,'AccountId');
        //For each opportunity fetch related Account ATM records and create OTM records respectively
        //new AccountTeamMember(AccountId = eachAcc.Id, UserId = aaar.Assigned_Rep__c, TeamMemberRole = aaar.Role__c, AccountAccessLevel = aaar.Access_Level__c == 'Read/Write' ? 'Edit' : 'Read');
        List<AccountTeamMember> atmList = [Select Id,AccountId,UserId,TeamMemberRole,AccountAccessLevel From AccountTeamMember where AccountId IN: accIdOpptyIdSetMap.keySet()];
        
        Map<String, List<AccountTeamMember>> accIdATMListMap = Adobe_GenericOperationsHelper.getFieldValueKeyListOfObjectsFromList(atmList,'AccountId');
        
        //For each opportunity create respective OTM records based on related Account ATM records
        List<OpportunityTeamMember> insertOTMList = new List<OpportunityTeamMember>();
        OpportunityTeamMember otm = null;
        for(String accId : accIdOpptyIdSetMap.keySet()){
            if(accIdATMListMap.containsKey(accId)){
                for(String oppId : accIdOpptyIdSetMap.get(accId)){
                    for(AccountTeamMember atm : accIdATMListMap.get(accId)){
                        otm = new OpportunityTeamMember(OpportunityId = oppId, UserId = atm.UserId, TeamMemberRole = atm.TeamMemberRole, OpportunityAccessLevel = atm.AccountAccessLevel);
                        insertOTMList.add(otm);
                    }
                }
            }
        }
        insert insertOTMList;//TODO : Exception handling
    }
    
    /* public static void processOnOwnerChange(Map<Id, Opportunity> oldOpptyMap, Map<Id, Opportunity> newOpptyMap){
        List<Opportunity> opptyWithNewOwnerList = new List<Opportunity>();
        
        for(Id oppId : newOpptyMap.keySet()){
            if(oldOpptyMap.get(oppId).OwnerId != newOpptyMap.get(oppId).OwnerId){
                opptyWithNewOwnerList.add(newOpptyMap.get(oppId));
            }
        }
        System.debug('**** Oppty trigger,processOnOwnerChange, opptyWithNewOwnerList = ' + opptyWithNewOwnerList);
        reEvaluateSharing(opptyWithNewOwnerList);
    } */
}