/*****************************************************************************************
* @author       Bhanu Jangam   
* @date         02-July-2019
* @description  Trigger on  Account object to perform after insert and update operations
*
*    --------------------------------------------------------------------------
*    Developer                  Date                Description
*    --------------------------------------------------------------------------
* 
******************************************************************************************/
trigger Adobe_Account_Trigger on Account (after insert, after update) {

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            Adobe_Account_Trigger_Handler.reEvaluateSharing(null, Trigger.newMap);
        }
         if(Trigger.isUpdate){
             Adobe_Account_Trigger_Handler.reEvaluateSharing(Trigger.oldMap, Trigger.newMap);
         }
        
    }
}