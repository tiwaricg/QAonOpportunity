/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Trek_Test_QAOnOpportunityController {

    static testMethod void myUnitTest() 
    {
    	/* Insert Opportunity */  
		Opportunity objOpportunity = new Opportunity(Name = 'Test', StageName='Stage 0 - Lead Handed Off', CloseDate=Date.today());
      	insert objOpportunity; 
      
      	/* Insert Product Group */
		Product_Group__c objProductGroup1 = new Product_Group__c(Name = 'TestProductGroup1'); 
		insert objProductGroup1;
		
		Product_Group__c objProductGroup2 = new Product_Group__c(Name = 'TestProductGroup2'); 
		insert objProductGroup2;
		
		/* Insert Product */
		Product2 objProduct1 = new Product2(Name = 'Test Product1', family = 'test family', isActive = true, Product_Group__c = objProductGroup1.Id);
    	insert objProduct1;
    	
    	Product2 objProduct2 = new Product2(Name = 'Test Product2', family = 'test family', isActive = true, Product_Group__c = objProductGroup1.Id);
    	insert objProduct2;
    	
    	Product2 objProduct3 = new Product2(Name = 'Test Product3', family = 'test family', isActive = true, Product_Group__c = objProductGroup2.Id);
    	insert objProduct3;
    	
    	/* Get standard PricebookId */
    	Id peiceBookId = Test.getStandardPricebookId();  
    	
    	/* Get standard PricebookEntry */
		PriceBookEntry objPBE1 = new PriceBookEntry(UnitPrice = 300, PriceBook2Id = peiceBookId, Product2Id = objProduct1.Id, IsActive = true);
		insert objPBE1;
		
		PriceBookEntry objPBE2 = new PriceBookEntry(UnitPrice = 300, PriceBook2Id = peiceBookId, Product2Id = objProduct2.Id, IsActive = true);
		insert objPBE2;
		
		PriceBookEntry objPBE3 = new PriceBookEntry(UnitPrice = 300, PriceBook2Id = peiceBookId, Product2Id = objProduct3.Id, IsActive = true);
		insert objPBE3;
		
		/* Insert Opportunuty Line Item */		
		OpportunityLineItem objOLI1 = new OpportunityLineItem(pricebookentryid = objPBE1.Id, Quantity = 1, OpportunityId = objOpportunity.id, TotalPrice = 1000);
		insert objOLI1;		       
		
		OpportunityLineItem objOLI2 = new OpportunityLineItem(pricebookentryid = objPBE2.Id, Quantity = 1, OpportunityId = objOpportunity.id, TotalPrice = 1000);
		insert objOLI2;
		
		OpportunityLineItem objOLI3 = new OpportunityLineItem(pricebookentryid = objPBE3.Id, Quantity = 1, OpportunityId = objOpportunity.id, TotalPrice = 1000);
		insert objOLI3;
		
		/* Insert Questions */
		Question__c objQues1 = new Question__c(Ques__c = 'What will be the expected price of the product?', Product_Group__c = objProductGroup1.Id, Type__c = 'Text'); 
		insert objQues1;					  
		
		Question__c objQues2 = new Question__c(Ques__c = 'Does it available in India?', Product_Group__c = objProductGroup1.Id, Type__c = 'Boolean'); 
		insert objQues2;
		
		Question__c objQues3 = new Question__c(Ques__c = 'What is the value of this?', Product_Group__c = objProductGroup2.Id, Type__c = 'Picklist'); 
		insert objQues3;
		
		
		ApexPages.currentPage().getParameters().put('oppId', objOpportunity.id);
		Trek_QAOnOpportunityController objQAOnOpportunityController = new Trek_QAOnOpportunityController();
		
		List<Answer__c> lstAnswer1 = [SELECT Id, Product__c FROM Answer__c WHERE Product__c =: objProduct1.Id AND Product__r.IsActive = true];
		List<Answer__c> lstAnswer2 = [SELECT Id, Product__c FROM Answer__c WHERE Product__c =: objProduct2.Id AND Product__r.IsActive = true];
		List<Answer__c> lstAnswer3 = [SELECT Id, Product__c FROM Answer__c WHERE Product__c =: objProduct3.Id AND Product__r.IsActive = true];
		
		Trek_QAOnOpportunityController.QuestionsAnswerWrapperToGroup objQueAnsWrapper1 = new Trek_QAOnOpportunityController.QuestionsAnswerWrapperToGroup(objProduct1.Name, lstAnswer1);
		Trek_QAOnOpportunityController.QuestionsAnswerWrapperToGroup objQueAnsWrapper2 = new Trek_QAOnOpportunityController.QuestionsAnswerWrapperToGroup(objProduct2.Name, lstAnswer2);
		Trek_QAOnOpportunityController.QuestionsAnswerWrapperToGroup objQueAnsWrapper3 = new Trek_QAOnOpportunityController.QuestionsAnswerWrapperToGroup(objProduct3.Name, lstAnswer3);
		
		objQAOnOpportunityController.fetchQuestionAndAnswerOppProduct();
		
		objQAOnOpportunityController.saveAnswer();
		
		/* Assrting the proper out put */
		System.assertEquals(5, [SELECT Id FROM Answer__c].size());
		System.assertEquals(3, [SELECT Id FROM Question__c].size());
		
    }
}