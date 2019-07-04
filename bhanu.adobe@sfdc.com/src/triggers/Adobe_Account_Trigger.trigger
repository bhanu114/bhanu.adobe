trigger Adobe_Account_Trigger on Account (after insert, after update) {

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            System.debug('**** in Account Trigger, before insert');
            Adobe_Account_Trigger_Handler.reEvaluateSharing(null, Trigger.newMap);
        }
         if(Trigger.isUpdate){
             System.debug('**** in Account Trigger, before update');
             Adobe_Account_Trigger_Handler.reEvaluateSharing(Trigger.oldMap, Trigger.newMap);
         }
        
    }
}