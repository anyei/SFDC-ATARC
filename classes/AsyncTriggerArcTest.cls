/*
 * Created By: Angel Robles
 * Created Date: 1/6/2017
 *   
 */ 
@IsTest
public class AsyncTriggerArcTest implements AsyncTriggerArc.IAsyncTriggerArc {
    
    public object execute(AsyncTriggerArc.AsyncTriggerArcContext triggerContext){
        string result;
        
        if(triggerContext.getCurrentProcessName() == 'Test Process 1')
            result = 'something new';
        
        if(triggerContext.getCurrentProcessName() == 'Test Process 2')
            result = 'something old'; 
        
        if(triggerContext.getCurrentProcessName() == 'Test Process 5')
            result = 'something from the queueable worker';
        
        if(triggerContext.getCurrentProcessName() == 'Test Process To Error')
            throw new AsyncTriggerArc.AsyncTriggerArcException('Error on purpose');
        
        if(triggerContext.getCurrentProcessName() == 'Test Process 6')
            result = 'something from 6';
        
        if(triggerContext.getCurrentProcessName() == 'Test Process 9')
            result = 'something from 9';
        
        return result;
            
    }
    
    
    @testsetup static void setupData(){
        List<AsyncTriggerArqSettings__c> testSettings = new List<AsyncTriggerArqSettings__c>{
            new AsyncTriggerArqSettings__c(Name='Test Process 1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           ApexTriggerName__c='OpportunityBeforeTrigger',Event__c='BeforeInsert',IsActive__c=true,Order__c=3, isAsync__c=false),
            new AsyncTriggerArqSettings__c(Name='Test Process 2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           ApexTriggerName__c='OpportunityBeforeTrigger',Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false),
            new AsyncTriggerArqSettings__c(Name='Test Process 3',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           ApexTriggerName__c='OpportunityBeforeTrigger',Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false),
            new AsyncTriggerArqSettings__c(Name='Test Process 4',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           ApexTriggerName__c='OpportunityBeforeTrigger',Event__c='BeforeInsert',IsActive__c=true,Order__c=4, 
                                               DependsOn__c = 'Test Process 2',isAsync__c=false),
           new AsyncTriggerArqSettings__c(Name='Test Process 5',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           ApexTriggerName__c='OpportunityBeforeTrigger',Event__c='BeforeInsert',IsActive__c=true,Order__c=5,isAsync__c=true)
        };
       
            
            insert testSettings;
	}
    
    @IsTest static void TriggerNameNotProvidedShouldThrowAnError(){
       AsyncTriggerArc.AsyncTriggerArcException expectedError = null;
        test.startTest();
        try{
            AsyncTriggerArc ata = new AsyncTriggerArc('Opportunity',null,
                                                   true, //before
                                                  false, 
                                                  true, //insert
                                                  false, 
                                                  false,
                                                  new List<Opportunity>(),
                                                  null,
                                                  null, 
                                                  null);
        }catch(AsyncTriggerArc.AsyncTriggerArcException error){
            expectedError = error;
        }
        
    	        
        
        test.stoptest();
        
       system.assert(expectedError != null, 'Expected error should not be null, current is null');
    
    }
    
    @IsTest static void ProcessOrderShouldOrderBaseOnTheOrderField(){
      AsyncTriggerArc ata = new AsyncTriggerArc('Opportunity','OpportunityBeforeTrigger',
                                               true, //before
                                              false, 
                                              true, //insert
                                              false, 
                                              false,
                                              new List<Opportunity>(),
                                              null,
                                              null, 
                                              null);
        
        test.starttest();    
    	AsyncTriggerArc.processOrder(true);
        test.stoptest();
        
        system.assert(AsyncTriggerArc.arqSettings.get('Opportunity').get('OpportunityBeforeTrigger').get('BeforeInsert').get(0).name == 'Test Process 3','Expected is "Test Process 3" is the first element in the list, current is '+
                      AsyncTriggerArc.arqSettings.get('Opportunity').get('OpportunityBeforeTrigger').get('BeforeInsert').get(0));
        
        system.assert(AsyncTriggerArc.arqSettings.get('Opportunity').get('OpportunityBeforeTrigger').get('BeforeInsert').get(1).name == 'Test Process 2','Expected is "Test Process 2" is the second element in the list, current is '+
                      AsyncTriggerArc.arqSettings.get('Opportunity').get('OpportunityBeforeTrigger').get('BeforeInsert').get(1));
        
        system.assert(AsyncTriggerArc.arqSettings.get('Opportunity').get('OpportunityBeforeTrigger').get('BeforeInsert').get(2).name == 'Test Process 1','Expected is "Test Process 1" is the second element in the list, current is '+
                      AsyncTriggerArc.arqSettings.get('Opportunity').get('OpportunityBeforeTrigger').get('BeforeInsert').get(2));
    }
    
    @IsTest static void TriggerWithNoSubscriptionsShouldNotWork(){
        AsyncTriggerArc ata = new AsyncTriggerArc('Opportunity','OpportunityAfterTrigger',
                                               true, //before
                                              false, 
                                              true, //insert
                                              false, 
                                              false,
                                              new List<Opportunity>(),
                                              null,
                                              null, 
                                              null);
        
        test.starttest();    
    	ata.Start();
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= ata.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        system.assert(totalProcesses == 5 && totalExecutedProcesses ==0, 'Expected is (totalProcesses 5 totalExecutedProcesses 0) Current is ( totalProcesses '+totalProcesses+' totalExecutedProcesses ' + totalExecutedProcesses +' ) ');
    }
    
    @IsTest static void TriggerWithShoulbscriptionsShouldExecuteThem(){
        AsyncTriggerArc ata = new AsyncTriggerArc('Opportunity','OpportunityBeforeTrigger',
                                               true, //before
                                              false, 
                                              true, //insert
                                              false, 
                                              false,
                                              new List<Opportunity>(),
                                              null,
                                              null, 
                                              null);
        
    	test.startTest();
        ata.Start();
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= ata.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status ==  AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        system.assert(totalProcesses == 5 && totalExecutedProcesses ==5, 'Expected is (totalProcesses 5 totalExecutedProcesses 5) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
    }
    
    @IsTest static void TriggerWithSubscriptionsShouldExecuteSuccess(){
        AsyncTriggerArc ata = new AsyncTriggerArc('Opportunity','OpportunityBeforeTrigger',
                                               true, //before
                                              false, 
                                              true, //insert
                                              false, 
                                              false,
                                              new List<Opportunity>(),
                                              null,
                                              null, 
                                              null);
        
    	test.startTest();        
        ata.Start();
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= ata.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        
     
        system.assert(totalProcesses == 5 && totalExecutedProcesses ==5, 'Expected is (totalProcesses 5 totalExecutedProcesses 5) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        system.assert(AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 1') == 'something new', 'Expected is "something new" Current is "'+AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 1')+'"');
               
        system.assert(AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 2') == 'something old', 'Expected is "something old" Current is "'+AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 2')+'"');
        
        system.assert(AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 3') == null, 'Expected is null Current is "'+AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 3')+'"');
    }
    
    @IsTest static void UsingSkipPRocessShouldNotExecuteSpecificProcess(){
        AsyncTriggerArc ata = new AsyncTriggerArc('Opportunity','OpportunityBeforeTrigger',
                                               true, //before
                                              false, 
                                              true, //insert
                                              false, 
                                              false,
                                              new List<Opportunity>(),
                                              null,
                                              null, 
                                              null);
        
    	test.startTest();
		ata.AddProcessSkip('Test Process 2');  
        ata.AddProcessSkip('test process fake');
        ata.AddSObjectSkip('testObject__c');
        
        //just to make sure the crappy coverage is good
        ata.removeObjectSkip('testObject__c');
        ata.removeProcessSkip('test process fake');
        ata.Start();
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= ata.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        system.assert(totalProcesses == 4 && totalExecutedProcesses ==3, 'Expected is (totalProcesses 4 totalExecutedProcesses 3) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        system.assert(AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 1') == 'something new', 'Expected is "something new" Current is "'+AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 1')+'"');
               
        system.assert(AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 3') ==  null, 'Expected is null Current is "'+AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 3')+'"');
        
        system.assert(AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 5') ==  'something from the queueable worker', 'Expected is "something from the queuable worker" Current is "'+AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 5')+'"');
    }
    
    
     @IsTest static void UsingSkipObjectShouldNotExecuteProcessForSpecificObject(){
        AsyncTriggerArc ata = new AsyncTriggerArc('Opportunity','OpportunityBeforeTrigger',
                                               true, //before
                                              false, 
                                              true, //insert
                                              false, 
                                              false,
                                              new List<Opportunity>(),
                                              null,
                                              null, 
                                              null);
        
    	test.startTest();
		ata.AddSObjectSkip('Opportunity');       
        ata.Start();
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= ata.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        system.assert(totalProcesses == 0 && totalExecutedProcesses ==0, 'Expected is (totalProcesses 0 totalExecutedProcesses 0) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
      }
    
    @IsTest static void ApexClassInTheSettingsIfDoesNotExistsShouldThrowError(){
        insert new AsyncTriggerArqSettings__c(Name='Test Process fake class',SObject__c='Opportunity', ApexHelperClassName__c='FakeRandomClassWhoWIllNeverExistsEverAsyncTriggerWithALongLongLongLOngLOnglONgName',
                                           ApexTriggerName__c='OpportunityBeforeTrigger',Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false,BreakIfError__c=true);
        AsyncTriggerArc ata = new AsyncTriggerArc('Opportunity','OpportunityBeforeTrigger',
                                               true, //before
                                              false, 
                                              true, //insert
                                              false, 
                                              false,
                                              new List<Opportunity>(),
                                              null,
                                              null, 
                                              null);
        string errorMessage = '';
        
    	test.startTest();
        try{
        	ata.Start();
        }catch(Exception error)
        {
            errorMessage=error.getMEssage();
        }
        test.stoptest();
        
        system.assert(errorMessage != '' && errorMessage != null,'No errors found, current is ' + errorMEssage);
      }
    
    
    @IsTest static void NextProcessToRunWhenDependenciesErrorOut(){
        
        List<AsyncTriggerArqSettings__c> testSettings = new List<AsyncTriggerArqSettings__c>{
            new AsyncTriggerArqSettings__c(Name='Test Process 6',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           ApexTriggerName__c='OpportunityBeforeTrigger',Event__c='BeforeInsert',IsActive__c=true,Order__c=6, isAsync__c=false),
                
            new AsyncTriggerArqSettings__c(Name='Test Process To Error',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           ApexTriggerName__c='OpportunityBeforeTrigger',Event__c='BeforeInsert',IsActive__c=true,Order__c=7, isAsync__c=false),
            new AsyncTriggerArqSettings__c(Name='Test Process 8',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',DependsOn__c='Test Process To Error',
                                           ApexTriggerName__c='OpportunityBeforeTrigger',Event__c='BeforeInsert',IsActive__c=true,Order__c=8, isAsync__c=false),
                
            new AsyncTriggerArqSettings__c(Name='Test Process 9',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           ApexTriggerName__c='OpportunityBeforeTrigger',Event__c='BeforeInsert',IsActive__c=true,Order__c=9, 
                                               isAsync__c=false)
           
        };
       
            
            insert testSettings;
        
        AsyncTriggerArc ata = new AsyncTriggerArc('Opportunity','OpportunityBeforeTrigger',
                                               true, //before
                                              false, 
                                              true, //insert
                                              false, 
                                              false,
                                              new List<Opportunity>(),
                                              null,
                                              null, 
                                              null);
        string errorMessage = '';
        
    	test.startTest();
        
        	ata.Start();
        
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= ata.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        system.assert(totalProcesses == 9 && totalExecutedProcesses ==7, 'Expected is (totalProcesses 9 totalExecutedProcesses 7) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
		
        system.assert(AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 6') == 'something from 6', 'Expected is "something from 6" Current is "'+AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 6')+'"');
 
        system.assert(AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process To Error') == null, 'Expected is null Current is "'+AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process To Error')+'"');
 
        system.assert(AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 8') == null, 'Expected is null Current is "'+AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 8')+'"');
        
        system.assert(AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 9') == 'something from 9', 'Expected is "something from 9" Current is "'+AsyncTriggerArc.globalConfig.triggerContext.getProcessData('Test Process 9')+'"');
        
        
      }

}