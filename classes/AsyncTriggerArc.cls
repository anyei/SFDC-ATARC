/*
 * Created By : Angel Robles (anyei)
 * Partners :  Anthony del Rosario
 * Created Date: 1/6/2017
 * Purpose: In a nutshell, runs processes out of a custom setting. The custom setting has a field indicating
 * 			the apex class implementing IAsyncTriggerArc interface which is the code to execute (the process), 
 * 			order of execution, a flag to make it active or not (if not active it will not run), a flag to force it to run
 * 			as queueable, a field to control dependencies (process A is dependent on process B to run, if process B does not run or 
 * 			has an exception in the code process A will not run) and in addition to all that this also has the capability to pass output from one process
 * 			to the next one within the same transaction.  
 *  
 * Test Classes: AsyncTriggerArcTest
 */ 
public class AsyncTriggerArc {
    
    
    /*********/
     //Static Variables
     /******/ 
    //statuses tokens
    public static final string PROCESS_EXECUTED = 'Executed';
    public static final string PROCESS_FAILED = 'Failed';
    
    //global maps, lists, config
    @TestVisible static Map<string,Map<string, map<string, AsyncTriggerArqSettings__c[]>>> arqSettings;    
    
    @TestVisible static AsyncTriggerArcConfig globalConfig;    
    
    static boolean orderProcessed;
    
    /****************/
    // INSTACE VARIABLES
    /****************/
    string sObjectName;
    string triggerName;
    string triggerEventTxt;
    
    //load initial config
    static{
        
        arqSettings = new Map<string,Map<string, Map<string, AsyncTriggerArqSettings__c[]>>>();        
        
        globalConfig = new AsyncTriggerArcConfig();
        
        orderProcessed = false;
        
    }
    

    /*
     * @method
     * Process the order of the items retrieve from the config settings
     */ 
    @TestVisible static void processOrder(boolean firstTime){
        Map<string,Map<string,Map<string, List<integer>>>> orderLogic = new Map<string,Map<string,Map<string, List<integer>>>>();
        
        for(AsyncTriggerArqSettings__c setting : AsyncTriggerArqSettings__c.GetAll().values()){
            
            if(setting.IsActive__c && !globalConfig.processToSkip.contains(setting.name) && !globalConfig.objectToSkip.contains(setting.SObject__c)){
                
                //order logic.. as we dont have soql we must order by our self
                if(!orderLogic.containsKey(setting.SObject__c))
                    orderLogic.put(setting.SObject__c, new Map<string,Map<string, List<integer>>>());
                
                if(!orderLogic.get(setting.SObject__c).containsKey(setting.ApexTriggerName__c))
                    orderLogic.get(setting.SObject__c).put(setting.ApexTriggerName__c, new Map<string, List<integer>>());
                
                if(!orderLogic.get(setting.SObject__c).get(setting.ApexTriggerName__c).containsKey(setting.Event__c))
                    orderLogic.get(setting.SObject__c).get(setting.ApexTriggerName__c).put(setting.Event__c, new List<integer>());
                
                orderLogic.get(setting.SObject__c).get(setting.ApexTriggerName__c).get(setting.Event__c).add(integer.valueof(setting.order__c));
                
            }
            
        }
        
        
        for(AsyncTriggerArqSettings__c setting : AsyncTriggerArqSettings__c.GetAll().values()){
            if(setting.IsActive__c && !globalConfig.processToSkip.contains(setting.name) && !globalConfig.objectToSkip.contains(setting.SObject__c)){
                
                if(firstTime)
                	globalConfig.ItemDetails.put(setting.name, new AsyncTriggerArcProcessInfo() );
                
                orderLogic.get(setting.SObject__c).get(setting.ApexTriggerName__c).get(setting.Event__c).sort();
                List<integer> orderOfProcess = orderLogic.get(setting.SObject__c).get(setting.ApexTriggerName__c).get(setting.Event__c);
                
                if(!arqSettings.containsKey(setting.SObject__c))
                    arqSettings.put(setting.SObject__c, new Map<string,Map<string, AsyncTriggerArqSettings__c[]>>() );
                
                if(!arqSettings.get(setting.SObject__c).containsKey(setting.ApexTriggerName__c))
                    arqSettings.get(setting.SObject__c).put(setting.ApexTriggerName__c, new Map<string, AsyncTriggerArqSettings__c[] >());
                
                if(!arqSettings.get(setting.SObject__c).get(setting.ApexTriggerName__c).containsKey(setting.Event__c))
                    arqSettings.get(setting.SObject__c).get(setting.ApexTriggerName__c).put(setting.Event__c, new AsyncTriggerArqSettings__c[orderOfProcess.size()] );
                
                for(integer i =0;i< orderOfProcess.size(); i++){
                    
                    if(orderOfProcess[i] == integer.valueof(setting.order__c))
                    {                        
                        arqSettings.get(setting.SObject__c).get(setting.ApexTriggerName__c).get(setting.Event__c).set(i, setting);
                        
                    }
                }
                
            }
            
            
            
        }
        
        orderProcessed = true;
    }    
    
    
    /*
     * @constructor 1
     * 
     */
    public AsyncTriggerArc(string sObjectName, string triggerName, boolean isBefore, boolean isAfter, boolean isInsert, boolean isUpdate, boolean isDelete, List<SOBject> newList, List<SObject> oldList,Map<Id, SObject> newMap, Map<id,SObject> oldMap){
        
        if(String.isEmpty(sObjectName) || String.isEmpty(triggerName))
            throw new AsyncTriggerArcException('sObject Name or trigger Name is must be provided');
        
        this.sObjectName = sObjectName;
        this.triggerName = triggerName;
        
        globalConfig.triggerContext.oldList = oldList;
        globalConfig.triggerContext.newList = newList;
        globalConfig.triggerContext.oldMap = oldmap;
        globalConfig.triggerContext.newMap = newMap;
        
        //the chain of process to execute should be reset every time 
        //a trigger is executed
        globalConfig.Chain = new List<AsyncTriggerArqSettings__c>();
        
        
        triggerEventTxt = ( (globalConfig.triggerContext.isBefore = isBefore) ? 'Before' : '') + ( (globalConfig.triggerContext.isAfter = isAfter) ? 'After' : '') +
            ( (globalConfig.triggerContext.IsInsert = isInsert) ? 'Insert' : '') + ( (globalConfig.triggerContext.isUpdate = isUpdate) ? 'Update' : '')+ 
            ( (globalConfig.triggerContext.isDelete = isDelete) ? 'Delete' : '');
        
    }
    
    /*
     * @constructor 2
     * 
     */
    public AsyncTriggerArc(string triggerName, boolean isBefore, boolean isAfter, boolean isInsert, boolean isUpdate, boolean isDelete, List<SOBject> newList, List<SObject> oldList,Map<Id, SObject> newMap, Map<id,SObject> oldMap){
       
        this( newList[0].getSObjectType().getDescribe().getName(),
            triggerName,
            isBefore,
            isAfter,
            isInsert,
            isUpdate,
            isDelete,
            newList,
            oldList,
            newMap,
            oldMap);
         }
    
    public Map<string,AsyncTriggerArcProcessInfo> getProcessesExecutionInformation(){
        Map<string,AsyncTriggerArcProcessInfo> result= new Map<string,AsyncTriggerArcProcessInfo>();
        result.putall(globalConfig.ItemDetails);
        return result;
    }
    /*
     * @method
     * ADDSKIP
     */ 
    public AsyncTriggerArc AddProcessSkip(string processName){
        globalConfig.processToSkip.add(processName);        
        return this;
	}
    
    public AsyncTriggerArc AddSObjectSkip(string SObjectName){
        globalConfig.objectToSkip.add(SObjectName);
        return this;
    }
    
    /*
     * @method
     * REMOVESKIP
     */ 
    public AsyncTriggerArc removeProcessSkip(string processName){
        if(globalConfig.processToSkip.contains(processName))
            globalConfig.processToSkip.remove(processName);        
        return this;
    }
    
    public AsyncTriggerArc removeObjectSkip(string SObjectName){
        if(globalConfig.objectToSkip.contains(SObjectName))
            globalConfig.objectToSkip.remove(SObjectName);
        
        return this;
    }
    
    /*
     * @method
     * START
     */  
    public void Start(){
        
		if(!orderProcessed)        
            processOrder(true);
        
        if(arqSettings.containsKey(sObjectName) 
           && arqSettings.get(sObjectName).containsKey(triggerName)
           && arqSettings.get(SObjectName).get(triggerName).containsKey(triggerEventTxt)
          ){
              for(AsyncTriggerArqSettings__c setting : arqSettings.get(sObjectName).get(triggerName).get(triggerEventTxt)){                    
                  globalConfig.Chain.add(setting);                    
              } 
              
              Eval(globalConfig, false);
          }
    }
    
    
    /*******************************/
    //@method
    //Eval
    /*****************************/
    static void Eval(AsyncTriggerArcConfig config, boolean fromAsync){
        //processes chaning logic
        while(config.chain.size() > 0){
            
            
            //"doing pop", returning and removing the next process to evaluate and execute
            //this is key to get rid of the processed processes from the queue
            AsyncTriggerArqSettings__c setting = config.chain.remove(0);
            
            //simple skip functionality
            if(config.processToSkip.contains(setting.name) || config.objectToSkip.contains(setting.SObject__c)) break;
            
            boolean breakTransaction = false;
            system.debug(setting.ApexHelperClassName__c);
            if(setting != null){                          
                
                if(String.isNotEmpty(setting.DependsOn__c) 
                   && config.ItemDetails.containsKeY(setting.DependsOn__c) 
                   && config.ItemDetails.get(setting.DependsOn__c).status == PROCESS_EXECUTED){
                       
                       //processes with dependencies should execute only if dependency process executed successfully
                       breakTransaction = Run(config, setting, fromAsync);
                       
                   }else if(String.isNotEmpty(setting.DependsOnError__c) 
                   && config.ItemDetails.containsKeY(setting.DependsOnError__c) 
                   && config.ItemDetails.get(setting.DependsOnError__c).status == PROCESS_FAILED){
                       
                       //processes with dependencies should execute only if dependency process executed successfully
                       breakTransaction = Run(config, setting, fromAsync);
                       
                   }else if(String.isBlank(setting.DependsOn__c) && String.isBlank(setting.DependsOnError__c))
                   {   
                       //processes with no dependencies should run
                       breakTransaction = Run(config,setting, fromAsync);
                       
                   }else if(config.Chain.size() > 0){
                       
                       //processes with dependencies but dependency didn't executed successfully should be skipped
                       //the next process in the list should be executed
                       continue;
                   }
                
            }else //no more process to execute, setting shoudl be null hence loop should break{
            {
                break;
            }
            
            //async transactions invokations should break this loop
            if(breakTransaction){                
                break;
            }
        }
    }
     
    
    
    /**********************************/
    //@method
    //RUN
    /**************************************/
    static boolean Run(AsyncTriggerArcConfig config, AsyncTriggerArqSettings__c setting, boolean fromAsync){         
        
        boolean isAsync = false;
        
        if(setting.isAsync__c){
            system.debug(setting.ApexHelperClassName__c + ' from async ' + setting.Name);
            //async processes should break the upper loop
            //so that only one active process thread is working            
            AsyncTriggerArcQueueable asyncWorker = new AsyncTriggerArcQueueable(config, setting);
            system.enqueueJob(asyncWorker);
            isAsync = true;
        }else if(fromAsync && !Test.isRunningTest()){
           system.debug('helper class synchronous from async '+setting.Name);
            //queuable to start a fresh transaction when a synchronous transactions needs to run after
            //an async transaction
            AsyncTriggerArcSynchronousProcess asyncWorker = new AsyncTriggerArcSynchronousProcess(config, setting);
            system.enqueueJob(asyncWorker);
            isAsync = true;
        }else{
            
            //after class is executed then get the output if any
            //after preparing data for the triggerContext upper loop should run the next process in line.
            object output =  RunClass(config, setting);
            
            config.triggerContext.customData.put(setting.Name,output);                         
            
        }
        
        return isAsync;
    }
    
    
    /********************************/
    //@method
    //RUNCLASS
    /********************************/
    static Object RunClass(AsyncTriggerArcConfig config, AsyncTriggerArqSettings__c setting){
        
        Type t = null;
        IAsyncTriggerArc instance = null;
        Object output = null;
        
        config.triggerContext.processName = setting.name;
        
        try{
            t = Type.forName(setting.ApexHelperClassName__c);
        }catch(Exception err){
            if(setting.BreakIfError__c)
                throw err;
        }
        
        if(t != null){
            try{
                instance =(IAsyncTriggerArc)t.newInstance();
            }catch(Exception err){
                if(setting.BreakIfError__c)
                throw err;
                
            }
        }        
        
        long startTime = system.datetime.now().millisecond();
        
        try{
            
            if(instance == null)
                throw new AsyncTriggerArcException('Not able to instantiate Apex Class '+setting.ApexHelperClassName__c);
            
            output = instance.execute(config.triggerContext);
            long totalTime = system.datetime.now().millisecond() - startTime;
                
            UpdateStatus(config, setting, (config.triggerContext.processSucceeded == true ? PROCESS_EXECUTED : PROCESS_FAILED )  );
            
            UpdateProcessTime(config, setting, totalTime);
        }catch(Exception err){  
            
            long totalTime = system.datetime.now().millisecond() - startTime;
            
            UpdateStatus(config, setting, PROCESS_FAILED);
            UpdateProcessTime(config, setting, totalTime);
            
            if(setting.BreakIfError__c)
                throw err;
        }
        
        return output;
        
    }
    
    /*
* Updates the status of the configuration
*/
    static void UpdateStatus(AsyncTriggerArcConfig config, AsyncTriggerArqSettings__c setting, string status){        
        config.ItemDetails.get(setting.Name).status = status;
    }
    
    static void UpdateProcessTime(AsyncTriggerArcConfig config, AsyncTriggerArqSettings__c setting, long totalTime){         
        config.ItemDetails.get(setting.Name).processTime = totalTime;
    }
    
    /************************************************/
    //INNER CLASSES
    /***********************************************/
    
    public class AsyncTriggerArcProcessInfo{
        public string status{get;set;}
        public decimal processTime {get;set;}
    }
    
    public class AsyncTriggerArcConfig{
        
        public List<AsyncTriggerArqSettings__c> Chain {get;set;}
        public Map<string,AsyncTriggerArcProcessInfo> ItemDetails {get;set;}
        public AsyncTriggerArcContext triggerContext{get;set;}
        public set<string> processToSkip {get;set;}        
        public set<string> objectToSkip {get;set;}        
        public AsyncTriggerArcConfig(){
             ItemDetails = new Map<string,AsyncTriggerArcProcessInfo>();        
             triggerContext = new AsyncTriggerArcContext();             
             processToSkip = new set<string>();
            objectToSkip = new set<string>();
            
        }
        
    }
    
    
    /*
* Wrapper class
* Holds apex trigger context data
*/
    public class AsyncTriggerArcContext {
        public boolean isBefore {get;set;}
        public boolean isAfter  {get;set;}
        public boolean isUpdate  {get;set;}
        public boolean isDelete  {get;set;}
        public boolean isInsert  {get;set;}        
        public List<SObject> newList{get;set;}
        public List<SObject> oldList {get;set;}
        public Map<id, SObject> oldMap  {get;set;}
        public Map<id, SObject> newMap  {get;set;}
        
        protected string processName;
        protected boolean processSucceeded = true;
        protected Map<string,object> CustomData {get;set;}
        public AsyncTriggerArcContext(){
            customData = new Map<string,object>();
        }
        
        public object getProcessData(string processName){
            return (customData.containsKey(processName) ? customData.get(processName) : null);
        }
        public string getCurrentProcessName(){
            return processName;
        }
        
        public void setFailed(){
            processSucceeded = false;
        }
        
        public string getProcessStatus(string processName){
            return globalConfig.itemDetails.containsKey(processName) ? globalConfig.itemDetails.get(processName).status : null;
        }
    }
    
    
    /*
* Queueable class 
* Runs when async is needed
*/
    public class AsyncTriggerArcQueueable implements Queueable{
        public AsyncTriggerArcConfig Config {get;set;}
        public AsyncTriggerArqSettings__c currentSetting {get;set;}
        public AsyncTriggerArcQueueable(AsyncTriggerArcConfig conf, AsyncTriggerArqSettings__c setting){
            Config = conf;
            currentSetting = setting;
        }
        public void execute(QueueableContext context){
            
            //to fix specific issue
            //globalConfig is empty when queueable is executed
            //
            //Also in the unit test when the starttest and stoptest happen
            //every async jobs or processes are treated as synchronous
            //but a new transaction is created anyway
            //globalConfig will be empty by that time 
            //assigning the config to the globalConfig will allow unit test context
            //to have the config data
            globalConfig = config;
            
            //run the class of the current setting
            object output =  RunClass(config, currentSetting);
            
            //store the output of the current invocation
            config.triggerContext.customData.put(currentSetting.Name,output);
            
            
            //chain operations
            //call the next operation according to the order.
            Eval(config, true);
            
        }
        
    }
    
    
    
    
    /*
     * Queueable to run when synchronous execution follow an async execution
     * note: because of how apex test engine works, this queuable is not executed
     * from unit testing (test engine does not like to run two queueable jobs in chain)
     */ 
    public class AsyncTriggerArcSynchronousProcess implements Queueable{
        public AsyncTriggerArcConfig Config {get;set;}
        
        public AsyncTriggerArqSettings__c currentSetting {get;set;}
        public AsyncTriggerArcSynchronousProcess(AsyncTriggerArcConfig conf, AsyncTriggerArqSettings__c setting){
            Config = conf;
            currentSetting = setting;
        }
        public void execute(QueueableContext context){
            
            //to fix specific issue
            //globalConfig is empty when queueable is executed
            //
            //Also in the unit test when the starttest and stoptest happen
            //every async jobs or processes are treated as synchronous
            //but a new transaction is created anyway
            //globalConfig will be empty by that time 
            //assigning the config to the globalConfig will allow unit test context
            //to have the config data
            globalConfig = config;
            
            //run the class of the current setting
            object output =  RunClass(config, currentSetting);
            
            //store the output of the current invocation
            config.triggerContext.customData.put(currentSetting.Name,output);
           
            
            //chain operations
            //call the next operation according to the order.
            Eval(config, false);
            
        }
        
    }
      
    
    /*
* General Interface
* Helper classes shall implement this interface
*/ 
    public interface IAsyncTriggerArc {
        
        object execute(AsyncTriggerArcContext triggerContext);
    }
    
    public class AsyncTriggerArcException extends Exception{}
    
}