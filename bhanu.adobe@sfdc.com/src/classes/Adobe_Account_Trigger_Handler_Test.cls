/*****************************************************************************************
* @author       Bhanu Jangam   
* @date         02-July-2019
* @description  Test Class for Adobe_Account_Trigger_Handler  
*
*    --------------------------------------------------------------------------
*    Developer                  Date                Description
*    --------------------------------------------------------------------------
* 
******************************************************************************************/
@isTest
public class Adobe_Account_Trigger_Handler_Test {
    /******************************************************************************************
    * Method Name : setupData
    * Parameters  : N/A
    * Return Type : void
    * Description : This method used to create test data in test context
    ******************************************************************************************/
    @testSetup static void setupData() {
        
        Account ac = new Account(name ='Test Account 1', BillingPostalCode = '10001') ;
        insert ac; 
        
        Opportunity opp = new Opportunity();
        opp.StageName = 'Sourcing Demand';
        opp.CloseDate = System.Today().addDays(10);
        opp.AccountId = ac.Id;
        opp.Name = 'Test Opportunity Triggers';
        insert opp;
        
        //Get Profile
        String adminProId = [Select Id from Profile where Name ='System Administrator' Limit 1].Id;
        
        //Create Users
        List<User> userList = new List<User>();
        for(Integer i=0;i<2;i++) {
            userList.add( new User(alias = 'test' + i, email='test123@noemail.com',
                                   emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                   localesidkey='en_US', profileid = adminProId, country='United States',IsActive =true,
                                   //ContactId = con.Id,
                                   timezonesidkey='America/Los_Angeles', username='abraka'+i+'@noemail.com'));
        }
        insert userList;
        
        
        // Create common test Adobe_Account_Assignment_Rules__c
        List<Adobe_Account_Assignment_Rules__c> testAAARList = new List<Adobe_Account_Assignment_Rules__c>();
        testAAARList.add(new Adobe_Account_Assignment_Rules__c(ZIP_Code__c = '10002', Assigned_Rep__c = userList[0].Id, Role__c = 'Sales Rep', Access_Level__c = 'Read'));
        testAAARList.add(new Adobe_Account_Assignment_Rules__c(ZIP_Code__c = '10001', Assigned_Rep__c = userList[0].Id, Role__c = 'Sales Rep', Access_Level__c = 'Read'));
        testAAARList.add(new Adobe_Account_Assignment_Rules__c(ZIP_Code__c = '10001', Assigned_Rep__c = userList[0].Id, Role__c = 'Sales Rep', Access_Level__c = 'Owner'));
        
        insert testAAARList; 
    }
    
    /******************************************************************************************
    * Method Name : testAccountCreation
    * Parameters  : N/A
    * Return Type : void
    * Description : This method used test Account Creation logic
    ******************************************************************************************/
    private static testMethod void testAccountCreation(){
        List<Account> accList = [Select Id,OwnerId,BillingPostalCode from Account ];
       
        Test.startTest();
        Account ac = new Account(name ='The Account 1', BillingPostalCode = '10001') ;
        insert ac;
        Test.stopTest();
        System.assertNotEquals(ac.Id,null);
    }
    /******************************************************************************************
    * Method Name : testAccountUpdate
    * Parameters  : N/A
    * Return Type : void
    * Description : This method used test Account update logic
    ******************************************************************************************/
    private static testMethod void testAccountUpdate(){
        List<Account> accList = [Select Id,OwnerId,BillingPostalCode from Account ];
        List<User> userList = [Select Id from User];
        
        Test.startTest();
        accList[0].OwnerId = userList[0].Id;
        update accList[0];
        
        accList[0].BillingPostalCode = '10002';
        update accList;
        Test.stopTest();
        System.assertEquals(accList[0].BillingPostalCode,'10002');
    }
}