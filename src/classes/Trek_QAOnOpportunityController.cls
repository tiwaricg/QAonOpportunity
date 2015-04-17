/**
* \arg ClassName        : Trek_QAOnOpportunityController
* \arg CreatedOn      	: 14th/APR/2015
* \arg LastModifiedOn   : 17th/APR/2015
* \arg CreatededBy    	: Mukesh
* \arg LastModifiedBy	: Mukesh
* \arg Description    	: This class is used to get question and answers related to opportunity.
*/
public with sharing class Trek_QAOnOpportunityController 
{
	
	public String strOpportunityName											{	get;set;	}
	public Integer intTotalAnsQues												{	get;set;	}
	public Integer intTotalUnAnsQues											{	get;set;	}
	public List<QuestionsAnswerWrapperToGroup> lstQuestionsAnswerWrapperToGroup {	get;set;	}
	private  Id opportunityId;
	
	/* Start - Constructor */
	public Trek_QAOnOpportunityController()
	{
		initialization();
	}
	/* End - Constructor */
	
	/*
     @InnerClassName: QuestionsAnswerWrapperToGroup
     @param: None
     @Description: Wrraper class to bind data
     
	*/
	public class QuestionsAnswerWrapperToGroup
	{
		public String strProduct										{	get; set;	}
		public List<Answer__c> lstQuestionsAnswer						{	get; set;	}
		
		/* Wrrapper class constructor */
		public QuestionsAnswerWrapperToGroup(String strProduct, List<Answer__c> lstQuestionsAnswer)
		{
			this.strProduct = strProduct;
			this.lstQuestionsAnswer = lstQuestionsAnswer;
		}
			
	}
	/* End  - Wrapper class QuestionsAnswerWrapperToGroup */
	
	/*
     @MethodName: initialization
     @param: na
     @Description: to initialize variables
    */
    void initialization()
    {
    	intTotalAnsQues = 0;
    	intTotalUnAnsQues = 0;
    	opportunityId = apexpages.currentpage().getparameters().get('oppId');
		
		for(Opportunity objOpportunity : [SELECT Name 
										    FROM Opportunity 
										   WHERE Id =: opportunityId])
		{
			strOpportunityName  = objOpportunity.Name; 
		}
    }
    
    /*
     @MethodName: fetchOLIForSelectedOpportunity
     @param: na
     @Description: This method is used to get all the questions and answers related to each products and group   
    */
    public void fetchQuestionAndAnswerOppProduct()
    {
    	Map<Id, List<Id>> mapProdGrpIdTolstProductId = new Map<Id, List<Id>>();
    	Map<Id, List<Question__c>> mapProdGrpIdTolstQues = new Map<Id, List<Question__c>>();
		Map<Id, String> mapProductIdProductName = new Map<Id, String>();
		Map<Id, String> mapProductId_QuesAns = new Map<Id, String>();
		Map<Id, List<String>> mapProductId_lstQuesAns = new Map<Id, List<String>>();
		Map<Id, List<Answer__c>> mapProductId_lstAns = new Map<Id, List<Answer__c>>();
		Map<Id, Answer__c> mapAnsId_Answer = new Map<Id, Answer__c>();
		
		List<Id> lstProductId = new List<Id>();
		List<Answer__c> lstNewAnswer = new List<Answer__c>();  
		List<Answer__c> lstAnswerToInsert = new List<Answer__c>();
		List<Question__c> lstQuestions = new List<Question__c>();
		 
    	Set<String> setUniqueAns = new Set<String>();
    	Set<Id> setProductGroupId = new Set<Id>();
    	Set<Id> setProductId = new Set<Id>();
    	
    	lstQuestionsAnswerWrapperToGroup = new List<QuestionsAnswerWrapperToGroup>();
    	Integer totalQuest = 0; 
    	
    	if(opportunityId != null)
    	{
    		/* Iterating over the OLI related to current Opportunity */
			for(OpportunityLineItem objOLI : [SELECT Id, 
													 PricebookEntry.Product2.Product_Group__c,
													 PricebookEntry.Product2.Name,
													 PricebookEntry.Product2.Id,
													 PricebookEntry.Product2.isActive
											    From OpportunityLineItem 
											   WHERE OpportunityId =: opportunityId 
											     AND PricebookEntry.Product2.Product_Group__c != null 
											     AND PricebookEntry.Product2.isActive = true]) 
			{
				if(!mapProdGrpIdTolstProductId.containskey(objOLI.PricebookEntry.Product2.Product_Group__c))
				{
					mapProdGrpIdTolstProductId.put(objOLI.PricebookEntry.Product2.Product_Group__c, new List<Id>{objOLI.PricebookEntry.Product2.Id});	
				}
				else
				{
					mapProdGrpIdTolstProductId.get(objOLI.PricebookEntry.Product2.Product_Group__c).add(objOLI.PricebookEntry.Product2.Id);
				}
				
				setProductGroupId.add(objOLI.PricebookEntry.Product2.Product_Group__c);
				setProductId.add(objOLI.PricebookEntry.Product2.Id);
				mapProductIdProductName.put(objOLI.PricebookEntry.Product2.Id, objOLI.PricebookEntry.Product2.Name);
			}
			
			lstQuestions = [SELECT Id, 
								   Name,
								   Type__c,
								   Ques__c, 
								   Product_Group__c 
							  FROM Question__c 
							 WHERE Product_Group__c IN : mapProdGrpIdTolstProductId.keyset()];
			
			for(Question__c objQues : lstQuestions)
			{
				if(!mapProdGrpIdTolstQues.containsKey(objQues.Product_Group__c))
				{
					mapProdGrpIdTolstQues.put(objQues.Product_Group__c, new List<Question__c>{objQues});
				}
				else
				{
					mapProdGrpIdTolstQues.get(objQues.Product_Group__c).add(objQues);
				}
			}
			
			for(Answer__c objAnswer : [SELECT Id,
											   QuesId__c, 
											   Answer__c,
											   Product__c,
											   Values__c,
											   Opportunity__c,
											   Product__r.IsActive 
										  FROM Answer__c 
										 WHERE Opportunity__c =: opportunityId AND Product__r.IsActive = true]) 
			{
				if(objAnswer.QuesId__c != null && objAnswer.Product__c != null && objAnswer.Opportunity__c != null)
					setUniqueAns.add(objAnswer.Product__c + '_' + objAnswer.QuesId__c + '_' + objAnswer.Opportunity__c);			
			}
			
			/* Iterating over the set product group Id to know the no of questions are in product */
			for(Id objProductGroupId : setProductGroupId)
			{
				for(Question__c objQuestion : mapProdGrpIdTolstQues.get(objProductGroupId))
				{
					for(Id objProductId : mapProdGrpIdTolstProductId.get(objProductGroupId))
					{
						if(!setUniqueAns.contains(objProductId + '_' + objQuestion.Id + '_' + opportunityId))
						{
							lstAnswerToInsert.add(new Answer__c(QuesId__c = objQuestion.Id, Product__c = objProductId, Opportunity__c = opportunityId));
						}
					}	
				}
			}
			
			/* Inserting an emty answer with corresponding to questions realeted to product */
			if(!lstAnswerToInsert.isEmpty())
				insert lstAnswerToInsert;
			
			/* Iterating over the all answer realted to current opportunity */
			for(Answer__c objAnswer : [SELECT Id,
											  QuesId__c,
											  QuesId__r.Product_Group__c,
											  QuesId__r.Ques__c,
											  QuesId__r.Type__c,  
											  Answer__c,
											  Product__c,
											  Values__c,
											  Product__r.IsActive,
											  Opportunity__c,
											  True_False__c 
										 FROM Answer__c 
										WHERE Opportunity__c =: opportunityId AND Product__r.IsActive = true]) 
			{
				lstNewAnswer.add(objAnswer);
				
				if(objAnswer.Product__c != null && objAnswer.QuesId__c != null && objAnswer.Opportunity__c != null)
				{
					if(objAnswer.Answer__c != null && objAnswer.Answer__c != '' && objAnswer.QuesId__r.Type__c != 'Boolean' && objAnswer.QuesId__r.Type__c != 'Picklist')
						intTotalAnsQues += 1; 
					
					if(objAnswer.QuesId__r.Type__c == 'Picklist' && objAnswer.Values__c != null && objAnswer.Values__c != '')
						intTotalAnsQues += 1;	
					
					if(objAnswer.QuesId__r.Type__c == 'Boolean' && objAnswer.True_False__c == true)
						intTotalAnsQues += 1;
					
					mapProductId_QuesAns.put(objAnswer.Product__c, objAnswer.QuesId__c + '_'+objAnswer.Id);
						
					if(!mapProductId_lstQuesAns.containskey(objAnswer.Product__c))
					{
						mapProductId_lstQuesAns.put(objAnswer.Product__c, new List<String>{objAnswer.QuesId__c + '_' + objAnswer.Id});
					}
					else
					{
						mapProductId_lstQuesAns.get(objAnswer.Product__c).add(objAnswer.QuesId__c + '_'+ objAnswer.Id);
					}
				
					mapAnsId_Answer.put(objAnswer.Id, objAnswer);
				}	
			}
			
			intTotalUnAnsQues = lstNewAnswer.size() - intTotalAnsQues;
			
			/* Iterating over the set product Id to know respective question and answer */
			for(Id objProductId : setProductId)
			{
				List<String> lstQueIdAnsId = mapProductId_lstQuesAns.get(objProductId);
				List<String> lstAnsId = new List<String>();
				
				for(String str : lstQueIdAnsId)
				{
					lstAnsId.add(str.substringAfter('_'));
				}
				
				/* Iterating over the answer related to product */
				for(Id ansId : lstAnsId)
				{
					if(!mapProductId_lstAns.containsKey(objProductId))
					{
						mapProductId_lstAns.put(objProductId, new List<Answer__c>{mapAnsId_Answer.get(ansId)});
					}
					else
					{
						mapProductId_lstAns.get(objProductId).add(mapAnsId_Answer.get(ansId));
					}		
				}
			}
			
			/* Adding all product into list */ 
			lstProductId.addAll(mapProductId_lstAns.keyset());
			
			/* Iterating over the list of product Id to add into the Wrrapeer classs */
			for(Id strProductId : lstProductId)
	    	{
	    		lstQuestionsAnswerWrapperToGroup.add(new QuestionsAnswerWrapperToGroup(mapProductIdProductName.get(strProductId), mapProductId_lstAns.get(strProductId)));
	    	}
		}
    }
	
	/*
     @MethodName: saveAnswer
     @param: na
     @Description: This method is used to save all answers 
    */
	public void saveAnswer()
	{
		List<Answer__c> lstAnswerToSave = new List<Answer__c>();
		List<Answer__c> lstAnswerToCheckTotalAnswerAndUnAnsQue = new List<Answer__c>();
		intTotalAnsQues = 0;
    	intTotalUnAnsQues = 0;
		
		for(QuestionsAnswerWrapperToGroup objWraP : lstQuestionsAnswerWrapperToGroup)
		{
			for(Answer__c objAnswer : objWraP.lstQuestionsAnswer)
			{
				lstAnswerToSave.add(new Answer__c(Id = objAnswer.Id, Values__c = objAnswer.Values__c, Answer__c = objAnswer.Answer__c, True_False__c = objAnswer.True_False__c));
			}
		}
		
		if(!lstAnswerToSave.isEmpty())
		{
			update lstAnswerToSave;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Answers are saved successfully.'));
		}
		else
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No answers to save.'));
		}
		
		for(Answer__c objAnswer : [SELECT Id, 
										  Answer__c, 
										  Product__c, 
										  QuesId__c, 
										  Opportunity__c,
										  Product__r.IsActive,
										  QuesId__r.Type__c,
										  Values__c,
										  True_False__c 
									 FROM Answer__c 
								    WHERE Opportunity__c =: opportunityId AND Product__r.IsActive = true])
		{
			lstAnswerToCheckTotalAnswerAndUnAnsQue.add(objAnswer);
			
			if(objAnswer.Product__c != null && objAnswer.QuesId__c != null && objAnswer.Opportunity__c != null)
			{
				if(objAnswer.Answer__c != null && objAnswer.Answer__c != '' && objAnswer.QuesId__r.Type__c != 'Boolean' && objAnswer.QuesId__r.Type__c != 'Picklist')
					intTotalAnsQues += 1;
				
				if(objAnswer.QuesId__r.Type__c == 'Picklist' && objAnswer.Values__c != null && objAnswer.Values__c != '')
					intTotalAnsQues += 1;
					
				if(objAnswer.QuesId__r.Type__c == 'Boolean' && objAnswer.True_False__c == true)
					intTotalAnsQues += 1;			
			}
		}
		
		intTotalUnAnsQues = lstAnswerToCheckTotalAnswerAndUnAnsQue.size() - intTotalAnsQues; 
	}
}