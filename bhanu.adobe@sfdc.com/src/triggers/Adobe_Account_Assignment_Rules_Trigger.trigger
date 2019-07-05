/*****************************************************************************************
* @author       Bhanu Jangam   
* @date         02-July-2019
* @description  Trigger on  Adobe_Account_Assignment_Rules__c object to perform after insert,update and delete operations
*
*    --------------------------------------------------------------------------
*    Developer                  Date                Description
*    --------------------------------------------------------------------------
* 
******************************************************************************************/
trigger Adobe_Account_Assignment_Rules_Trigger on Adobe_Account_Assignment_Rules__c (after insert,after update, after delete) {
    
    if(Trigger.isAfter){
        if(Trigger.isInsert){
			Adobe_Account_Assignment_Rules_Helper.performAccountATMEvaluation(null, Trigger.newMap);
        }
        if(Trigger.isUpdate){
            Adobe_Account_Assignment_Rules_Helper.performAccountATMEvaluation(Trigger.oldMap, Trigger.newMap);
        }
		if(Trigger.isDelete){
			Adobe_Account_Assignment_Rules_Helper.performAccountATMDeletion(Trigger.oldMap);
        }
    }
}