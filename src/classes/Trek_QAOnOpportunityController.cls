/**
* \arg ClassName        : Trek_QAOnOpportunityController
* \arg CreatedOn      	: 14th/APR/2015
* \arg LastModifiedOn   : 15th/APR/2015
* \arg CreatededBy    	: Mukesh
* \arg LastModifiedBy	: Mukesh
* \arg Description    	: This class is used to get question and answers related to opportunity.
*/
public with sharing class Trek_QAOnOpportunityController 
{
	
	public Map<Id, String> mapQuesIdToAns										{	get;set;	}
	public List<Question__c> lstQuestionsToDisplay								{	get;set;	}
	public String strOpportunityName											{	get;set;	}
	
	public Integer intTotalAnsQues												{	get;set;	}
	public Integer intTotalUnAnsQues											{	get;set;	}
	public List<QuestionsAnswerWrapperToGroup> lstQuestionsAnswerWrapperToGroup {	get;set;	}
	
	private Id opportunityId;
	
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
		public List<QuestionsAnswerWrapper> lstQuestionsAnswerWrapper	{	get; set;	}
		
		/* Wrrapper class constructor */
		public QuestionsAnswerWrapperToGroup(String strProduct, List<QuestionsAnswerWrapper> lstQuestionsAnswerWrapper)
		{
			this.strProduct = strProduct;
			this.lstQuestionsAnswerWrapper = lstQuestionsAnswerWrapper;
		}
			
	}
	/* End  - Wrapper class QuestionsAnswerWrapperToGroup */
	
	/*
     @InnerClassName: QuestionsAnswerWrapper
     @param: None
     @Description: Wrraper class to bind data
	*/
	public class QuestionsAnswerWrapper
	{	
		public Question__c objQues			{	get; set;	}
		public Answer__c objAns				{	get; set;	}
		
		/* Wrrapper class constructor */
		public QuestionsAnswerWrapper(Question__c objQues, Answer__c objAns)
		{
			this.objQues = objQues;
			this.objAns = objAns;
		}		
	}
	/* End  - Wrapper class QuestionsAnswerWrapper */
	
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
		mapQuesIdToAns = new MAp<Id, String>();
		lstQuestionsToDisplay = new List<Question__c>();
		
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
     @Description: 
    */
    public void fetchQuestionAndAnswerOppProduct()
    {
    	Map<Id, List<Id>> mapProdGrpIdTolstProductId = new Map<Id, List<Id>>();
    	Map<Id, List<Id>> mapProdGrpIdTolstQuesId = new Map<Id, List<Id>>();
		Map<Id, Id> mapProductIdToProductGroupId = new Map<Id, Id>(); 
		Map<Id, List<QuestionsAnswerWrapper>> mapProductTolstQuesAnsWrapper = new Map<Id, List<QuestionsAnswerWrapper>>();
		MAp<Id, String> mapProductIdProductName = new Map<Id, String>();
		
		List<QuestionsAnswerWrapper> lstQuestionsAnswerWrapper = new List<QuestionsAnswerWrapper>();
		List<Answer__c> lstAnswerToInsert = new List<Answer__c>();
		List<Answer__c> lstAnswer = new List<Answer__c>();
		List<Id> lstProductId = new List<Id>();
		
		Set<String> setOppId_ProductId = new Set<String>();
    	Set<String> setProductIds = new Set<String>();
    	Set<String> setUniqueAns = new Set<String>();
    	
    	lstQuestionsAnswerWrapperToGroup = new List<QuestionsAnswerWrapperToGroup>();
    	
    	Integer totalQuest = 0; 
    	
    	if(opportunityId != null)
    	{
    		/* Iterating over the OLI related to current Opportunity */
			for(OpportunityLineItem objOLI : [SELECT Id, 
													 PricebookEntry.Product2.Product_Group__c,
													 PricebookEntry.Product2.Name,
													 PricebookEntry.Product2.Id
											    From OpportunityLineItem 
											   WHERE OpportunityId =: opportunityId 
											     AND PricebookEntry.Product2.Product_Group__c != null]) 
			{
				if(!mapProdGrpIdTolstProductId.containskey(objOLI.PricebookEntry.Product2.Product_Group__c))
				{
					mapProdGrpIdTolstProductId.put(objOLI.PricebookEntry.Product2.Product_Group__c, new List<Id>{objOLI.PricebookEntry.Product2.Id});	
				}
				else
				{
					mapProdGrpIdTolstProductId.get(objOLI.PricebookEntry.Product2.Product_Group__c).add(objOLI.PricebookEntry.Product2.Id);
				}
				
				mapProductIdToProductGroupId.put(objOLI.PricebookEntry.Product2.Id, objOLI.PricebookEntry.Product2.Product_Group__c);
				mapProductIdProductName.put(objOLI.PricebookEntry.Product2.Id, objOLI.PricebookEntry.Product2.Name);
				setProductIds.add(objOLI.PricebookEntry.Product2.Id);
				
			}
			
			List<Question__c> lstQuestions = [SELECT Id, 
													 Name,
													 Type__c, 
													 Ques__c, 
													 Product_Group__c 
											    FROM Question__c 
											   WHERE Product_Group__c IN : mapProdGrpIdTolstProductId.keyset()];
			
			for(Question__c objQues : lstQuestions)
			{
				if(!mapProdGrpIdTolstQuesId.containsKey(objQues.Product_Group__c))
				{
					mapProdGrpIdTolstQuesId.put(objQues.Product_Group__c, new List<Id>{objQues.Id});
				}
				else
				{
					mapProdGrpIdTolstQuesId.get(objQues.Product_Group__c).add(objQues.Id);
				}
			}
			
			
			List<Answer__c> lstAllAnswer = [SELECT Id,
											  QuesId__c, 
											  Answer__c,
											  Product__c,
											  Opportunity__c 
										 FROM Answer__c 
										WHERE Opportunity__c =: opportunityId];
			
			for(Answer__c objAnswer : lstAllAnswer) 
			{
				if(objAnswer.QuesId__c != null && objAnswer.Product__c != null && objAnswer.Opportunity__c != null)
				{
					setUniqueAns.add(objAnswer.QuesId__c + '_' + objAnswer.Product__c + '_' + objAnswer.Opportunity__c);			
				}	  
			}
			
			Map<Id, Question__c> mapQueIdToQuestion = new Map<Id, Question__c>();
			
			for(Question__c objQuestion : lstQuestions)
			{
				mapQueIdToQuestion.put(objQuestion.Id, objQuestion);
				
				for(Id objProductId : mapProductIdToProductGroupId.keyset())
				{
					if(!setUniqueAns.contains(objQuestion.Id + '_' + objProductId + '_' + opportunityId))
					{
						lstAnswerToInsert.add(new Answer__c(QuesId__c = objQuestion.Id, Product__c = objProductId, Opportunity__c = opportunityId, Answer__c = ''));
					}
				}
				
			}
			
			if(!lstAnswerToInsert.isEmpty())
			{
				insert lstAnswerToInsert;
			}
			
			for(Answer__c objAnswer : lstAllAnswer) 
			{
				if(objAnswer.QuesId__c != null && objAnswer.Product__c != null && objAnswer.Opportunity__c != null)
				{
					lstAnswer.add(objAnswer);
				}	  
			}
			
			for(Id objProductId : mapProductIdToProductGroupId.keyset())
			{
				for(Answer__c objAns : lstAnswer)	
				{
					lstQuestionsAnswerWrapper.add(new QuestionsAnswerWrapper(mapQueIdToQuestion.get(objAns.QuesId__c), objAns));
				}
				
				mapProductTolstQuesAnsWrapper.put(objProductId, lstQuestionsAnswerWrapper);
			}
						
	    	lstProductId.addAll(mapProductTolstQuesAnsWrapper.keySet());
	    	
	    	for(Id strProductId : lstProductId)
	    	{
	    		lstQuestionsAnswerWrapperToGroup.add(new QuestionsAnswerWrapperToGroup(mapProductIdProductName.get(strProductId), mapProductTolstQuesAnsWrapper.get(strProductId)));
	    	}
		}
    }
	
	void saveAnswer()
	{
		
	} 
	
}