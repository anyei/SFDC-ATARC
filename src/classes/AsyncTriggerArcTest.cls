/*
* Created By: Angel Robles(anyei)
* Created Date: 1/6/2017
* Tested Class: AsyncTriggerArc  
*/ 
@IsTest
public class AsyncTriggerArcTest extends AsyncTriggerArc.AsyncTriggerArcFEAProcessBase {
    
    /*
* Mocking atarc base process implementation filter
*/ 
    protected override void filter(SObject oldRecord, sObject newRecord, AsyncTriggerArc.AsyncTriggerArcContext triggerContext){
        
        //testing Test Process 13
        if(triggerContext.getCurrentProcessName() == 'Test Process 13')
            triggerContext.setFailed();
        
        triggerContext.debug('filter  '+triggerContext.getCurrentProcessName() );
        
        //testing Test Process To Error
        if(triggerContext.getCurrentProcessName() == 'Test Process To Error')
            triggerContext.setFailed();
        
        if(triggerContext.getCurrentProcessName() == 'Filter Error 1')
            throw new AsyncTriggerArc.AsyncTriggerArcException('Filter Error 1');
        
        if(triggerContext.getCurrentProcessName() == 'Skip 5')
            triggerContext.bypass(AsyncTriggerArc.PROCESS_SKIP, 'Skip 6');
    }
    
    /*
* Mocking atarc base process implementation action
*/ 
    protected override void action(SObject oldRecord, sObject newRecord, AsyncTriggerArc.AsyncTriggerArcContext triggerContext){
        
         if(triggerContext.getCurrentProcessName() == 'Filter Error 2')
            throw new AsyncTriggerArc.AsyncTriggerArcException('Filter Error 2');
        
        if(triggerContext.getCurrentProcessName() == 'Skip 5')
            triggerContext.bypass(AsyncTriggerArc.PROCESS_SKIP, 'Skip 6');
        
        
    }
    
    /*
* MOCKING ATARC PROCESS 
*/
    protected override object execute(AsyncTriggerArc.AsyncTriggerArcContext triggerContext){
        object result;
        triggerContext.debug('current processes ' + triggerContext.getCurrentProcessName());
        
        if(triggerContext.getCurrentProcessName() == 'Test Process 1')
        {   result = 'something new'; AsyncTriggerArc.debug('this is for test'); }
        
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
        
        if(triggerContext.getCurrentProcessName() == 'Test Process 10'){
            result = (string)triggerContext.getProcessData('Test Process 10');
            if(result == null){
                triggerContext.LoopLimit = 3;
                result = '1';
            }
            else
                result = string.valueof(integer.valueof(result) + 1);
        }
        
        
        if(triggerContext.getCurrentProcessName() == 'Test Process 11'){
            result = triggerContext.getProcessData('Test Process 11');
            if(result == null){               
                result = 1;
            }
            else{
                result = integer.valueof(result) + 1;
            }
        }
        
        
        
        if(triggerContext.getCurrentProcessName() == 'Test Process 12'){
            result = triggerContext.getProcessData('Test Process 12');
            if(result == null){ 
                triggerContext.LoopLimit = 2;
                result = 1;
            }
            else
                result = integer.valueof(result) + 1;
        }
        if(triggerContext.getCurrentProcessName() == 'Test Process Recursive'){
            result = triggerContext.getProcessData('Test Process Recursive');
            if(result == null){ 
                result = 1;
            }
            else
                result = integer.valueof(result) + 1;
        }
        
        if(triggerContext.getCurrentProcessName() == 'Test Process 13'){
            triggerContext.setFailed();
            result = null;
        }
        
        if(triggerContext.getCurrentProcessName() == 'Test Process 14')
            result = 'something from 14';
        
        if(triggerContext.getCurrentProcessName() == 'Test Process 15')
            result = 'from 15';
        
        if(triggerContext.getCurrentProcessName() == 'Test Process async 1')
            result = 'form async p';
        
        if(triggerContext.getCurrentProcessName() == 'Filter Error 3')
            throw new AsyncTriggerArc.AsyncTriggerArcException('Filter Error 3');
        
        if(triggerContext.getCurrentProcessName() == 'Set Process Data')
        { 
            triggerContext.setData(10);
            result = 10;
        }
        
        if(triggerContext.getCurrentProcessName() == 'Get Process Data')
            if( ((integer) triggerContext.getProcessData('Set Process Data')) != 10) throw new AsyncTriggerArc.AsyncTriggerArcException('Set and Get Process Data Failed');
        
        if(triggerContext.getCurrentProcessName() == 'GeneralAvailabilityTrue')
            result = 1010;
        
        if(triggerContext.getCurrentProcessName() == 'GeneralAvailabilityFalse')
            result = 2020;
        
        return result;
        
    }
    
    @testSetup static void setupSettings(){
        ATARC_Global_Setting__c aSetting = new ATARC_Global_Setting__c(debug__c = false, LoopLimit__c=1);
        insert aSetting;
    }
    
    static List<ATARC_Process_Setting__mdt> setupData(){
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
                new ATARC_Process_Setting__mdt(DeveloperName='Test Process 3',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                               Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, BreakIfError__c=true, General_Availability__c=true),
                new ATARC_Process_Setting__mdt(DeveloperName='Test Process 2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                               Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, General_Availability__c=true),
                    new ATARC_Process_Setting__mdt(DeveloperName='Test Process 1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=3, isAsync__c=false, General_Availability__c=true),
                new ATARC_Process_Setting__mdt(DeveloperName='Test Process 4',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                               Event__c='BeforeInsert',IsActive__c=true,Order__c=4,
                                               DependsOnSuccess__c = 'Test Process 2',isAsync__c=false, General_Availability__c=true),
                new ATARC_Process_Setting__mdt(DeveloperName='Test Process 5',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                               Event__c='BeforeInsert',IsActive__c=true,Order__c=5,isAsync__c=false, General_Availability__c=true)
                };
          return testSettings;
                   
    }
    
    @IsTest static void ProcessOrderShouldOrderBaseOnTheOrderFieldDefault(){
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = setupData();
        test.starttest();    
        AsyncTriggerArc.processOrder(true);
        test.stoptest();
        
        system.assert(AsyncTriggerArc.arqSettings.get('Opportunity').get('BeforeInsert').get(0).DeveloperName == 'Test Process 3','Expected is "Test Process 3" is the first element in the list, current is '+
                      AsyncTriggerArc.arqSettings.get('Opportunity').get('BeforeInsert').get(0));
        
        system.assert(AsyncTriggerArc.arqSettings.get('Opportunity').get('BeforeInsert').get(1).DeveloperName == 'Test Process 2','Expected is "Test Process 2" is the second element in the list, current is '+
                      AsyncTriggerArc.arqSettings.get('Opportunity').get('BeforeInsert').get(1));
        
        system.assert(AsyncTriggerArc.arqSettings.get('Opportunity').get('BeforeInsert').get(2).DeveloperName == 'Test Process 1','Expected is "Test Process 1" is the second element in the list, current is '+
                      AsyncTriggerArc.arqSettings.get('Opportunity').get('BeforeInsert').get(2));
    }
    
    @IsTest static void EventsWithNoSubscriptionsShouldNotWork(){
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, 
            true, //insert
            false, 
            false,
            false,
            new List<Contact>{new Contact()},
            new List<Contact>{new Contact()},
            null, 
            null);
        AsyncTriggerArc.settings = setupData();
        test.starttest();    
        atarc.Start();
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        system.assert(totalProcesses == 5 && totalExecutedProcesses ==0, 'Expected is (totalProcesses 5 totalExecutedProcesses 0) Current is ( totalProcesses '+totalProcesses+' totalExecutedProcesses ' + totalExecutedProcesses +' ) ');
    }
    
    @IsTest static void EventWithSubscriptionsShouldExecuteThem(){
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = setupData();
        test.startTest();
        atarc.Start();
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status ==  AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        system.assert(totalProcesses == 5 && totalExecutedProcesses ==5, executionResult+'Expected is (totalProcesses 5 totalExecutedProcesses 5) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
    }
    
    @IsTest static void EventWithSubscriptionsShouldExecuteSuccess(){
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = setupData();
        test.startTest();        
        atarc.Start();
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        } 
        
        
        system.assert(totalProcesses == 5 && totalExecutedProcesses ==5, 'Expected is (totalProcesses 5 totalExecutedProcesses 5) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 1') == 'something new', 'Expected is "something new" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 1')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 2') == 'something old', 'Expected is "something old" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 2')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 3') == null, 'Expected is null Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 3')+'"');
    }
    
    @IsTest static void EventWithSubscriptionsShouldExecuteSuccessConstructor2(){
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = setupData();
        test.startTest();        
        atarc.Start();
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 5 && totalExecutedProcesses ==5, 'Expected is (totalProcesses 5 totalExecutedProcesses 5) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 1') == 'something new', 'Expected is "something new" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 1')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 2') == 'something old', 'Expected is "something old" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 2')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 3') == null, 'Expected is null Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 3')+'"');
    }
    
    @IsTest static void UsingSkipBypassProcessShouldNotExecuteSpecificProcess(){
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = setupData();
        AsyncTriggerArc.AsyncTriggerArcContext triggerContext = new AsyncTriggerArc.AsyncTriggerArcContext();
        
        test.startTest();
        triggerContext.bypass('process','Test Process 2');  
        triggerContext.bypass('process','test process fake');
        triggerContext.bypass('object','testObject__c');
        
        //just to make sure the crappy coverage is good
        triggerContext.clearBypass('object','testObject__c');
        triggerContext.clearBypass('process','test process fake');
        atarc.Start();
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        system.assert(totalProcesses == 4 && totalExecutedProcesses ==3, 'Expected is (totalProcesses 4 totalExecutedProcesses 3) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 1') == 'something new', 'Expected is "something new" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 1')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 3') ==  null, 'Expected is null Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 3')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 5') ==  'something from the queueable worker', 'Expected is "something from the queuable worker" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 5')+'"');
    }
    
    @IsTest static void UsingSkipBypassObjectShouldNotExecuteProcessForSpecificObject(){
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = setupData();
        AsyncTriggerArc.AsyncTriggerArcContext triggerContext = new AsyncTriggerArc.AsyncTriggerArcContext();
        
        test.startTest();
        triggerContext.bypass('object','Opportunity');       
        atarc.Start();
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        system.assert(totalProcesses == 0 && totalExecutedProcesses ==0, 'Expected is (totalProcesses 0 totalExecutedProcesses 0) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
    }
    
    @IsTest static void ApexClassInTheSettingsDoesNotExistsShouldThrowError(){
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
             new ATARC_Process_Setting__mdt(DeveloperName='Test Process fake class',SObject__c='Opportunity', ApexHelperClassName__c='FakeRandomClassWhoWIllNeverExistsEverAsyncTriggerWithALongLongLongLOngLOnglONgName',
                                              Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false,BreakIfError__c=true, General_Availability__c=true)
                 };
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = testSettings;
        string errorMessage = '';
        
        test.startTest();
        try{
            atarc.Start();
        }catch(Exception error)
        {
            errorMessage=error.getMEssage();
        }
        test.stoptest();
        
        system.assert(errorMessage != '' && errorMessage != null,'No errors found, current is ' + errorMEssage);
    }
    
    @IsTest static void NextProcessShouldRunWhenDependenciesErrorOut(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Test Process 6',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=6, isAsync__c=false, General_Availability__c=true),
                
                new ATARC_Process_Setting__mdt(DeveloperName='Test Process To Error',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                               debug__c = true, debug_Level__C='DEBUG',Event__c='BeforeInsert',IsActive__c=true,Order__c=7, isAsync__c=false, General_Availability__c=true),
                new ATARC_Process_Setting__mdt(DeveloperName='Test Process 8',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',DependsOnSuccess__c='Test Process To Error',
                                               debug__c = true, debug_Level__C='DEBUG',Event__c='BeforeInsert',IsActive__c=true,Order__c=8, isAsync__c=false, General_Availability__c=true),
                
                new ATARC_Process_Setting__mdt(DeveloperName='Test Process 9',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                               Event__c='BeforeInsert',IsActive__c=true,Order__c=9,isAsync__c=false, General_Availability__c=true)
                
                };
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = setupData();
        AsyncTriggerArc.settings.addAll(testSettings);
        string errorMessage = '';
        
        test.startTest();
        
        atarc.Start();
        
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        
        system.assert(totalProcesses == 9 && totalExecutedProcesses ==7, 'Expected is (totalProcesses 9 totalExecutedProcesses 7) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 6') == 'something from 6', 'Expected is "something from 6" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 6')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process To Error') == null, 'Expected is null Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process To Error')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 8') == null, 'Expected is null Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 8')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 9') == 'something from 9', 'Expected is "something from 9" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 9')+'"');
        
        
    }
    
    @IsTest static void transactionLoopShouldRun3Times(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Test Process 10',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='AfterInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true)
                
                
                };
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            false, //before
            true, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = testSettings;
        
        string errorMessage = '';
        
        test.startTest();
        
        atarc.Start();//first run
        atarc.Start();//second run
        atarc.Start();//third run
        
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        system.assert(totalProcesses == 1 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 1 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 10') == '3', 'Expected is "3" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 10')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.LoopLimit ==3, 'Expected is 3 current is '+atarc.globalConfig.triggerContext.LoopLimit);
        
        
    }
    
    @IsTest static void transactionLoopShouldRun1Times(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Test Process 11',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='AfterInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true)
                
                
                };
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            false, //before
            true, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = testSettings;
        
        string errorMessage = '';
        
        test.startTest();
        
        atarc.Start();//first run
        atarc.Start();//second run
        atarc.Start();//third run
        
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        system.assert(totalProcesses == 1 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 1 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 11') == 1, 'Expected is "1" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 11')+'"');        
        
    }
    
    @IsTest static void transactionLoopShouldRun2Times(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Test Process 12',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='AfterInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true)
                
                
                };
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            false, //before
            true, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = testSettings;
        
        string errorMessage = '';
        
        test.startTest();
        
        atarc.Start();//first run
        atarc.Start();//second run
        atarc.Start();//third run
        
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        system.assert(totalProcesses == 1 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 1 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 12') == 2, 'Expected is "2" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process 11')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.LoopLimit ==2, 'Expected is 2 as it ran  current is '+atarc.globalConfig.triggerContext.LoopLimit);
        
        
    }
    
    @IsTest static void triggerContextSetFailedDependentProcessNotRunning(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Test Process 13',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true),
                new ATARC_Process_Setting__mdt(DeveloperName='Test Process 14',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',DependsOnSuccess__c='Test Process 13',
                                               Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, General_Availability__c=true)
                
                
                };
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings = testSettings;
        
        string errorMessage = '';
        
        test.startTest();
        
        atarc.Start();//first run
        
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==0, 'Expected is (totalProcesses 2 totalExecutedProcesses 0) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessStatus('Test Process 13') == AsyncTriggerArc.PROCESS_FAILED, 'Expected is "Failed" Current is "'+atarc.globalConfig.triggerContext.getProcessStatus('Test Process 13')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessStatus('Test Process 14') == null, 'Expected is null Current is "'+atarc.globalConfig.triggerContext.getProcessStatus('Test Process 14')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process 14')== null, 'Expected is null as it ran  current is '+atarc.globalConfig.triggerContext.getProcessStatus('Test Process 14'));
        
        
    }
    
    @IsTest static void triggerContextSetFailedDependentOnErrorRunning(){
        
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Test Process 13',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true),
                new ATARC_Process_Setting__mdt(DeveloperName='Test Process 14',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',DependsOnFailure__c='Test Process 13',
                                               Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, General_Availability__c=true)
                
                
                };
                    
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = testSettings;
        
        string errorMessage = '';
        
        test.startTest();
        
        atarc.Start();//first run
        
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        
        
        //system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessStatus('Test Process 13') == AsyncTriggerArc.PROCESS_FAILED, 'Expected is "Failed" Current is "'+atarc.globalConfig.triggerContext.getProcessStatus('Test Process 13')+'"');
        
        system.assert(atarc.globalConfig.triggerContext.getProcessStatus('Test Process 14') ==  AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is "something from 14" Current is "'+atarc.globalConfig.triggerContext.getProcessStatus('Test Process 14')+'"');
        
        
    }
    
    @IsTest static void triggerContextAddEventSkip(){

        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Test Process 13',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true),
                new ATARC_Process_Setting__mdt(DeveloperName='Test Process 14',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',DependsOnSuccess__c='Test Process 13',
                                               Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, General_Availability__c=true),
                new ATARC_Process_Setting__mdt(DeveloperName='Test Process 15',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                               Event__c='AfterInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true)
                
                
                };
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = testSettings;
        
        AsyncTriggerArc.AsyncTriggerArcContext triggerContext = new AsyncTriggerArc.AsyncTriggerArcContext();
        
        string errorMessage = '';
        
        test.startTest();
        
        triggerContext.bypass('event', 'BeforeInsert');
        
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 1 && totalExecutedProcesses ==0, 'Expected is (totalProcesses 3 totalExecutedProcesses 0) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
    }
    
    @IsTest static void processWithAsyncShouldExecute(){
        
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Test Process async 1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='AfterInsert',IsActive__c=true,Order__c=1, isAsync__c=true, General_Availability__c=true)
                };
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            false, //before
            true, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = setupData();
        AsyncTriggerArc.settings.addAll(testSettings);
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 6 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 6 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(atarc.globalConfig.triggerContext.getProcessData('Test Process async 1') == 'form async p', 'Expected is "form async p" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process async 1')+'"');
        
    }
    
    @IsTest static void BypassProcess(){
        
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Skip 5',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='AfterInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='Skip 6',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='AfterInsert',IsActive__c=true,Order__c=2, isAsync__c=false, General_Availability__c=true)
                };
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            false, //before
            true, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = setupData();
        AsyncTriggerArc.settings.addAll(testSettings);
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 7 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 7 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('Skip 5').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for Skip 5');
        
    }
    
    @IsTest static void ErrorWhenNoSObjectTypeFound(){
        
        string errMsg = '';
        AsyncTriggerArc atarc;
        test.startTest();
        try{
            atarc = new AsyncTriggerArc(
            false, //before
            true, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{},
            new List<Opportunity>{},
            null, 
            null);
        }catch(Exception err){
            errMsg = err.getMessage();
        }
        
        test.stoptest();
        
        
        
        system.assert(atarc == null, 'Expected is atarc is null as there was an exception');
        system.assert(errMsg.containsIgnoreCase('sObject Name must be provided!!'), 'Expected is "sObject Name must be provided!!" Current is "'+errMsg+'"');
        
    }
    
    @IsTest static void ErrorInFEAFilterStep(){
        
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Filter Error 1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='AfterInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true)
                };
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            false, //before
            true, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = setupData();
        AsyncTriggerArc.settings.addAll(testSettings);
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 6 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 6 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('Filter Error 1').status==AsyncTriggerArc.PROCESS_FAILED, 'Expected is Process failed for Filter Error 1');
        
    }
    
    @IsTest static void ErrorInFEAActionStep(){
        
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Filter Error 2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='AfterInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true)
                };
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            false, //before
            true, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = setupData();
        AsyncTriggerArc.settings.addAll(testSettings);
        
        
        test.startTest();
        atarc.Start();
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 6 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 6 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('Filter Error 2').status==AsyncTriggerArc.PROCESS_FAILED, 'Expected is Process failed for Filter Error 2');
        
    }

    @IsTest static void ErrorInFEAExecuteStep(){
        
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Filter Error 3',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='AfterInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true)
                };
                    
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            false, //before
            true, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= setupData();
        AsyncTriggerArc.settings.addAll(testSettings);
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 6 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 6 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('Filter Error 3').status==AsyncTriggerArc.PROCESS_FAILED, 'Expected is Process failed for Filter Error 3');
        
    }
    
    @IsTest static void transactionLoopShouldRun4Times(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Test Process Recursive',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='AfterInsert',IsActive__c=true,Order__c=1, isAsync__c=false, Override_Loop_Limit__c=true, LoopLimit__c=4, General_Availability__c=true)
                
                
                };
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            false, //before
            true, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = testSettings;
        
        string errorMessage = '';
        
        test.startTest();
        
        atarc.Start();//first run
        atarc.Start();//second run
        atarc.Start();//third run
        atarc.Start();//third run
        
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        system.assert(totalProcesses == 1 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 1 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        system.assert(integer.valueof(atarc.globalConfig.triggerContext.getProcessData('Test Process Recursive') ) == 4, 'Expected is "4" Current is "'+atarc.globalConfig.triggerContext.getProcessData('Test Process Recursive')+'"');        
        
    }
    
    @IsTest static void AsyncIsIsolate(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Test Process Isolate',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='AfterInsert',IsActive__c=true,Order__c=1, isAsync__c=true,Isolate__c=true, General_Availability__c=true)
                
                
                };
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            false, //before
            true, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new Opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        AsyncTriggerArc.settings = testSettings;
        
        string errorMessage = '';
        
        test.startTest();
        
        atarc.Start();//first run
       
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ? 1 : 0);
        }
        system.assert(totalProcesses == 1 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 1 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
        
    }
    
     @IsTest static void GetAndSetProcessDataShouldWork(){
        
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='Set Process Data',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='Get Process Data',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, General_Availability__c=true)
                };
                    
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==2, 'Expected is (totalProcesses 2 totalExecutedProcesses 2) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('Get Process Data').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for Get Process Data');

    }

    @IsTest static void NoProcessRun(){
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, //update 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);        
        
        test.startTest();
        
        AsyncTriggerArc.globalSkip = true;
        atarc.Start();//first run
        
        
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 0 && totalExecutedProcesses ==0, 'Expected is (totalProcesses 0 totalExecutedProcesses 0) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        
    }
    
    @IsTest static void GeneralAvailabilityFullExecutesOneProcess(){
        
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='GeneralAvailabilityFalse',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=false, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='GeneralAvailabilityTrue',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true)
                };
                    
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('GeneralAvailabilityTrue').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for GeneralAvailabilityTrue');

    }
    
     @IsTest static void OnlyAvailableForOneGroupShouldRunOneProcess(){
        
        Group grp = new Group(); 
        grp.Name = 'ATARC_Group_Test1x'; 
        grp.Type = 'Regular'; 
        insert grp;
        
           GroupMember GrpMem = new GroupMember();
           GrpMem.GroupId = grp.Id;
           GrpMem.UserOrGroupId = UserInfo.getUserId();
           insert grpMem;
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=false, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=false)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
              new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule1', Scope__c='Group', Scope_Id_Value__c=grp.Id, Availability__c='Available',isActive__c=true)
                                                       //this doens't work ATARC_Process_Setting__r =  testSettings[1])
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule1'=>'ProcessWithoutGeneralAvail2'};                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('ProcessWithoutGeneralAvail2').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for ProcessWithoutGeneralAvail2');

    }
    
    @IsTest static void OnlyAvailableForOnePermissionSetsShouldRunOneProcess(){
        
       PermissionSet ps = new PermissionSet(Name='ATARC_PS_Test_1xx', Label='ATARC_PS_Test_1xx');
       insert ps;
        
       PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId=ps.id);
        insert psa;
                
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail3',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=false, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail4',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=false)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
              new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule2', Scope__c='PermissionSet', Scope_Id_Value__c=ps.Id, Availability__c='Available',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule2'=>'ProcessWithoutGeneralAvail3'};                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('ProcessWithoutGeneralAvail3').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for ProcessWithoutGeneralAvail3');

    }
    
    @IsTest static void OnlyAvailableForOneQueueShouldRunOneProcess(){
        
        Group grp = new Group(); 
        grp.Name = 'ATARC_Group_Test1x'; 
        grp.Type = 'Queue'; 
        insert grp;
        
           GroupMember GrpMem = new GroupMember();
           GrpMem.GroupId = grp.Id;
           GrpMem.UserOrGroupId = UserInfo.getUserId();
           insert grpMem;
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail5',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=false, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail6',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=false)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
              new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule3', Scope__c='Queue', Scope_Id_Value__c=grp.Id, Availability__c='Available',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule3'=>'ProcessWithoutGeneralAvail6'};                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('ProcessWithoutGeneralAvail6').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for ProcessWithoutGeneralAvail6');

    }
    
    @IsTest static void OnlyAvailableForOneProfileShouldRunOneProcess(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail7x',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=false, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail8x',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=false)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
              new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule4x', Scope__c='Profile', Scope_Id_Value__c=UserInfo.getProfileId(), Availability__c='Available',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule4x'=>'ProcessWithoutGeneralAvail7x'};                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('ProcessWithoutGeneralAvail7x').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for ProcessWithoutGeneralAvail7x');

    }
    
     @IsTest static void OnlyAvailableForOneRoleShouldRunOneProcess(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail7x1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=false, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail8x',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=false)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
              new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule4x1', Scope__c='Role', Scope_Id_Value__c=UserInfo.getUserRoleId(), Availability__c='Available',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule4x1'=>'ProcessWithoutGeneralAvail7x1'};                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('ProcessWithoutGeneralAvail7x1').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for ProcessWithoutGeneralAvail7x1');

    }
    
    @IsTest static void OnlyAvailableForOneUserShouldRunOneProcess(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail7',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=false, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail8',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=false)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
              new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule4', Scope__c='User', Scope_Id_Value__c=UserInfo.getUserId(), Availability__c='Available',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule4'=>'ProcessWithoutGeneralAvail7'};                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('ProcessWithoutGeneralAvail7').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for ProcessWithoutGeneralAvail7');

    }
    
    @IsTest static void OnlyAvailableForOneUserCustomFilterShouldRunOneProcess(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail9',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=false, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail10',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=false),
                new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail11',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=false),
                new ATARC_Process_Setting__mdt(DeveloperName='ProcessWithoutGeneralAvail12',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=false)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
             new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule5', Scope__c='User', Custom_Scope_Filter__c=true, Custom_Scope_Filter_Value__c='[{"field":"Name", "value":"'+userinfo.getName()+'","op":"="}]', Availability__c='Available',isActive__c=true),
             new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule6', Scope__c='User', Custom_Scope_Filter__c=true, Custom_Scope_Filter_Value__c='[{"field":"Email", "value":"'+userinfo.getUserEmail()+'", "op":"="}]', Availability__c='Available',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule5'=>'ProcessWithoutGeneralAvail9','rule6'=>'ProcessWithoutGeneralAvail11' };                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 4 && totalExecutedProcesses ==2, 'Expected is (totalProcesses 4 totalExecutedProcesses 2) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('ProcessWithoutGeneralAvail11').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for ProcessWithoutGeneralAvail11');
        system.assert(executionResult.get('ProcessWithoutGeneralAvail9').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for ProcessWithoutGeneralAvail9');

    }
    
    @IsTest static void GeneralUnavailableFullExecutesNoProcess(){
        
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='afalse1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=false, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='afalse2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=false)
                };
                    
                    
        
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==0, 'Expected is (totalProcesses 2 totalExecutedProcesses 0) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
    }
    
    @IsTest static void UnavailableForOneGroupShouldRunOneProcess(){
        
        Group grp = new Group(); 
        grp.Name = 'ATARC_Group_Test1x'; 
        grp.Type = 'Regular'; 
        insert grp;
        
           GroupMember GrpMem = new GroupMember();
           GrpMem.GroupId = grp.Id;
           GrpMem.UserOrGroupId = UserInfo.getUserId();
           insert grpMem;
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='atrue1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='atrue2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
              new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule1', Scope__c='Group', Scope_Id_Value__c=grp.Id, Availability__c='Unavailable',isActive__c=true)
                                                       //this doens't work ATARC_Process_Setting__r =  testSettings[1])
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule1'=>'atrue1'};                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('atrue2').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for atrue2');

    }
    
    @IsTest static void UnavailableForOnePermissionSetsShouldRunOneProcess(){
        
       PermissionSet ps = new PermissionSet(Name='ATARC_PS_Test_1xx', Label='ATARC_PS_Test_1xx');
       insert ps;
        
       PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId=ps.id);
        insert psa;
                
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='atrue1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='atrue2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
              new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule2', Scope__c='PermissionSet', Scope_Id_Value__c=ps.Id, Availability__c='Unavailable',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule2'=>'atrue2'};                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('atrue1').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for atrue1');

    }
    
    @IsTest static void UnavailableForOneQueueShouldRunOneProcess(){
        
        Group grp = new Group(); 
        grp.Name = 'ATARC_Group_Test1x'; 
        grp.Type = 'Queue'; 
        insert grp;
        
           GroupMember GrpMem = new GroupMember();
           GrpMem.GroupId = grp.Id;
           GrpMem.UserOrGroupId = UserInfo.getUserId();
           insert grpMem;
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='atrue1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='atrue2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
              new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule3', Scope__c='Queue', Scope_Id_Value__c=grp.Id, Availability__c='Unavailable',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule3'=>'atrue1'};                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('atrue2').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for atrue2');

    }
    
    @IsTest static void UnavailableForOneProfileShouldRunOneProcess(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='atrue1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='atrue2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
              new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule4x', Scope__c='Profile', Scope_Id_Value__c=UserInfo.getProfileId(), Availability__c='Unavailable',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule4x'=>'atrue2'};                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('atrue1').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for atrue1');

    }
    
    @IsTest static void UnavailableForOneRoleShouldRunOneProcess(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='atrue1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='atrue2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
              new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule4x1', Scope__c='Role', Scope_Id_Value__c=UserInfo.getUserRoleId(), Availability__c='Unavailable',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule4x1'=>'atrue1'};                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('atrue2').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for atrue2');

    }
    
    @IsTest static void UnavailableForOneUserShouldRunOneProcess(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='atrue1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='atrue2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
              new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule4', Scope__c='User', Scope_Id_Value__c=UserInfo.getUserId(), Availability__c='Unavailable',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule4'=>'atrue2'};                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 2 && totalExecutedProcesses ==1, 'Expected is (totalProcesses 2 totalExecutedProcesses 1) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('atrue1').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for atrue1');

    }
    
    @IsTest static void UnavailableForTwoUsersCustomFilterShouldRunOneProcess(){
        
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='atrue1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='atrue2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true),
                new ATARC_Process_Setting__mdt(DeveloperName='atrue3',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true),
                new ATARC_Process_Setting__mdt(DeveloperName='atrue4',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
             new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule5', Scope__c='User', Custom_Scope_Filter__c=true, Custom_Scope_Filter_Value__c='[{"field":"Name", "value":"'+userinfo.getName()+'","op":"="}]', Availability__c='Unavailable',isActive__c=true),
             new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule6', Scope__c='User', Custom_Scope_Filter__c=true, Custom_Scope_Filter_Value__c='[{"field":"Email", "value":"'+userinfo.getUserEmail()+'", "op":"="}]', Availability__c='Unavailable',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule5'=>'atrue2','rule6'=>'atrue3' };                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 4 && totalExecutedProcesses ==2, 'Expected is (totalProcesses 4 totalExecutedProcesses 2) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('atrue1').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for atrue1');
        system.assert(executionResult.get('atrue4').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for atrue4');

    }
    
    @IsTest static void UnavailableForMoreUsersCustomFilterShouldRunOneProcess(){
        string zs = '';
        for(integer i =0;i<255;i++) zs+='Z';
        List<ATARC_Process_Setting__mdt> testSettings = new List<ATARC_Process_Setting__mdt>{
            new ATARC_Process_Setting__mdt(DeveloperName='atrue1',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=1, isAsync__c=false, General_Availability__c=true, debug__c=true),
            new ATARC_Process_Setting__mdt(DeveloperName='atrue2',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true),
                new ATARC_Process_Setting__mdt(DeveloperName='atrue3',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true),
                new ATARC_Process_Setting__mdt(DeveloperName='atrue4',SObject__c='Opportunity', ApexHelperClassName__c='AsyncTriggerArcTest',
                                           Event__c='BeforeInsert',IsActive__c=true,Order__c=2, isAsync__c=false, breakIfError__c=true, debug__c=true,General_Availability__c=true)
                };
         List<ATARC_Process_Availability_Rule__mdt> allrules = new List<ATARC_Process_Availability_Rule__mdt>{
             new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule5', Scope__c='User', Custom_Scope_Filter__c=true, Custom_Scope_Filter_Value__c='[{"value":"a", "op":"<=", "field":"LastName"},{"value":true, "op":"=", "field":"IsActive" },{ "value":"a", "op":"<","field":"FirstName"}]', Availability__c='Unavailable',isActive__c=true),
                 new ATARC_Process_Availability_Rule__mdt(DeveloperName = 'rule6', Scope__c='User', Custom_Scope_Filter__c=true, Custom_Scope_Filter_Value__c='[{"value":false,"op":"!=","field":"IsActive"}, {"value":"'+zs+'","op":">=","field":"LastName"}, {"value":"'+zs+'","op":">","field":"FirstName"}]', Availability__c='Unavailable',isActive__c=true)
                  };
                    
        Map<string, string> ruleSettingsMapping =new Map<string, string> {'rule5'=>'atrue2','rule6'=>'atrue3' };                    
        AsyncTriggerArc atarc = new AsyncTriggerArc(
            true, //before
            false, //after 
            true, //insert
            false, 
            false,
            false,
            new List<Opportunity>{new opportunity()},
            new List<Opportunity>{new Opportunity()},
            null, 
            null);
        
        AsyncTriggerArc.settings= testSettings;
        AsyncTriggerArc.allrules = allrules;
        AsyncTriggerArc.rulesSettingsMapping = ruleSettingsMapping;
        
        test.startTest();
        atarc.Start();//first run
        test.stoptest();
        
        Map<string,AsyncTriggerArc.AsyncTriggerArcProcessInfo> executionResult= atarc.getProcessesExecutionInformation();
        integer totalProcesses = executionResult.size();
        integer totalExecutedProcesses = 0;
        
        for(AsyncTriggerArc.AsyncTriggerArcProcessInfo p : executionResult.values()){
            totalExecutedProcesses += ( p.status == AsyncTriggerArc.PROCESS_EXECUTED ||  p.status == AsyncTriggerArc.PROCESS_FAILED ? 1 : 0);
        }
        
        
        system.assert(totalProcesses == 4 && totalExecutedProcesses ==2, 'Expected is (totalProcesses 4 totalExecutedProcesses 2) Current is (totalProcesses '+totalProcesses+' totalExecutedProcesses '+totalExecutedProcesses+')');
        system.assert(executionResult.get('atrue1').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for atrue1');
        system.assert(executionResult.get('atrue4').status==AsyncTriggerArc.PROCESS_EXECUTED, 'Expected is Process Executed for atrue4');

    }
    
    
    
}