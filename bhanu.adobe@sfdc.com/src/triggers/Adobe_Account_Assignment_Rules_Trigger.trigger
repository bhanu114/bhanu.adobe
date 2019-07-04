trigger Adobe_Account_Assignment_Rules_Trigger on Adobe_Account_Assignment_Rules__c (after insert,after update, after delete) {
    
    if(Trigger.isAfter){
        if(Trigger.isInsert){
			System.debug('**** in AAAR Trigger, after insert');
			Adobe_Account_Assignment_Rules_Helper.performAccountATMEvaluation(null, Trigger.newMap);
        }
        if(Trigger.isUpdate){
        	System.debug('**** in AAAR Trigger, after update');
            Adobe_Account_Assignment_Rules_Helper.performAccountATMEvaluation(Trigger.oldMap, Trigger.newMap);
        }
		if(Trigger.isDelete){
			System.debug('**** in AAAR Trigger, after delete');
			Adobe_Account_Assignment_Rules_Helper.performAccountATMDeletion(Trigger.oldMap, Trigger.newMap);
        }
    }
}