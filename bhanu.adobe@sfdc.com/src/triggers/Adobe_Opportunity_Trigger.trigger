/*****************************************************************************************
* @author       Bhanu Jangam   
* @date         02-July-2019
* @description  Trigger on  Opportunity object to perform after insert operations
*
*    --------------------------------------------------------------------------
*    Developer                  Date                Description
*    --------------------------------------------------------------------------
* 
******************************************************************************************/
trigger Adobe_Opportunity_Trigger on Opportunity (after insert) {

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            Adobe_Opportunity_Trigger_Helper.reEvaluateSharing( Trigger.new);
        }
       
    }
}