/*
* Created By : Angel Robles (anyei)
* Created Date: 1/6/2017
* GitHub: https://github.com/anyei/SFDC-ATARC
* Purpose: In a nutshell, runs processes out of a custom setting. The custom setting has a field indicating
*           the apex class implementing AsyncTriggerArcProcessBase or AsyncTriggerArcProcessFEABAse base class which is the code to execute (the process), 
*           order of execution, a flag to make it active or not (if not active it will not run), a flag to force it to run
*           as queueable, a field to control dependencies (process A is dependent on process B to run, if process B does not run or 
*           has an exception in the code process A will not run) and in addition to all that this also has the capability to pass output from one process
*           to the next one within the same transaction.  
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
    
    //possible values listed here NONE, ERROR, WARN, INFO, DEBUG,
    //FINE, FINER, FINEST
    public static final string DEFAULT_LOGGIN_LEVEL =  'DEBUG';
    public static final string CATEGORY_SKIP = 'category';
    public static final string OBJECT_SKIP = 'object';
    public static final string EVENT_SKIP = 'event';
    public static final string PROCESS_SKIP = 'process';
    public static final string FRAMEWORK_NAME = 'ATARC';
    public static final integer GOVERNOR_LIMITS_QUEUEABLE = System.Limits.getLimitQueueableJobs();
    
    //global maps, lists, config
    @TestVisible static Map < string, map < string, List<ATARC_Process_Setting__mdt> >> arqSettings;
    
    //must be an instance variable
    //this is the state of engine instance    
    @TestVisible AsyncTriggerArcConfig globalConfig;

    //Salesforce has a weird suggestion on how to test custom metadata type related code
    //I think this is a better solution, this field should be populated by the unit test
    //It will be populated by the real code at runtime.
	@TestVisible List < ATARC_Process_Setting__mdt > settings;    
   
    @testVisible static Map < string, set < string > > skips;
    
    @TestVisible static Map < string, AsyncTriggerArcProcessInfo > processesExecStatuses;
    
    @testVisible static Map < string, object > customData;
    
    @TestVisible static Map < string, Map < string, integer >> triggerExecTrack;
    
    @TestVisible static Map < string, System.LoggingLevel > logginLevelMap;

    @TestVisible static List< AsyncTriggerArcDebugStackSetting > processesStack;
    
    static boolean orderProcessed;
    static boolean runningAsyncContext;
    public static boolean globalSkip;
    public static integer globalTransactionLoop;
    public static boolean globalDebugMode = true;
    
    
    /****************/
    // INSTACE VARIABLES
    /****************/
    string sObjectName;
    string triggerName;
    string triggerEventTxt;
    
    //load initial config
    static {
        customData = new Map < string, object > ();
        
        arqSettings = new Map < string, Map < string, List<ATARC_Process_Setting__mdt> >> ();
        
        triggerExecTrack = new Map < string, Map < string, integer >> ();
        
        processesExecStatuses = new Map < string, AsyncTriggerArcProcessInfo > ();

        processesStack = new List< AsyncTriggerArcDebugStackSetting > ();
        
        logginLevelMap = new Map < string, System.LoggingLevel > {
            'NONE' => LoggingLevel.NONE,
                'ERROR' => LoggingLevel.ERROR,
                'WARN' => LoggingLevel.WARN,
                'INFO' => LoggingLevel.INFO,
                'DEBUG' => LoggingLevel.DEBUG,
                'FINE' => LoggingLevel.FINE,
                'FINER' => LoggingLevel.FINER,
                'FINEST' => LoggingLevel.FINEST
                
                };
         skips = new Map < string, set < string >> {
                CATEGORY_SKIP => new set < string > (),
                    OBJECT_SKIP => new set < string > (),
                    EVENT_SKIP => new set < string > (),
                    PROCESS_SKIP => new set < string > ()
                    };
                    
                    orderProcessed = false;
        
        globalSkip = false;
        ATARC_Global_Setting__c globalConfigSetting = ATARC_Global_Setting__c.getInstance();
        if(globalConfigSetting != null)  {
            globalSkip = globalConfigSetting.SkipAll__c;
            globalDebugMode = globalConfigSetting.Debug__c;
            globalTransactionLoop = Integer.valueof(globalConfigSetting.LoopLimit__c);
        }
                
        
        runningAsyncContext = false;
        
    }
    
    static AsyncTriggerArcQueueable RequestQueuable() {
        
        AsyncTriggerArcQueueable newInstance = null;
        
        if (Limits.getQueueableJobs() < GOVERNOR_LIMITS_QUEUEABLE) {
            newInstance = new AsyncTriggerArcQueueable();
        }
        return newInstance;
    }
    
    @TestVisible static boolean canSkip(boolean gskip, ATARC_Process_Setting__mdt setting) {
        boolean skip = false;
        
        for (string skipType: skips.keyset()) {
            if (skipType == CATEGORY_SKIP)
                if (skip = skips.get(skipType).contains(setting.Category__c)) break;
            if (skipType == OBJECT_SKIP)
                if (skip = skips.get(skipType).contains(setting.SObject__c)) break;
            if (skipType == EVENT_SKIP)
                if (skip = skips.get(skipType).contains(setting.Event__c)) break;
            if (skipType == PROCESS_SKIP)
                if (skip = skips.get(skipType).contains(setting.DeveloperName)) break;
            
        }
        return skip || gskip;
    }
    
    
    /*
    * @method
    * Process the order of the items retrieve from the config settings
    */
    @TestVisible void processOrder(boolean firstTime) {
        
        if (orderProcessed != true) {
            
            Map < string, Map < string, List < integer >>> orderLogicA = new Map < string, Map < string, List < integer >>> ();
            Map < string, Map < string, List < integer >>> orderLogicS = new Map < string, Map < string, List < integer >>> ();
            
            settings = settings == null ? [select DeveloperName , MasterLabel, ApexHelperClassName__c , BreakIfError__c , Category__c , Debug__c , Debug_Level__c , DependsOnFailure__c , DependsOnSuccess__c , Event__c , IsActive__c , IsAsync__c , Order__c , SObject__c, isolate__c from ATARC_Process_Setting__mdt where isActive__c = true
order by SObject__c, Event__c,Order__c,isAsync__c asc] : settings;//AsyncTriggerArqSettings__c.GetAll().values();
            
            for (ATARC_Process_Setting__mdt setting: settings) {
                if (setting.IsActive__c && !canSkip(globalSkip, setting)) {
                    
                    if (!processesExecStatuses.containsKey(setting.DeveloperName))
                        processesExecStatuses.put(setting.DeveloperName, new AsyncTriggerArcProcessInfo());
                    
                    if (!arqSettings.containsKey(setting.SObject__c))
                        arqSettings.put(setting.SObject__c, new Map < string, List<ATARC_Process_Setting__mdt> > ());
                    
                    if (!arqSettings.get(setting.SObject__c).containsKey(setting.Event__c))
                        arqSettings.get(setting.SObject__c).put(setting.Event__c, new List<ATARC_Process_Setting__mdt>());
                    
                    arqSettings.get(setting.SObject__c).get(setting.Event__c).add(setting);
                    
                }
                
                
                
            }
            
            atarcDebug('Config loaded\n' + settings.size());
        }
        
        
        
        
        orderProcessed = true;
    }
    
    /*
    * @method
    * Calls the static debug method
    */
    static void atarcDebug(object msg) {
        debug(FRAMEWORK_NAME, globalDebugMode, 'INFO', (msg != null) ? string.valueof(msg) : '');
    }
    
    /*
    * @method
    * Specific debug detailed method, calls the system.debug function.
    */
    static void debug(string prefix, boolean debugMode, string lvl, string msg) {
        if (debugMode == true) system.debug((logginLevelMap.containsKey(lvl) ? logginLevelMap.get(lvl) : logginLevelMap.get(DEFAULT_LOGGIN_LEVEL)), prefix + ': ' + msg);
    }

    /*
    * @method
    * To be used by outside helpers, this way if you try to print something in the debug output
    * it will depend on the specific current atarc process debug mode flag
    */
    public static void debug(object msg){
        if(!processesStack.isEmpty()){
            AsyncTriggerArcDebugStackSetting currentProcessDebugInfo= processesStack[processesStack.size() - 1];
            debug(currentProcessDebugInfo.name,currentProcessDebugInfo.debugMode,currentProcessDebugInfo.lvl, string.valueof(msg) );
        }
    }
    
    /*
    * @constructor 1
    * 
    */
    public AsyncTriggerArc(string sObjectName, boolean isBefore, boolean isAfter, boolean isInsert, boolean isUpdate, boolean isDelete, boolean isUndelete, List < SOBject > newList, List < SObject > oldList, Map < Id, SObject > newMap, Map < id, SObject > oldMap) {
        
        if (String.isEmpty(sObjectName))
            throw new AsyncTriggerArcException('sObject Name must be provided!!');
        
        globalConfig = new AsyncTriggerArcConfig();
        
        this.sObjectName = sObjectName;
        this.triggerName = triggerName;
        
        globalConfig.triggerContext.oldList = oldList;
        globalConfig.triggerContext.newList = newList;
        globalConfig.triggerContext.oldMap = oldmap;
        globalConfig.triggerContext.newMap = newMap;
        globalConfig.triggerContext.transactionLoop = globalTransactionLoop;
        globalConfig.skipEverything = globalSkip;
              
        //the chain of process to execute should be reset every time 
        //a trigger is executed
        globalConfig.Chain = new List < ATARC_Process_Setting__mdt > ();
        
        
        triggerEventTxt = ((globalConfig.triggerContext.isBefore = isBefore) ? 'Before' : '') + ((globalConfig.triggerContext.isAfter = isAfter) ? 'After' : '') +
            ((globalConfig.triggerContext.IsInsert = isInsert) ? 'Insert' : '') + ((globalConfig.triggerContext.isUpdate = isUpdate) ? 'Update' : '') +
            ((globalConfig.triggerContext.isDelete = isDelete) ? 'Delete' : '');
        triggerEventTxt = ((globalConfig.triggerContext.isUndelete = isUndelete) && globalConfig.triggerContext.isAfter ? '' : (globalConfig.triggerContext.isUndelete == true ? 'BeforeUndelete' : triggerEventTxt));
    }
    
    /*
    * @constructor 2
    * 
    */
    public AsyncTriggerArc(boolean isBefore, boolean isAfter, boolean isInsert, boolean isUpdate, boolean isDelete, boolean isUndelete, List < SOBject > newList, List < SObject > oldList, Map < Id, SObject > newMap, Map < id, SObject > oldMap) {
        
        this(((isDelete == true || isUndelete == true) && oldList.size() > 0 ? oldList[0].getSObjectType().getDescribe().getName() : (newlist.size() > 0) ? newList[0].getSObjectType().getDescribe().getName() : null),
             isBefore,
             isAfter,
             isInsert,
             isUpdate,
             isDelete,
             isUndelete,
             newList,
             oldList,
             newMap,
             oldMap);
    }
    
    
    /*
    * @method
    * GetProcessesExecutionInformation
    */
    public Map < string, AsyncTriggerArcProcessInfo > getProcessesExecutionInformation() {
        Map < string, AsyncTriggerArcProcessInfo > result = new Map < string, AsyncTriggerArcProcessInfo > ();
        result.putall(processesExecStatuses);
        return result;
    }
    
    
    /*
    * @method
    * START
    */
    public void Start() {
        
        atarcDebug('Start\nTransaction loop tracking:' + getTriggerTrack() +
                   '\nSOBject:' + sObjectName +
                   '\nEvent:' + triggerEventTxt +
                   '\nRunningOutOfAnAsyncProcess:' + runningAsyncContext +
                   '\nglobalSkip:' + globalSkip +
                   '\nglobalTransactionLoop:' + globalTransactionLoop +
                   '\nglobalDebugMode:' + globalDebugMode  );
        
        
        /*********************************/
        //order features by order field        
        if (!orderProcessed)
            processOrder(true);
        /*********************************/
        
        if (arqSettings.containsKey(sObjectName) &&
            arqSettings.get(SObjectName).containsKey(triggerEventTxt)
           ) {
               
               /********************************/
               //propagation cancelation feature
               
               if (globalConfig.triggerContext.transactionLoop == null || getTriggerTrack() >= globalConfig.triggerContext.transactionLoop || globalConfig.triggerContext.transactionLoop == 0) {
                   atarcDebug('TRANSACTION LOOP REACHED '+globalConfig.triggerContext.transactionLoop);
                   return;
               }
               
               updateTriggerTrack();
               /*********************************/
               
               List < ATARC_Process_Setting__mdt > settings = arqSettings.get(sObjectName).get(triggerEventTxt);
               
               atarcDebug('Event match found:' + triggerEventTxt + '\nTotal processes:' + settings.size());
               
               for (ATARC_Process_Setting__mdt setting: settings) {
                   globalConfig.Chain.add(setting);
                   atarcDebug(setting.DeveloperName);
               }
               
               Eval(globalConfig, null, null);
           }
        
        

        //finishing up the execution of the current ATARC instance
        //cleaning up
        Finish();

    }


    /*
    * @method
    * Completes the execution of the ATARC instance currently running
    * usually happens when the execution of all the atarc processes found for a specific trigger/event have been completed
    */
    void Finish(){
        atarcDebug('Exit Start\nTransaction loop tracking:' + getTriggerTrack() +
                   '\nSOBject:' + sObjectName +
                   '\nEvent:' + triggerEventTxt +
                   '\nRunningOutOfAnAsyncProcess:' + runningAsyncContext +
                   '\nglobalSkip:' + globalSkip +
                   '\nglobalTransactionLoop:' + globalTransactionLoop +
                   '\nglobalDebugMode:' + globalDebugMode );
    }
    
    /*
    * @method
    * Generate instances of the apex classes listed in the custom settings. 
    */
    static map < string, AsyncTriggerArcProcessBase > getInstances(AsyncTriggerArcConfig config) {
        map < string, AsyncTriggerArcProcessBase > instances = new Map < string, AsyncTriggerArcProcessBase > ();
        
        atarcDebug('Generating instances..getInstances');
        for (ATARC_Process_Setting__mdt setting: config.chain) {
            //instantiate the objects
            //and invoke the filter method
            
            
            /**********************************/
            //simple skip functionality
            if (canSkip(config.skipEverything, setting)) {
                atarcDebug('BYPASS FOUND getInstances '+setting.DeveloperName);
                continue;
            }
            /***********************************/
            object o = RequestInstance(setting.ApexHelperClassName__c, setting.BreakIfError__c);
            AsyncTriggerArcProcessBase instance = (o instanceof AsyncTriggerArcProcessBase ) ?  (AsyncTriggerArcProcessBase) o : null; 
            if (instance != null)
                instances.put(setting.DeveloperName, instance);
        }
        
        return instances;
    }
    
    /*
    * @method
    * Generate instances of the apex classes listed in the custom settings.
    */
    static map < string, AsyncTriggerArcFEAProcessBase > getFEAInstances(AsyncTriggerArcConfig config, set<string> standardInterface) {
        map < string, AsyncTriggerArcFEAProcessBase > instances = new Map < string, AsyncTriggerArcFEAProcessBase > ();
        
        atarcDebug('Generating instances..getFEAInstances');
        for (ATARC_Process_Setting__mdt setting: config.chain) {
            //instantiate the objects
            //and invoke the filter method
            
            /**********************************/
            //simple skip functionality
            if (canSkip(config.skipEverything, setting)) {
                atarcDebug('BYPASS FOUND getFEAInstances '+setting.DeveloperName);
                continue;
            }
            /***********************************/
            if(standardInterface.contains(setting.DeveloperName)){
                continue;
            }
            object o = RequestInstance(setting.ApexHelperClassName__c, setting.BreakIfError__c);
            AsyncTriggerArcFEAProcessBase instance = (o instanceof AsyncTriggerArcFEAProcessBase) ? (AsyncTriggerArcFEAProcessBase)o: null;
            
            if (instance != null)
                instances.put(setting.DeveloperName, instance);
        }
        
        return instances;
    }
    
    /**/
    static void pushToProcessStack(ATARC_Process_Setting__mdt setting){
        AsyncTriggerArcDebugStackSetting debuggingInfo = new AsyncTriggerArcDebugStackSetting();
        debuggingInfo.debugMode = setting.debug__c;
        debuggingInfo.lvl = setting.debug_Level__c;
        debuggingInfo.name = setting.DeveloperName;
        processesStack.add(debuggingInfo);
    }
    
    /*
    * @method
    * Implementation of the action step in the fea pattern
    */
    static void runActionPattern(AsyncTriggerArcConfig config, boolean fromAsync, boolean breakTransaction, boolean deletionContext, map < string, AsyncTriggerArcFEAProcessBase > feaInstances, List < ATARC_Process_Setting__mdt > chain) {
        if (breakTransaction != true) {
            atarcDebug('Running ACTION Pattern');
            if(feaInstances.size() == 0 ) atarcDebug('No fea instances found, action pattern will not run ');
            
            if(feaInstances.size() > 0){
                
                long startTime = system.datetime.now().millisecond();
                atarcDebug('Pending actions to run '+chain.size());
                
                for (integer i =0;i<(deletionContext == true ? config.triggerContext.oldList.size() : config.triggerContext.newList.size());i++) {
                    SObject record = (deletionContext == true ? config.triggerContext.oldList[i] : config.triggerContext.newList[i]);
                    for (ATARC_Process_Setting__mdt setting: chain) {
                        
                         /**********************************/
                        //simple skip functionality
                        if (canSkip(config.skipEverything, setting)) {
                            atarcDebug('BYPASS FOUND getFEAInstances '+setting.DeveloperName);
                            continue;
                        }
                                    
                        if (feaInstances.containsKey(setting.DeveloperName)) {
                            AsyncTriggerArcFEAProcessBase feaInstance = feaInstances.get(setting.Developername);
                            
                            
                            //configuring
                            config.triggerContext.debugMode = setting.debug__c;
                            config.triggerContext.debugLevel = setting.debug_Level__c;
                            config.triggerContext.processName = setting.DeveloperName;

                            pushToProcessStack(setting);
                            boolean noError = true;
                            
                            //invoking the "action" method
                            try {
                                
                                if( (String.isNotEmpty(setting.DependsOnSuccess__c) && processesExecStatuses.containsKeY(setting.DependsOnSuccess__c) &&  processesExecStatuses.get(setting.DependsOnSuccess__c).status == PROCESS_EXECUTED ) ||
                                    (String.isNotEmpty(setting.DependsOnFailure__c ) && processesExecStatuses.containsKeY(setting.DependsOnFailure__c ) && processesExecStatuses.get(setting.DependsOnFailure__c ).status == PROCESS_FAILED ) ||
                                    (String.isBlank(setting.DependsOnSuccess__c) && String.isBlank(setting.DependsOnFailure__c ) )
                                  )
                                {
                                       
                                       feaInstance.action((deletionContext != true ?  config.triggerContext.oldList[i] : record),(deletionContext != true ? record : null), config.triggerContext);
                                       
                                       long totalTime = system.datetime.now().millisecond() - startTime;
                                       
                                       UpdateStatusSuccess(setting.DeveloperName);
                                       
                                       UpdateProcessTime(setting.DeveloperName, totalTime);
                                       
                                   } 
                                
                            } catch (Exception err) {
                                
                                long totalTime = system.datetime.now().millisecond() - startTime;
                                
                                UpdateStatusFailed(setting.DeveloperName);
                                UpdateProcessTime(setting.DeveloperName, totalTime);
                                
                                atarcDebug('EXCEPTION!!:\n' + err.getMessage());
                                processesStack.remove(processesStack.size() - 1);
                                noError = false;
                                /**********************************/
                                //break transaction if error feature
                                if (setting.BreakIfError__c) {
                                    atarcDebug('breaking transaction');
                                    throw err;
                                }
                            }
                            
                            if(noError) processesStack.remove(processesStack.size() -1);
                            
                        }
                        
                        //if this is running from async context
                        //break
                        if(setting.isAsync__c)
                            break;
                    }
                }
            }
            
            atarcDebug('Running ACTION Pattern COMPLETE');
        }
    }
    
    /*
    * @method
    * Implementation of the filter step in the fea pattern
    */
    static void runFilterPattern(AsyncTriggerArcConfig config, boolean deletionContext, map < string, AsyncTriggerArcFEAProcessBase > feaInstances, List < ATARC_Process_Setting__mdt > chain, boolean fromAsync) {
        atarcDebug('Running first loop for FILTER pattern ');
        
        if(feaInstances.size() == 0) atarcDebug('No fea instances found, filter pattern will not run');
        
        //shall not run even a single line of code if no fea instances
        if(feaInstances.size() > 0){
            
            long startTime = system.datetime.now().millisecond();
            
            for ( integer i = 0;i< (deletionContext == true ? config.triggerContext.oldList.size() : config.triggerContext.newList.size()) ; i++ ) {
                SObject record= (deletionContext == true ? config.triggerContext.oldList[i] : config.triggerContext.newList[i]);
                for (ATARC_Process_Setting__mdt setting: chain) {
                    
                    /**********************************/
                        //simple skip functionality
                        if (canSkip(config.skipEverything, setting)) {
                            atarcDebug('BYPASS FOUND getFEAInstances '+setting.DeveloperName);
                            continue;
                        }
                    if(setting.isAsync__c == true && fromAsync != true) continue;
                    
                    if (feaInstances.containsKey(setting.DeveloperName) ) {
                        
                        AsyncTriggerArcFEAProcessBase feaInstance = feaInstances.get(setting.DeveloperName);
                        
                        //configuring
                        config.triggerContext.debugMode = setting.debug__c;
                        config.triggerContext.debugLevel = setting.debug_Level__c;
                        config.triggerContext.processName = setting.DeveloperName;
                        
                        pushToProcessStack(setting);
                        boolean noError = true;
                        //invoking the "filter" method
                        try {
                            
                            
                            if ((String.isNotEmpty(setting.DependsOnSuccess__c) && processesExecStatuses.containsKeY(setting.DependsOnSuccess__c) && processesExecStatuses.get(setting.DependsOnSuccess__c).status == PROCESS_EXECUTED ) ||
                                (String.isNotEmpty(setting.DependsOnFailure__c) && processesExecStatuses.containsKeY(setting.DependsOnFailure__c) && processesExecStatuses.get(setting.DependsOnFailure__c).status == PROCESS_FAILED ) ||
                                (String.isBlank(setting.DependsOnSuccess__c) && String.isBlank(setting.DependsOnFailure__c))
                            )    
                            {
                                   
                                   feaInstance.filter((deletionContext != true ?  config.triggerContext.oldList[i] : record),(deletionContext != true ? record : null), config.triggerContext);
                                
                                   long totalTime = system.datetime.now().millisecond() - startTime;
                                   
                                   UpdateStatusSuccess(setting.DeveloperName);
                                   
                                   UpdateProcessTime(setting.DeveloperName, totalTime);
                                   
                               } 
                            
                        } catch (Exception err) {
                            
                            long totalTime = system.datetime.now().millisecond() - startTime;
                            
                            UpdateStatusFailed(setting.DeveloperName);
                            UpdateProcessTime(setting.DeveloperName, totalTime);

                            atarcDebug('EXCEPTION!!:\n' + err.getMessage());
                            processesStack.remove(processesStack.size() - 1);
                            noError = false;
                            
                            //break transaction if error feature
                            if (setting.BreakIfError__c) {
                                atarcDebug('breaking transaction');
                                throw err;
                            }
                        }
                        
                        if(noError) processesStack.remove(processesStack.size() - 1);
                        
                    }
                    
                }
                 
            }            
        } 
        atarcDebug('Running first loop for FILTER pattern COMPLETE');
    }
    
    /*
    * @method
    * Calls the execute method from the base process class (either fea or not)
    */
    static boolean runExecutePattern(AsyncTriggerArcConfig config, boolean fromAsync, map < string, AsyncTriggerArcProcessBase > instances,map < string, AsyncTriggerArcFEAProcessBase > feaInstances, List < ATARC_Process_Setting__mdt > syncProcessesToRunActionPattern) {
        boolean breakTransaction = false;
        atarcDebug('Running  EXECUTE Pattern');
        
        if(instances.size() == 0 && feaInstances.size() == 0) atarcDebug('No instances or feainstances found, execute pattern will not run .');
        
        if(instances.size() > 0 || feainstances.size() > 0){
            
            while (config.chain.size() > 0) {
                
                atarcDebug('Pending processes size ' + config.chain.size());
                
                //"doing pop", returning and removing the next process to evaluate and execute
                //this is key to get rid of the processed processes from the queue
                ATARC_Process_Setting__mdt setting = config.chain.remove(0);
                
                
                /**********************************/
                //simple skip functionality
                if (canSkip(config.skipEverything, setting)) {
                    atarcDebug('BYPASS FOUND execute '+setting.DeveloperName);                    
                    break;
                }
                /***********************************/
                
                //configuring
                config.triggerContext.debugMode = setting.debug__c;
                config.triggerContext.debugLevel = setting.debug_Level__c;
                config.triggerContext.processName = setting.DeveloperName;
                
                pushToProcessStack(setting);
                
                
                if ( (String.isnotblank(setting.DependsOnSuccess__c) && processesExecStatuses.containsKeY(setting.DependsOnSuccess__c) && processesExecStatuses.get(setting.DependsOnSuccess__c).status == PROCESS_EXECUTED) || 
                    (String.isnotblank(setting.DependsOnFailure__c) && processesExecStatuses.containsKeY(setting.DependsOnFailure__c) && processesExecStatuses.get(setting.DependsOnFailure__c).status == PROCESS_FAILED ) ||
                    (String.isBlank(setting.DependsOnSuccess__c) && String.isBlank(setting.DependsOnFailure__c))
                   )
                {
                       breakTransaction = Run(instances, feaInstances, config, setting, fromAsync);
                       processesStack.remove(processesStack.size() - 1);
                   } 
                
                //async transactions invokations should break this loop
                if (breakTransaction) { //&& DEFAULT_OPERATION_STRATEGY_MODE.equalsIgnoreCase(config.strategyMode) ){                
                    break;
                }
                
                if (feainstances.containskey(setting.DeveloperName))  syncProcessesToRunActionPattern.add(setting);
            }
        }
        atarcDebug('Running EXECUTE pattern COMPLETE');
        return breakTransaction;
    }
    
    /*******************************/
    //@method
    //Evaluates the apex classes from the custom settings to send it to the fea pattern or the regular execute method
    /*****************************/
    static void Eval(AsyncTriggerArcConfig config, map < string, AsyncTriggerArcProcessBase > instances, map < string, AsyncTriggerArcFEAProcessBase > feaInstances) {
        atarcDebug('Preparing to start invoke processes');
        
        instances =  getInstances(config);
        feaInstances =  getFeaInstances(config, instances.keyset());
        
        List < ATARC_Process_Setting__mdt > syncProcessesToRunActionPattern = new List < ATARC_Process_Setting__mdt > ();
        
        boolean deletionContext = config.triggerContext.isdelete == true; //|| config.triggerContext.isUndelete == true;
        
        /*
        * FIRST LOOP TO DO FILTER PATTERN
        */
        runFilterPattern(config, deletionContext, feaInstances, config.chain, false);
        
        /*
        * EXECUTION invoke, no loop in here
        */
        //processes chaning logic
        boolean breakTransaction = runExecutePattern(config, false, instances,feaInstances, syncProcessesToRunActionPattern);
        
        /*
        * SECOND LOOP TO DO ACTION PATTERN
        */
        runActionPattern(config, false, breakTransaction, deletionContext, feaInstances, syncProcessesToRunActionPattern);
        
    }
    
    
    
    /**********************************/
    //@method
    //RUN
    /**************************************/
    static boolean Run(map < string, AsyncTriggerArcProcessBase > instances, map < string, AsyncTriggerArcFEAProcessBase > feaInstances, AsyncTriggerArcConfig config, ATARC_Process_Setting__mdt setting, boolean fromAsync) {
        
        boolean isAsync = false;
        config.triggerContext.debugMode = setting.debug__c;
        config.triggerContext.debugLevel = setting.debug_Level__c;
        
        //async processes should break the upper loop only if isolate is false
        //so that only one active process thread is working            
        AsyncTriggerArcQueueable asyncWorker = RequestQueuable();
        
        if (setting.isAsync__c && asyncWorker != null &&
            //to fix specific problems when dml happens on a processes and the objects
            //affected by the dml has async process as well
            !runningAsyncContext) {
                /**********************************/
                //async feature
                //
                
                atarcDebug('Async running...');
                
                asyncWorker.currentSetting = setting;
                asyncWorker.config = config;
                if(setting.isolate__c){
                    asyncWorker.config = new AsyncTriggerArcConfig();
                    asyncWorker.config.Chain = new List<ATARC_Process_Setting__mdt>();
                    asyncWorker.config.Chain.add(setting);
                    asyncWorker.config.triggerContext = config.triggerContext;
                }
                asyncWorker.pStatuses = processesExecStatuses;
                asyncWorker.fromAsync = true;
                asyncWorker.pCustomData =  customData;
                asyncWorker.pSkips = skips;
                asyncWorker.instances = instances;  //(instances.containsKey(setting.name) ? new Map<string, AsyncTriggerArcProcessBase > { setting.name => instances.get(setting.name)} : new Map<string,AsyncTriggerArcProcessBase>() );
                asyncWorker.feaInstances = feaInstances; //(feaInstances.containsKey(setting.name) ? new Map<string, AsyncTriggerArcFEAProcessBase > { setting.name => feaInstances.get(setting.name)} : new Map<string,AsyncTriggerArcFEAProcessBase>() );   
                    
                system.enqueueJob(asyncWorker);
                atarcDebug('Processes executed async');
                
                isAsync = setting.isolate__c != true; // if isAsync = true processes in the config.chain will be executed from the recently queued queueable execution for the current object/event               
            } 
         
        else {
            
            atarcDebug('Running '+setting.DeveloperName+'...');
            
            //after class is executed then get the output if any
            //after preparing data for the triggerContext upper loop should run the next process in line.
            object output = RunClass(instances, feaInstances, config, setting);
            
            //cleaning the heap a little bit
            if(instances.containsKey(setting.DeveloperName))
                instances.remove(setting.DeveloperName);
            
            customData.put(setting.DeveloperName, output);
                        
        }
        
        return isAsync;
    }
    
    /*
    * @method
    * RequestInstance
    */
    static Object RequestInstance(string apexClassName, boolean throwError) {
        object newInstance = null;
        
        try {
            Type t = Type.forName(apexClassName);
            newInstance = t.newInstance();
        } catch (Exception err) {
            
            /**********************************/
            //break transaction if error feature
            if (throwError)
                throw err;
        }
        return newInstance;
        
    }
    
    
    /********************************/
    //@method
    //RUNCLASS
    /********************************/
    static Object RunClass(Map < string, AsyncTriggerArcProcessBase > instances, map < string, AsyncTriggerArcFEAProcessBase > feaInstances, AsyncTriggerArcConfig config, ATARC_Process_Setting__mdt setting) {        
        
        object o =  null;
        
        AsyncTriggerArcProcessBase instance = (          
            instances.containsKey(setting.DeveloperName) ? instances.get(setting.DeveloperName) : null
        );
        AsyncTriggerArcFEAProcessBase feaInstance = (            
            feaInstances.containsKey(setting.DeveloperName) ? feaInstances.get(setting.DeveloperName) : null           
        );
        
        Object output = null;
        
        config.triggerContext.processName = setting.DeveloperName;
        
        
        long startTime = system.datetime.now().millisecond();
        
        try {
            
            if (instance == null && feaInstance == null)
                throw new AsyncTriggerArcException('Not able to instantiate Apex Class ' + setting.ApexHelperClassName__c);
            
            atarcDebug('instance found');
            
            //passing data in between processes feature
            //the output represents the data output from a process            
            output = (instance != null) ? instance.execute(config.triggerContext) : ((feaInstance != null) ? feaInstance.execute(config.triggerContext) : null);
                     
            boolean outputExists = output != null;
            
            long totalTime = system.datetime.now().millisecond() - startTime;
            
            UpdateStatusSuccess(setting.DeveloperName);
            
            UpdateProcessTime(setting.DeveloperName, totalTime);
            
            atarcDebug('*****Processes executed exit ' + setting.ApexHelperClassName__c + '\nOutput Data:' + string.valueof(outputExists) + ' '+ processesExecStatuses.get(setting.DeveloperName));
            
        } catch (Exception err) {
            
            long totalTime = system.datetime.now().millisecond() - startTime;
            
            UpdateStatusFailed(setting.DeveloperName);
            UpdateProcessTime(setting.DeveloperName, totalTime);

            atarcDebug('EXCEPTION!!:\n' + err.getMessage());
            
            /**********************************/
            //break transaction if error feature
            if (setting.BreakIfError__c) {
                atarcDebug('breaking transaction');
                throw err;
            }
        }
        
        return output;
        
    }
    
    void updateTriggerTrack() {
        if (!triggerExecTrack.containsKey(sObjectName))
            triggerExecTrack.put(sObjectName, new Map < string, integer > ());
        
        
        triggerExecTrack.get(SObjectName).put(
            triggerEventTxt,
            (
                triggerExecTrack.get(sObjectName).containsKey(triggerEventTxt) ? triggerExecTrack.get(sObjectName).get(triggerEventTxt) + 1 : 1
            ));
    }
    
    integer getTriggerTrack() {
        return (
            triggerExecTrack.containsKey(sObjectName) &&
            triggerExecTrack.get(sObjectName).containsKey(triggerEventTxt) ? triggerExecTrack.get(sObjectName).get(triggerEventTxt) : 0
        );
    }
    
    /*
    * Updates the status of the configuration
    */
    static void UpdateStatusSuccess(string processName) {
        
        if(processesExecStatuses.get(processName).status != PROCESS_FAILED) processesExecStatuses.get(processName).status = PROCESS_EXECUTED;
    }
    /*
    * Updates the status of the configuration
    */
    static void UpdateStatusFailed(string processName) {
        
         processesExecStatuses.get(processName).status = PROCESS_FAILED;
    }
    
    static void UpdateProcessTime(string processName, long totalTime) {
        processesExecStatuses.get(processName).processTime = totalTime;
    }
    
    /************************************************/
    //INNER CLASSES
    /***********************************************/
    
    public class AsyncTriggerArcProcessInfo {
        public string status {
            get;
            set;
        }
        public long processTime {
            get;
            set;
        }
    }
    
    class AsyncTriggerArcConfig {
        
        public List < ATARC_Process_Setting__mdt > Chain {
            get;
            set;
        }
        public AsyncTriggerArcContext triggerContext {
            get;
            set;
        }       
        public boolean skipEverything {
            get;
            set;
        }        
        
        public AsyncTriggerArcConfig() {
            
            triggerContext = new AsyncTriggerArcContext();           
            
                        skipEverything = false;
            
        }
        
    }
    
    
    /*
    * Wrapper class
    * Holds apex trigger context data
    */
    public class AsyncTriggerArcContext {
        public boolean isBefore {
            get;
            protected set;            
        }
        public boolean isAfter {
            get;
            protected set;
        }
        public boolean isUpdate {
            get;
            protected set;
        }
        public boolean isDelete {
            get;
            protected set;
        }
        public boolean isInsert {
            get;
            protected set;
        }
        public boolean isUndelete {
            get;
            protected set;
        }
        public integer transactionLoop {
            get {
                return tloop;
            }
            set {
                tloop = value;
                globalTransactionLoop = value;
            }
        }
        protected integer tloop {
            get;
            set;
        }
        public List < SObject > newList {
            get;
            protected set;
        }
        public List < SObject > oldList {
            get;
            protected set;
        }
        public Map < id, SObject > oldMap {
            get;
            protected set;
        }
        public Map < id, SObject > newMap {
            get;
            protected set;
        }
        
        protected string processName;
        protected boolean debugMode = false;
        protected string debugLevel = DEFAULT_LOGGIN_LEVEL;
        
        public AsyncTriggerArcContext() {
            
        }
        
        public object getProcessData(string processName) {
            return (customData.containsKey(processName) ? customData.get(processName) : null);
        }
        public string getCurrentProcessName() {
            return processName;
        }
        
        public void setFailed() {
            processesExecStatuses.get(processName).status = PROCESS_FAILED;
        }
        
        public string getProcessStatus(string processName) {
            return processesExecStatuses.containsKey(processName) ? processesExecStatuses.get(processName).status : null;
        }
        
        public void debug(object msg) {
            AsyncTriggerArc.debug(processName, debugMode, debugLevel, msg != null ? string.valueof(msg) : '');
        }
         public AsyncTriggerArcContext bypass(string skipType, string skipValue) {
                if (skips.containsKey(skipType)) skips.get(skipType).add(skipValue);
                return this;
            }
            
            /*
        * @method
        * REMOVESKIP
        */
            public AsyncTriggerArcContext clearBypass(string skipType, string skipValue) {
                if (skips.containsKey(skipType)) skips.remove(skipValue);
                return this;
            }
    }
    
    /*
    * General Interface
    * Helper classes shall implement this interface
    */
    public abstract class AsyncTriggerArcProcessBase {
        
        
        /*
        * General execution
        */
        @testvisible protected virtual object execute(AsyncTriggerArcContext triggerContext){
            return null;
        }
        
        
    }
    
    
    /*
    * Helper classes shall extend this class
    */
    public abstract class AsyncTriggerArcFEAProcessBase {
        
        /*
        * First loop of the execution. Only filtering is valid in this loop.
        */
        @testvisible protected virtual void filter(sObject newRecord, sObject oldRecord, AsyncTriggerArcContext triggerContext){
            
        }
        
        /*
        * General execution
        */
        @testvisible protected virtual object execute(AsyncTriggerArcContext triggerContext){
            return null;
        }
        
        /*
        * Second loop of the execution. After having all the needed data perfor any operation in here.
        */
        @testVisible protected virtual void action(SObject newRecord, sObject oldRecord, AsyncTriggerArcContext triggerContext){
            
        }
        
    }
    
    class AsyncTriggerArcQueueable implements Queueable, Database.AllowsCallouts  {
        public AsyncTriggerArcConfig Config {
            get;
            set;
        }
        public ATARC_Process_Setting__mdt currentSetting {
            get;
            set;
        }
        public Map < string, AsyncTriggerArcProcessInfo > pStatuses {
            get;
            set;
        }
        public string additionalMsg {
            get;
            set;
        }
        public boolean fromAsync {
            get;
            set;
        }
        public Map<string, AsyncTriggerArcProcessBase> instances {
            get;
            set;
        }
        public map < string, AsyncTriggerArcFEAProcessBase > feaInstances{
            get;
            set;
        }
        
        public map < string, object> pCustomData {
            get;
            set;
        }
        
        public Map < string, set < string > > pSkips {
            get;
            set;
        }
        
        public virtual void execute(QueueableContext context) {
            
            atarcDebug('EXECUTING ASYNC ' + currentSetting.ApexHelperClassName__c + '\n' + additionalMsg + '\n'+currentSetting.DeveloperName );
            
            //instances = instances.containsKey(currentSetting.DeveloperName) ? instances : new Map<string,AsyncTriggerArcProcessBase>() ; 
            //feaInstances = feaInstances.containsKey(currentSetting.DeveloperName) ? feaInstances : new Map<string, AsyncTriggerArcFEAProcessBase>() ;
            
            customData = pCustomData;
            
            //TODO: TEST THIS SCENARIO FOR runningAsyncContext = true
            //to overcome sfdc limit 
            //(only one queueable can be called from within a queueable so any dlm inside the implementation 
            //of the this context will be executed within this transaction unfortunately)
            runningAsyncContext = true;
            
            //tracking of the executed processes so far
            processesExecStatuses = pstatuses;
            system.debug(processesExecStatuses);
            skips = pSkips;
                       
            boolean deletionContext = config.triggerContext.isdelete == true || config.triggerContext.isUndelete == true;
            
            if (feaInstances.containsKey(currentSetting.DeveloperName))
                runFilterPattern(config, deletionContext, feaInstances, new List < ATARC_Process_Setting__mdt > {
                    currentSetting
                        }, fromAsync);
            
            pushToProcessStack(currentSetting);
            object output = RunClass(instances,feaInstances, config, currentSetting);
            
            //store the output of the current invocation
            customData.put(currentSetting.DeveloperName, output);
                        
            /*
            * SECOND LOOP TO DO ACTIONS
            */
            if (feaInstances.containsKey(currentSetting.DeveloperName))//(includePattern(PATTERN_ACTION, currentSetting))
                runActionPattern(config, true, false, deletionContext, feaInstances, new List < ATARC_Process_Setting__mdt > {
                    currentSetting
                        });
            
            //unflaggin this allows the eval process to run/chain another queueable
            runningAsyncContext = false;
            
            //chain operations
            //call the next operation according to the order.            
            List<ATARC_Process_Setting__mdt> dummyList = new List<ATARC_Process_Setting__mdt>();
            if(!currentSetting.isolate__c) runExecutePattern(config, fromAsync, instances, feaInstances, dummyList);
            
        }
    }

    class AsyncTriggerArcDebugStackSetting{
        public string name {get;set;}
        public boolean debugMode {get;set;}
        public string lvl {get;set;}
    }
    
    public class AsyncTriggerArcException extends Exception {}
    
}