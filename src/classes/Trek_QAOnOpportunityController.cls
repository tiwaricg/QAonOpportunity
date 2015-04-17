/**
* \arg ClassName        : Trek_QAOnOpportunityController
* \arg CreatedOn      	: 14th/APR/2015
* \arg LastModifiedOn   : 16th/APR/2015
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
		public Id strProductId											{	get; set;	}
		public List<QuestionsAnswerWrapper> lstQuestionsAnswerWrapper	{	get; set;	}
		
		/* Wrrapper class constructor */
		public QuestionsAnswerWrapperToGroup(Id strProductId, String strProduct, List<QuestionsAnswerWrapper> lstQuestionsAnswerWrapper)
		{
			this.strProductId = strProductId;
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
		public String strSelectedValue		{	get; set;	}
		
		/* Wrrapper class constructor */
		public QuestionsAnswerWrapper(Question__c objQues, Answer__c objAns, String strSelectedValue)
		{
			this.objQues = objQues;
			this.objAns = objAns;
			this.strSelectedValue = strSelectedValue;
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
    	Map<Id, List<Question__c>> mapProdGrpIdTolstQues = new Map<Id, List<Question__c>>();
		Map<Id, Id> mapProductIdToProductGroupId = new Map<Id, Id>(); 
		Map<Id, List<QuestionsAnswerWrapper>> mapProductTolstQuesAnsWrapper = new Map<Id, List<QuestionsAnswerWrapper>>();
		MAp<Id, String> mapProductIdProductName = new Map<Id, String>();
		
		List<QuestionsAnswerWrapper> lstQuestionsAnswerWrap = new List<QuestionsAnswerWrapper>();
		List<Answer__c> lstAnswerToInsert = new List<Answer__c>();
		List<Id> lstProductId = new List<Id>();
		
		Set<String> setOppId_ProductId = new Set<String>();
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
				if(!mapProdGrpIdTolstQues.containsKey(objQues.Product_Group__c))
				{
					mapProdGrpIdTolstQues.put(objQues.Product_Group__c, new List<Question__c>{objQues});
				}
				else
				{
					mapProdGrpIdTolstQues.get(objQues.Product_Group__c).add(objQues);
				}
			}
			
			List<Answer__c> lstAllAnswer = [SELECT Id,
												   QuesId__c, 
												   Answer__c,
												   Product__c,
												   Values__c,
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
				upsert lstAnswerToInsert;
			}
			
			Map<String, Answer__c> mapProductIdQueId_Answer = new Map<String, Answer__c>(); 
			
			for(Answer__c objAnswer : [SELECT Id,
											   QuesId__c, 
											   Answer__c,
											   Product__c,
											   Values__c,
											   Opportunity__c 
										  FROM Answer__c 
										 WHERE Opportunity__c =: opportunityId]) 
			{
				if(objAnswer.QuesId__c != null && objAnswer.Product__c != null && objAnswer.Opportunity__c != null)
				{
					mapProductIdQueId_Answer.put(objAnswer.Product__c + '_' + objAnswer.QuesId__c, objAnswer);
				}	  
			}
								
			Set<Id> setQuestIdToAvoidDuplicate = new Set<Id>();
			
			for(Id objProductId : mapProductIdToProductGroupId.keyset())
			{
				Id productGrpId = mapProductIdToProductGroupId.get(objProductId);
				
				for(Question__c objQues : mapProdGrpIdTolstQues.get(productGrpId))
				{
					if(!setQuestIdToAvoidDuplicate.contains(objQues.Id))
					{
						setQuestIdToAvoidDuplicate.add(objQues.Id);
						
						if(mapQueIdToQuestion.containsKey(objQues.Id) && mapProductIdQueId_Answer.containsKey(objProductId + '_' + objQues.Id))
						{
							lstQuestionsAnswerWrap.add(new QuestionsAnswerWrapper(mapQueIdToQuestion.get(objQues.Id), mapProductIdQueId_Answer.get(objProductId + '_' +objQues.Id), null));
						}	
					}
				}
				mapProductTolstQuesAnsWrapper.put(objProductId, lstQuestionsAnswerWrap);
					
			}
						
	    	lstProductId.addAll(mapProductTolstQuesAnsWrapper.keySet());
	    	    	    	
	    	for(Id strProductId : lstProductId)
	    	{
	    		
	    		lstQuestionsAnswerWrapperToGroup.add(new QuestionsAnswerWrapperToGroup(strProductId, mapProductIdProductName.get(strProductId), mapProductTolstQuesAnsWrapper.get(strProductId)));
	    	}
	    }
    }
	
	public void saveAnswer()
	{
		Set<Answer__c> lstAnswerToSave = new Set<Answer__c>();
		
		for(QuestionsAnswerWrapperToGroup objWraP : lstQuestionsAnswerWrapperToGroup)
		{
			System.debug('=========objWraP='+objWraP.lstQuestionsAnswerWrapper);
		
			for(Integer i=0; i < objWraP.lstQuestionsAnswerWrapper.size(); i++)
			{
				Answer__c objAns = new Answer__c(Id = objWraP.lstQuestionsAnswerWrapper[i].objAns.Id, Values__c = objWraP.lstQuestionsAnswerWrapper[i].objAns.Values__c,
												 Answer__c = objWraP.lstQuestionsAnswerWrapper[i].objAns.Answer__c);
				lstAnswerToSave.add(objAns);
			}	
		}
				
		List<Answer__c> lstToupdate = new List<Answer__c>();
		if(!lstAnswerToSave.isEmpty())
		{
			lstToupdate.addAll(lstAnswerToSave);
			update lstToupdate;
		}
		
	} 
}