/*****************************************************************************************
* @author       Bhanu Jangam   
* @date         02-July-2019
* @description  Test Class for Adobe_Opportunity_Trigger_Helper 
*
*    --------------------------------------------------------------------------
*    Developer                  Date                Description
*    --------------------------------------------------------------------------
* 
******************************************************************************************/
@isTest
public class Adobe_Opportunity_Trigger_Helper_Test {

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
        for(Integer i=0;i<4;i++) {
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
    * Method Name : testOpptyCreation
    * Parameters  : N/A
    * Return Type : void
    * Description : This method used test Opportunity Creation logic
    ******************************************************************************************/
    private static testMethod void testOpptyCreation(){
        List<Account> accList = [Select Id,OwnerId,BillingPostalCode from Account Limit 1];
        
        Test.startTest();
        Account ac = new Account(name ='The Good 34', BillingPostalCode = '10001') ;
        insert ac; 
        
         Opportunity opp = new Opportunity();
       
           opp.StageName = 'Sourcing Demand';
           opp.CloseDate = System.Today().addDays(10);
           opp.AccountId = ac.Id;
           opp.Name = 'The Opportunity Triggers';
           insert opp;
           Test.stopTest();
           System.assertNotEquals(opp.Id,null);
    }
}