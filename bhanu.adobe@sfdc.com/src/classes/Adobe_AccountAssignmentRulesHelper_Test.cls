/*****************************************************************************************
* @author       Bhanu Jangam   
* @date         02-July-2019
* @description  Test Class for Adobe_AccountAssignmentRulesHelper
*
*    --------------------------------------------------------------------------
*    Developer                  Date                Description
*    --------------------------------------------------------------------------
* 
******************************************************************************************/
@isTest
public class Adobe_AccountAssignmentRulesHelper_Test {
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
        for(Integer i=0;i<2;i++) {
            testAAARList.add(new Adobe_Account_Assignment_Rules__c(ZIP_Code__c = '10001', Assigned_Rep__c = userList[i].Id, Role__c = 'Sales Rep', Access_Level__c = 'Read'));
        }
        insert testAAARList; 
    }
    /******************************************************************************************
    * Method Name : testAAARCreation
    * Parameters  : N/A
    * Return Type : void
    * Description : This method used test Assignment Rules Creation logic
    ******************************************************************************************/
    private static testMethod void testAAARCreation(){
        List<Account> accList = [Select Id,OwnerId from Account ];
        List<User> userList = [Select Id from User];
        
        accList[0].OwnerId = userList[0].Id;
        update accList[0];
        
        
        // Create common test Adobe_Account_Assignment_Rules__c
        List<Adobe_Account_Assignment_Rules__c> testAAARList = new List<Adobe_Account_Assignment_Rules__c>();
        
        testAAARList.add(new Adobe_Account_Assignment_Rules__c(ZIP_Code__c = '10001', Assigned_Rep__c = userList[0].Id, Role__c = 'Sales Rep', Access_Level__c = 'Read'));
        testAAARList.add(new Adobe_Account_Assignment_Rules__c(ZIP_Code__c = '10001', Assigned_Rep__c = userList[0].Id, Role__c = 'Sales Rep', Access_Level__c = 'Owner'));
        
        Test.startTest();
        System.runAs(userList[0]) {
            insert testAAARList;
        }
        Test.stopTest();
        System.assertNotEquals(testAAARList,null);
    }
    /******************************************************************************************
    * Method Name : testAAARUpdate
    * Parameters  : N/A
    * Return Type : void
    * Description : This method used test Assignment Rules Update logic
    ******************************************************************************************/
    private static testMethod void testAAARUpdate(){
        List<User> userList = [Select Id from User];
        
        
        List<Account> accList = [Select Id,OwnerId from Account ];
        
        List<Adobe_Account_Assignment_Rules__c> aaarList = [Select Id,ZIP_Code__c, Assigned_Rep__c from Adobe_Account_Assignment_Rules__c Limit 1];
        
        Test.startTest();
        aaarList[0].Assigned_Rep__c = userList[2].Id;
        update aaarList;
        System.assertEquals(aaarList[0].Assigned_Rep__c,userList[2].Id);
        
        aaarList[0].Assigned_Rep__c = userList[3].Id;
        update aaarList;
        System.assertEquals(aaarList[0].Assigned_Rep__c,userList[3].Id);
        Test.stopTest();
        
    }
    /******************************************************************************************
    * Method Name : testAAARDelete
    * Parameters  : N/A
    * Return Type : void
    * Description : This method used test Assignment Rules deletion logic
    ******************************************************************************************/
    private static testMethod void testAAARDelete(){
        List<Adobe_Account_Assignment_Rules__c> aaarList = [Select Id,ZIP_Code__c, Assigned_Rep__c from Adobe_Account_Assignment_Rules__c Limit 1];
        Test.startTest();
        delete aaarList;
        Test.stopTest();
        System.assertEquals(aaarList.size(),1);
    }
}