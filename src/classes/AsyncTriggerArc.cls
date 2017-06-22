/*
* Created By : Angel Robles (anyei)
* Created Date: 1/6/2017
* Purpose: In a nutshell, runs processes out of a custom setting. The custom setting has a field indicating
*           the apex class implementing AsyncTriggerArcProcessBase or AsyncTriggerArcProcessFEABAse base class which is the code to execute (the process), 
*           order of execution, a flag to make it active or not (if not active it will not run), a flag to force it to run
*           as queueable, a field to control dependencies (process A is dependent on process B to run, if process B does not run or 
*           has an exception in the code process A will not run) and in addition to all that this also has the capability to pass output from one process
*           to the next one within the same transaction.  processToSkip
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
    public static final integer GOVERNOR_LIMITS_QUEUEABLE = 50;
    
    //global maps, lists, config
    @TestVisible static Map < string, map < string, AsyncTriggerArqSettings__c[] >> arqSettings;
    
    //must be an instance variable
    //this is the state of engine instance
    
    @TestVisible AsyncTriggerArcConfig globalConfig;
    
    @TestVisible static AsyncTriggerArcConfig currentGlobalConfig;
    
    @testVisible static Map < string, set < string > > skips;
    
    @TestVisible static Map < string, AsyncTriggerArcProcessInfo > processesExecStatuses;
    
    @testVisible static Map < string, object > customData;
    
    @TestVisible static Map < string, Map < string, integer >> triggerExecTrack;
    
    @TestVisible static Map < string, System.LoggingLevel > logginLevelMap;
    
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
        
        arqSettings = new Map < string, Map < string, AsyncTriggerArqSettings__c[] >> ();
        
        triggerExecTrack = new Map < string, Map < string, integer >> ();
        
        processesExecStatuses = new Map < string, AsyncTriggerArcProcessInfo > ();
        
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
        
        globalTransactionLoop = 1;        
        
        runningAsyncContext = false;
        
    }
    
    static AsyncTriggerArcQueueableBase RequestQueuable() {
        
        AsyncTriggerArcQueueableBase newInstance = null;
        
        if (Limits.getQueueableJobs() < GOVERNOR_LIMITS_QUEUEABLE) {
            newInstance = new AsyncTriggerArcQueueable();
        }
        return newInstance;
    }
    
    @TestVisible static boolean canSkip(boolean gskip, AsyncTriggerArqSettings__c setting) {
        boolean skip = false;
        
        //if (gskip == true) return gskip;
        
        for (string skipType: skips.keyset()) {
            if (skipType == CATEGORY_SKIP)
                if (skip = skips.get(skipType).contains(setting.Category__c)) break;
            if (skipType == OBJECT_SKIP)
                if (skip = skips.get(skipType).contains(setting.SObject__c)) break;
            if (skipType == EVENT_SKIP)
                if (skip = skips.get(skipType).contains(setting.Event__c)) break;
            if (skipType == PROCESS_SKIP)
                if (skip = skips.get(skipType).contains(setting.Name)) break;
            
        }
        return skip || gskip;
    }
    
    //it will be always synchronous first
    boolean SyncFirst() {
        return true;
        
    }
    
    //TODO: DECOM
    boolean respectOrder() {
        return false;
    }
    /*
* @method
* Process the order of the items retrieve from the config settings
*/
    @TestVisible void processOrder(boolean firstTime) {
        
        if (orderProcessed != true) {
            
            Map < string, Map < string, List < integer >>> orderLogicA = new Map < string, Map < string, List < integer >>> ();
            Map < string, Map < string, List < integer >>> orderLogicS = new Map < string, Map < string, List < integer >>> ();
            
            List < AsyncTriggerArqSettings__c > settings = AsyncTriggerArqSettings__c.GetAll().values();
            
            
            
            /*
* Synchronous settings should be executed first, no matter if in the order of execution they are listed after an async one
* This is to avoid specific behavior ( If async process A executes and then the next in line to be executed are three sync process
* if we want to separate those transactions then we need to make the sync processes to execute from within an async operation )
* 
*/
            
            boolean syncFirst = SyncFirst();
            boolean respectOrder = respectOrder();
            
            for (AsyncTriggerArqSettings__c setting: settings) {
                
                if (syncFirst) {
                    /*
* All non async processes are executed in the first after call in the transaction transaction
*/
                    if (setting.IsActive__c && !canSkip(globalSkip, setting) && setting.isAsync__c) {
                        
                        //order logic.. as we dont have soql we must order by our self
                        if (!orderLogicA.containsKey(setting.SObject__c))
                            orderLogicA.put(setting.SObject__c, new Map < string, List < integer >> ());
                        
                        if (!orderLogicA.get(setting.SObject__c).containsKey(setting.Event__c))
                            orderLogicA.get(setting.SObject__c).put(setting.Event__c, new List < integer > ());
                        
                        orderLogicA.get(setting.SObject__c).get(setting.Event__c).add(integer.valueof(setting.order__c));
                        orderLogicA.get(setting.SObject__c).get(setting.Event__c).sort();
                        
                        
                        
                    } else if (setting.IsActive__c && !canSkip(globalSkip, setting) && setting.isAsync__c != true) {
                        
                        //order logic.. as we dont have soql we must order by our self
                        if (!orderLogicS.containsKey(setting.SObject__c))
                            orderLogicS.put(setting.SObject__c, new Map < string, List < integer >> ());
                        
                        if (!orderLogicS.get(setting.SObject__c).containsKey(setting.Event__c))
                            orderLogicS.get(setting.SObject__c).put(setting.Event__c, new List < integer > ());
                        
                        orderLogicS.get(setting.SObject__c).get(setting.Event__c).add(integer.valueof(setting.order__c));
                        
                        orderLogicS.get(setting.SObject__c).get(setting.Event__c).sort();
                        
                    }
                    
                    /* RESPECT THE ORDER OF THE PROCESSES*/
                } 
                
                //DECOM : Synchronous will always run first, the order goes from sync to queueable
                /*else if (respectOrder) {
if (setting.IsActive__c && !canSkip(globalSkip, setting, globalConfig)) {

//order logic.. as we dont have soql we must order by our self
if (!orderLogicA.containsKey(setting.SObject__c))
orderLogicA.put(setting.SObject__c, new Map < string, List < integer >> ());

if (!orderLogicA.get(setting.SObject__c).containsKey(setting.Event__c))
orderLogicA.get(setting.SObject__c).put(setting.Event__c, new List < integer > ());

orderLogicA.get(setting.SObject__c).get(setting.Event__c).add(integer.valueof(setting.order__c));
orderLogicA.get(setting.SObject__c).get(setting.Event__c).sort();
}
}*/
                
                
            }
            
            for (AsyncTriggerArqSettings__c setting: settings) {
                if (setting.IsActive__c && !canSkip(globalSkip, setting)) {
                    
                    if (firstTime)
                        processesExecStatuses.put(setting.name, new AsyncTriggerArcProcessInfo());
                    
                    
                    List < integer > opa = (
                        (syncFirst || respectOrder) && orderLogicA.containsKey(setting.SObject__c) && orderLogicA.get(setting.SObject__c).containsKey(setting.Event__c) ?
                        orderLogicA.get(setting.SObject__c).get(setting.Event__c) :
                        new List < Integer > ()
                    );
                    
                    
                    List < integer > ops = (
                        (syncFirst || respectOrder) && orderLogicS.containsKey(setting.SObject__c) && orderLogicS.get(setting.SObject__c).containsKey(setting.Event__c) ?
                        orderLogicS.get(setting.SObject__c).get(setting.Event__c) :
                        new List < Integer > ()
                    );
                    
                    if (!arqSettings.containsKey(setting.SObject__c))
                        arqSettings.put(setting.SObject__c, new Map < string, AsyncTriggerArqSettings__c[] > ());
                    
                    if (!arqSettings.get(setting.SObject__c).containsKey(setting.Event__c))
                        arqSettings.get(setting.SObject__c).put(setting.Event__c, new AsyncTriggerArqSettings__c[(syncFirst ? opa.size() + ops.size() : opa.size())]);
                    
                    
                    for (integer i = 0; i < ((setting.isAsync__c || respectOrder) ? opa.size() : ops.size()); i++) {
                        
                        if (setting.isAsync__c != true && i < ops.size() && ops[i] == integer.valueof(setting.order__c)) {
                            arqSettings.get(setting.SObject__c).get(setting.Event__c).set(i, setting);
                            
                        } else if ((setting.isAsync__c || respectOrder) && opa[i] == integer.valueof(setting.order__c)) {
                            arqSettings.get(setting.SObject__c).get(setting.Event__c).set(i + (respectOrder() ? 0 : ops.size()), setting);
                        }
                    }
                    
                    
                    
                }
                
                
                
            }
            
            atarcDebug('Config loaded\n' + settings.size());
        }
        
        
        
        
        orderProcessed = true;
    }
    static void atarcDebug(object msg) {
        debug(FRAMEWORK_NAME, globalDebugMode, 'INFO', (msg != null) ? string.valueof(msg) : '');
    }
    public static void globalDebug(object msg) {
        if (currentGlobalConfig != null && currentGlobalConfig.triggerContext != null) debug(currentGlobalConfig.triggerContext.processName, currentGlobalConfig.triggerContext.debugMode, currentGlobalConfig.triggerContext.debugLevel, msg != null ? string.valueof(msg) : '');
        
    }
    
    static void debug(string prefix, boolean debugMode, string lvl, string msg) {
        if (debugMode == true) system.debug((logginLevelMap.containsKey(lvl) ? logginLevelMap.get(lvl) : logginLevelMap.get(DEFAULT_LOGGIN_LEVEL)), prefix + ': ' + msg);
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
        globalConfig.Chain = new List < AsyncTriggerArqSettings__c > ();
        
        
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
        //order feature        
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
               
               List < AsyncTriggerArqSettings__c > settings = arqSettings.get(sObjectName).get(triggerEventTxt);
               
               atarcDebug('Event match found:' + triggerEventTxt + '\nTotal processes:' + settings.size());
               
               for (AsyncTriggerArqSettings__c setting: settings) {
                   globalConfig.Chain.add(setting);
               }
               
               Eval(globalConfig, false, null, null);
           }
        
        
        atarcDebug('Exit Start\nTransaction loop tracking:' + getTriggerTrack() +
                   '\nSOBject:' + sObjectName +
                   '\nEvent:' + triggerEventTxt +
                   '\nRunningOutOfAnAsyncProcess:' + runningAsyncContext +
                   '\nglobalSkip:' + globalSkip +
                   '\nglobalTransactionLoop:' + globalTransactionLoop +
                   '\nglobalDebugMode:' + globalDebugMode );
    }
    
    static map < string, AsyncTriggerArcProcessBase > getInstances(AsyncTriggerArcConfig config) {
        map < string, AsyncTriggerArcProcessBase > instances = new Map < string, AsyncTriggerArcProcessBase > ();
        
        atarcDebug('Generating instances..getInstances');
        for (AsyncTriggerArqSettings__c setting: config.chain) {
            //instantiate the objects
            //and invoke the filter method
            
            
            /**********************************/
            //simple skip functionality
            if (canSkip(config.skipEverything, setting)) {
                atarcDebug('BYPASS FOUND getInstances '+setting.Name);
                continue;
            }
            /***********************************/
            object o = RequestInstance(setting.ApexHelperClassName__c, setting.BreakIfError__c);
            AsyncTriggerArcProcessBase instance = (o instanceof AsyncTriggerArcProcessBase ) ?  (AsyncTriggerArcProcessBase) o : null; 
            if (instance != null)
                instances.put(setting.name, instance);
        }
        
        return instances;
    }
    
    static map < string, AsyncTriggerArcFEAProcessBase > getFEAInstances(AsyncTriggerArcConfig config, set<string> standardInterface) {
        map < string, AsyncTriggerArcFEAProcessBase > instances = new Map < string, AsyncTriggerArcFEAProcessBase > ();
        
        atarcDebug('Generating instances..getFEAInstances');
        for (AsyncTriggerArqSettings__c setting: config.chain) {
            //instantiate the objects
            //and invoke the filter method
            
            /**********************************/
            //simple skip functionality
            if (canSkip(config.skipEverything, setting)) {
                atarcDebug('BYPASS FOUND getFEAInstances '+setting.Name);
                continue;
            }
            /***********************************/
            if(standardInterface.contains(setting.name)){
                continue;
            }
            object o = RequestInstance(setting.ApexHelperClassName__c, setting.BreakIfError__c);
            AsyncTriggerArcFEAProcessBase instance = (o instanceof AsyncTriggerArcFEAProcessBase) ? (AsyncTriggerArcFEAProcessBase)o: null;
            
            if (instance != null)
                instances.put(setting.name, instance);
        }
        
        return instances;
    }
    
    static void runActionPattern(AsyncTriggerArcConfig config, boolean fromAsync, boolean breakTransaction, boolean deletionContext, map < string, AsyncTriggerArcFEAProcessBase > feaInstances, List < AsyncTriggerArqSettings__c > chain) {
        if (breakTransaction != true) {
            atarcDebug('Running ACTION Pattern');
            if(feaInstances.size() == 0 ) atarcDebug('No fea instances found, action pattern will not run ');
            
            if(feaInstances.size() > 0){
                
                long startTime = system.datetime.now().millisecond();
                atarcDebug('Pending actions to run '+chain.size());
                
                for (SObject record: (deletionContext == true ? config.triggerContext.oldList : config.triggerContext.newList)) {
                    
                    for (AsyncTriggerArqSettings__c setting: chain) {
                        
                        if (feaInstances.containsKey(setting.name)) {
                            AsyncTriggerArcFEAProcessBase feaInstance = feaInstances.get(setting.name);
                            
                            
                            //configuring
                            config.triggerContext.debugMode = setting.debug__c;
                            config.triggerContext.debugLevel = setting.debugLevel__c;
                            config.triggerContext.processName = setting.name;
                            
                            
                            /*
* BREAKING LOOP IF PREVIOUS PATTERN DIDN'T EXECUTED PROPERLY
*/ 
                            /*if(  processesExecStatuses.get(setting.name).status != PROCESS_EXECUTED)
continue; //if previous pattern executed without succeed then just break/
*/ 
                            //if previous steps of the patterns ran well.
                            config.triggerContext.processSucceeded = processesExecStatuses.get(setting.name).status==PROCESS_EXECUTED;
                            
                            //invoking the "action" method
                            try {
                                
                                if (String.isNotEmpty(setting.DependsOn__c) &&
                                    processesExecStatuses.containsKeY(setting.DependsOn__c) &&
                                    processesExecStatuses.get(setting.DependsOn__c).status == PROCESS_EXECUTED /*&&
includePattern(PATTERN_ACTION, setting)*/
                                   ) {
                                       
                                       feaInstance.action((deletionContext != true ?  config.triggerContext.oldMap.get(record.id) : record),(deletionContext != true ? record : null), config.triggerContext);
                                       
                                       long totalTime = system.datetime.now().millisecond() - startTime;
                                       
                                       UpdateStatus(config, setting, (config.triggerContext.processSucceeded == true ? PROCESS_EXECUTED : PROCESS_FAILED));
                                       
                                       UpdateProcessTime(config, setting, totalTime);
                                       
                                   } 
                                else if (String.isNotEmpty(setting.DependsOnError__c) &&
                                         processesExecStatuses.containsKeY(setting.DependsOnError__c) &&
                                         processesExecStatuses.get(setting.DependsOnError__c).status == PROCESS_FAILED /*&&
includePattern(PATTERN_ACTION, setting)*/) {
    
    feaInstance.action((deletionContext != true ?  config.triggerContext.oldMap.get(record.id) : record),(deletionContext != true ? record : null), config.triggerContext);
    
    long totalTime = system.datetime.now().millisecond() - startTime;
    
     UpdateStatus(config, setting, (config.triggerContext.processSucceeded == true ? PROCESS_EXECUTED : PROCESS_FAILED));

    
    UpdateProcessTime(config, setting, totalTime);
    
    
    
} 
                                else if (String.isBlank(setting.DependsOn__c) &&
                                         String.isBlank(setting.DependsOnError__c) /*&&
includePattern(PATTERN_ACTION, setting)*/
                                        ) {
                                            feaInstance.action((deletionContext != true ?  config.triggerContext.oldMap.get(record.id) : record),(deletionContext != true ? record : null), config.triggerContext);
                                            
                                            long totalTime = system.datetime.now().millisecond() - startTime;
                                            
                                            UpdateStatus(config, setting, (config.triggerContext.processSucceeded == true ? PROCESS_EXECUTED : PROCESS_FAILED));

                                            UpdateProcessTime(config, setting, totalTime);
                                            
                                        }
                                
                                
                                
                            } catch (Exception err) {
                                
                                long totalTime = system.datetime.now().millisecond() - startTime;
                                
                                UpdateStatus(config, setting, PROCESS_FAILED);
                                UpdateProcessTime(config, setting, totalTime);
                                
                                atarcDebug('EXCEPTION!!:\n' + err.getMessage());
                                
                                /**********************************/
                                //break transaction if error feature
                                if (setting.BreakIfError__c) {
                                    atarcDebug('breaking transaction');
                                    throw err;
                                }
                            }
                            
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
    
    static void runFilterPattern(AsyncTriggerArcConfig config, boolean deletionContext, map < string, AsyncTriggerArcFEAProcessBase > feaInstances, List < AsyncTriggerArqSettings__c > chain, boolean fromAsync) {
        atarcDebug('Running first loop for FILTER pattern ');
        
        if(feaInstances.size() == 0) atarcDebug('No fea instances found, filter pattern will not run');
        
        //shall not run even a single line of code if no fea instances
        if(feaInstances.size() > 0){
            
            long startTime = system.datetime.now().millisecond();
            boolean firstRecord = true;
            for (SObject record: (deletionContext == true ? config.triggerContext.oldList : config.triggerContext.newList)) {
                
                for (AsyncTriggerArqSettings__c setting: chain) {
                    if(setting.isAsync__c == true && fromAsync != true) continue;
                    
                    if (feaInstances.containsKey(setting.name) ) {
                        
                        
                        AsyncTriggerArcFEAProcessBase feaInstance = feaInstances.get(setting.name);
                        
                        
                        //configuring
                        config.triggerContext.debugMode = setting.debug__c;
                        config.triggerContext.debugLevel = setting.debugLevel__c;
                        config.triggerContext.processSucceeded = firstRecord ? firstRecord : processesExecStatuses.get(setting.name).status ==PROCESS_EXECUTED;
                        config.triggerContext.processName = setting.name;
                        
                        
                        
                        //invoking the "filter" method
                        try {
                            
                            
                            if (String.isNotEmpty(setting.DependsOn__c) &&
                                processesExecStatuses.containsKeY(setting.DependsOn__c) &&
                                processesExecStatuses.get(setting.DependsOn__c).status == PROCESS_EXECUTED /*&&
includePattern(PATTERN_FILTER, setting)*/
                               ) {
                                   
                                   feaInstance.filter((deletionContext != true ?  config.triggerContext.oldMap.get(record.id) : record),(deletionContext != true ? record : null), config.triggerContext);
                                   
                                   long totalTime = system.datetime.now().millisecond() - startTime;
                                   
                                   UpdateStatus(config, setting, (config.triggerContext.processSucceeded == true ? PROCESS_EXECUTED : PROCESS_FAILED));
                                   
                                   UpdateProcessTime(config, setting, totalTime);
                                   
                               } 
                            else if (String.isNotEmpty(setting.DependsOnError__c) &&
                                     processesExecStatuses.containsKeY(setting.DependsOnError__c) &&
                                     processesExecStatuses.get(setting.DependsOnError__c).status == PROCESS_FAILED /*&&
includePattern(PATTERN_FILTER, setting)*/) {
    
    feaInstance.filter((deletionContext != true ?  config.triggerContext.oldMap.get(record.id) : record),(deletionContext != true ? record : null), config.triggerContext);
    
    long totalTime = system.datetime.now().millisecond() - startTime;
    
    //UpdateStatus(config, setting, (config.triggerContext.processSucceeded == true ? PROCESS_EXECUTED : PROCESS_FAILED));
    
    UpdateStatus(config, setting, (config.triggerContext.processSucceeded == true ? PROCESS_EXECUTED : PROCESS_FAILED));

    
    UpdateProcessTime(config, setting, totalTime);
    
    
    
} 
                            else if (String.isBlank(setting.DependsOn__c) &&
                                     String.isBlank(setting.DependsOnError__c) /*&&
includePattern(PATTERN_FILTER, setting)*/
                                    ) {
                                        feaInstance.filter((deletionContext != true ?  config.triggerContext.oldMap.get(record.id) : record),(deletionContext != true ? record : null), config.triggerContext);
                                        
                                        long totalTime = system.datetime.now().millisecond() - startTime;
                                        
                                        //UpdateStatus(config, setting, (config.triggerContext.processSucceeded == true ? PROCESS_EXECUTED : PROCESS_FAILED));
                                         UpdateStatus(config, setting, (config.triggerContext.processSucceeded == true ? PROCESS_EXECUTED : PROCESS_FAILED));

                                        
                                        UpdateProcessTime(config, setting, totalTime);
                                    }
                            
                            
                            
                            
                        } catch (Exception err) {
                            
                            long totalTime = system.datetime.now().millisecond() - startTime;
                            
                            UpdateStatus(config, setting, PROCESS_FAILED);
                            UpdateProcessTime(config, setting, totalTime);
                            config.triggerContext.processSucceeded = false;
                            
                            
                            atarcDebug('EXCEPTION!!:\n' + err.getMessage());
                            
                            /**********************************/
                            //break transaction if error feature
                            if (setting.BreakIfError__c) {
                                atarcDebug('breaking transaction');
                                throw err;
                            }
                        }
                        
                    }
                    
                }
                 
                firstRecord = false;
            }            
        } 
        atarcDebug('Running first loop for FILTER pattern COMPLETE');
    }
    
    static boolean runExecutePattern(AsyncTriggerArcConfig config, boolean fromAsync, map < string, AsyncTriggerArcProcessBase > instances,map < string, AsyncTriggerArcFEAProcessBase > feaInstances, List < AsyncTriggerArqSettings__c > syncProcessesToRunActionPattern) {
        boolean breakTransaction = false;
        atarcDebug('Running  EXECUTE Pattern');
        
        if(instances.size() == 0 && feaInstances.size() == 0) atarcDebug('No instances or feainstances found, execute pattern will not run .');
        
        if(instances.size() > 0 || feainstances.size() > 0){
            
            while (config.chain.size() > 0) {
                
                atarcDebug('Pending processes size ' + config.chain.size());
                
                //"doing pop", returning and removing the next process to evaluate and execute
                //this is key to get rid of the processed processes from the queue
                AsyncTriggerArqSettings__c setting = config.chain.remove(0);
                
                 if (feainstances.containskey(setting.name))//includePattern(PATTERN_ACTION, setting))
                                     syncProcessesToRunActionPattern.add(setting);
                
                  config.triggerContext.processSucceeded = !feainstances.containsKey(setting.name) ? true : processesExecStatuses.get(setting.name).status ==PROCESS_EXECUTED;
               
                atarcDebug('Evaluating process\nName:' + setting.Name + '\nApexClass:' + setting.ApexHelperClassName__c + '\nOrder:' + setting.Order__c + '\nIsAsync:' + setting.isAsync__c+'\nDebug:'+setting.debug__c);
                
                /**********************************/
                //simple skip functionality
                if (canSkip(config.skipEverything, setting)) {
                    atarcDebug('BYPASS FOUND execute '+setting.name);
                    break;
                }
                /***********************************/
                
                //configuring
                config.triggerContext.debugMode = setting.debug__c;
                config.triggerContext.debugLevel = setting.debugLevel__c;
                config.triggerContext.processName = setting.name;
                
                /*
* BREAKING LOOP IF PREVIOUS PATTERN DIDN'T EXECUTED PROPERLY
*/ 
                /* if(    setting.isAsync__c != true && feainstances.containsKey(setting.name) &&  processesExecStatuses.get(setting.name).status != PROCESS_EXECUTED)
{
atarcDebug('breaking previous pattern did not executed well');
continue; //if previous pattern executed without succeed then just break/

}*/
                
                if (String.isNotEmpty(setting.DependsOn__c) &&
                    processesExecStatuses.containsKeY(setting.DependsOn__c) &&
                    processesExecStatuses.get(setting.DependsOn__c).status == PROCESS_EXECUTED
                   ) {
                       
                       atarcDebug('Running with dependencies, depends on '+ setting.DependsOn__c);
                       //processes with dependencies should execute only if dependency process executed successfully
                       breakTransaction = Run(instances, feaInstances, config, setting, fromAsync);
                       
                       if (feainstances.containskey(setting.name))//includePattern(PATTERN_ACTION, setting))
                           syncProcessesToRunActionPattern.add(setting);
                       
                   } else if (String.isNotEmpty(setting.DependsOnError__c) &&
                              processesExecStatuses.containsKeY(setting.DependsOnError__c) &&
                              processesExecStatuses.get(setting.DependsOnError__c).status == PROCESS_FAILED
                             ) {
                                 
                                 atarcDebug('Running with dependencies, depends on error '+ setting.DependsOnError__c);
                                 //processes with dependencies should execute only if dependency process executed successfully
                                 breakTransaction = Run(instances, feaInstances, config, setting, fromAsync);
                                 
                                
                                 
                             } else if (String.isBlank(setting.DependsOn__c) &&
                                        String.isBlank(setting.DependsOnError__c)
                                       ) {
                                           atarcDebug('running with no dependencies');
                                           //processes with no dependencies should run
                                           breakTransaction = Run(instances, feaInstances, config, setting, fromAsync);
                                           
                                          
                                       } else if (config.Chain.size() > 0) {
                                           
                                           //processes with dependencies but dependency didn't executed successfully should be skipped
                                           //the next process in the list should be executed
                                           continue;
                                       }
                
                
                //async transactions invokations should break this loop
                if (breakTransaction) { //&& DEFAULT_OPERATION_STRATEGY_MODE.equalsIgnoreCase(config.strategyMode) ){                
                    break;
                }
            }
        }
        atarcDebug('Running EXECUTE pattern COMPLETE');
        return breakTransaction;
    }
    
    /*******************************/
    //@method
    //Eval
    /*****************************/
    static void Eval(AsyncTriggerArcConfig config, boolean fromAsync,  map < string, AsyncTriggerArcProcessBase > instances, map < string, AsyncTriggerArcFEAProcessBase > feaInstances) {
        atarcDebug('Preparing to start invoke processes');
        
        instances = fromAsync ? instances : getInstances(config);
        feaInstances = fromAsync ? feaInstances : getFeaInstances(config, instances.keyset());
        
        List < AsyncTriggerArqSettings__c > syncProcessesToRunActionPattern = new List < AsyncTriggerArqSettings__c > ();
        
        boolean deletionContext = config.triggerContext.isdelete == true || config.triggerContext.isUndelete == true;
        
        /*
* FIRST LOOP TO DO FILTER PATTERN
*/
        if(fromAsync != true)
            runFilterPattern(config, deletionContext, feaInstances, config.chain, fromAsync);
        //if(config.triggerContext.isAfter)
        //system.assert(false, feaInstances.keyset());
        /*
* EXECUTION invoke, no loop in here
*/
        //processes chaning logic
        boolean breakTransaction = runExecutePattern(config, fromAsync, instances,feaInstances, syncProcessesToRunActionPattern);
        
        
        
        /*
* SECOND LOOP TO DO ACTION PATTERN
*/
        runActionPattern(config, fromAsync, breakTransaction, deletionContext, feaInstances, syncProcessesToRunActionPattern);
        
        
    }
    
    
    
    /**********************************/
    //@method
    //RUN
    /**************************************/
    static boolean Run(map < string, AsyncTriggerArcProcessBase > instances, map < string, AsyncTriggerArcFEAProcessBase > feaInstances, AsyncTriggerArcConfig config, AsyncTriggerArqSettings__c setting, boolean fromAsync) {
        
        boolean isAsync = false;
        config.triggerContext.debugMode = setting.debug__c;
        config.triggerContext.debugLevel = setting.debugLevel__c;
        
        if (setting.isAsync__c &&
            //to fix specific problems when dml happens on a processes and the objects
            //affected by the dml has async process as well
            !runningAsyncContext) {
                /**********************************/
                //async feature
                //
                
                atarcDebug('Async running...');
                
                //async processes should break the upper loop
                //so that only one active process thread is working            
                //AsyncTriggerArcQueueable asyncWorker = new AsyncTriggerArcQueueable(config, setting, processesExecStatuses);
                AsyncTriggerArcQueueableBase asyncWorker = RequestQueuable();
                asyncWorker.currentSetting = setting;
                asyncWorker.config = config;
                asyncWorker.pStatuses = processesExecStatuses;
                asyncWorker.fromAsync = true;
                asyncWorker.pCustomData =  customData;
                asyncWorker.pSkips = skips;
                asyncWorker.instances = instances;  //(instances.containsKey(setting.name) ? new Map<string, AsyncTriggerArcProcessBase > { setting.name => instances.get(setting.name)} : new Map<string,AsyncTriggerArcProcessBase>() );
                asyncWorker.feaInstances = feaInstances; //(feaInstances.containsKey(setting.name) ? new Map<string, AsyncTriggerArcFEAProcessBase > { setting.name => feaInstances.get(setting.name)} : new Map<string,AsyncTriggerArcFEAProcessBase>() );   
                //asyncWorker.qpool = mainQueuableUsedPool;
                
                system.enqueueJob(asyncWorker);
                
                atarcDebug('Processes executed async');
                
                isAsync = true;
            } 
         
        else  /* if (includePattern(PATTERN_EXECUTE, setting))*/ {
            
            atarcDebug('Running...');
            
            //after class is executed then get the output if any
            //after preparing data for the triggerContext upper loop should run the next process in line.
            object output = RunClass(instances, feaInstances, config, setting);
            
            //cleaning the heap a little bit
            if(instances.containsKey(setting.name))
            	instances.remove(setting.name);
            
            customData.put(setting.Name, output);
            
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
    static Object RunClass(Map < string, AsyncTriggerArcProcessBase > instances, map < string, AsyncTriggerArcFEAProcessBase > feaInstances, AsyncTriggerArcConfig config, AsyncTriggerArqSettings__c setting) {        
        
        object o =  null;
        
        AsyncTriggerArcProcessBase instance = (          
            instances.containsKey(setting.name) ? instances.get(setting.name) : null
        );
        AsyncTriggerArcFEAProcessBase feaInstance = (            
            feaInstances.containsKey(setting.name) ? feaInstances.get(setting.name) : null           
        );
        
        Object output = null;
        
        config.triggerContext.processName = setting.name;
        
        
        long startTime = system.datetime.now().millisecond();
        
        try {
            
            if (instance == null && feaInstances == null)
                throw new AsyncTriggerArcException('Not able to instantiate Apex Class ' + setting.ApexHelperClassName__c);
            
            atarcDebug('instance found');
            
            //passing data in between processes feature
            //the output represents the data output from a process            
            output = (instance != null) ? instance.execute(config.triggerContext) : ((feaInstance != null) ? feaInstance.execute(config.triggerContext) : null);
                
                boolean outputExists = output != null;
            
            atarcDebug('Processes executed exit ' + setting.ApexHelperClassName__c + '\nOutput Data:' + string.valueof(outputExists) + ' executed '+ config.triggerContext.processSucceeded );
            
            long totalTime = system.datetime.now().millisecond() - startTime;
            
            //UpdateStatus(config, setting, (config.triggerContext.processSucceeded == true ? PROCESS_EXECUTED : PROCESS_FAILED));
             UpdateStatus(config, setting, (config.triggerContext.processSucceeded == true ? PROCESS_EXECUTED : PROCESS_FAILED));

            
            UpdateProcessTime(config, setting, totalTime);
            
        } catch (Exception err) {
            
            long totalTime = system.datetime.now().millisecond() - startTime;
            
            UpdateStatus(config, setting, PROCESS_FAILED);
            UpdateProcessTime(config, setting, totalTime);
            config.triggerContext.processSucceeded = false;
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
    static void UpdateStatus(AsyncTriggerArcConfig config, AsyncTriggerArqSettings__c setting, string status) {
        processesExecStatuses.get(setting.Name).status = status;
    }
    
    static void UpdateProcessTime(AsyncTriggerArcConfig config, AsyncTriggerArqSettings__c setting, long totalTime) {
        processesExecStatuses.get(setting.Name).processTime = totalTime;
    }
    
    /************************************************/
    //INNER CLASSES
    /***********************************************/
    
    public class AsyncTriggerArcProcessInfo {
        public string status {
            get;
            set;
        }
        public decimal processTime {
            get;
            set;
        }
    }
    
    class AsyncTriggerArcConfig {
        
        public List < AsyncTriggerArqSettings__c > Chain {
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
            set;
        }
        public boolean isAfter {
            get;
            set;
        }
        public boolean isUpdate {
            get;
            set;
        }
        public boolean isDelete {
            get;
            set;
        }
        public boolean isInsert {
            get;
            set;
        }
        public boolean isUndelete {
            get;
            set;
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
            set;
        }
        public List < SObject > oldList {
            get;
            set;
        }
        public Map < id, SObject > oldMap {
            get;
            set;
        }
        public Map < id, SObject > newMap {
            get;
            set;
        }
        
        protected string processName;
        protected boolean processSucceeded = null;      
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
            processSucceeded = false;
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
    
    
    public class AsyncTriggerArcQueueable extends AsyncTriggerArcQueueableBase {}
    
    /*
* General Interface
* Helper classes shall implement this interface
*/
    public abstract class AsyncTriggerArcProcessBase {
        
        /*
* General execution
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
* Second loop of the execution. After having all the needed data perfor any operation in here
* not related to field updates or validations throwouts.
*/
        @testVisible protected virtual void action(SObject newRecord, sObject oldRecord, AsyncTriggerArcContext triggerContext){
            
        }
        
        
    }
    
    
    /*
* General Interface
* Helper classes shall implement this interface
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
* Second loop of the execution. After having all the needed data perfor any operation in here
* not related to field updates or validations throwouts.
*/
        @testVisible protected virtual void action(SObject newRecord, sObject oldRecord, AsyncTriggerArcContext triggerContext){
            
        }
        
    }
    
    public abstract class AsyncTriggerArcQueueableBase implements Queueable, Database.AllowsCallouts  {
        public AsyncTriggerArcConfig Config {
            get;
            set;
        }
        public AsyncTriggerArqSettings__c currentSetting {
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
        public integer qpool {
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
            atarcDebug('EXECUTING ASYNC ' + currentSetting.ApexHelperClassName__c + '\n' + additionalMsg + '\n'+currentSetting.name );
            
            instances = instances.containsKey(currentSetting.name) ? instances : new Map<string,AsyncTriggerArcProcessBase>() ; 
            feaInstances = feaInstances.containsKey(currentSetting.name) ? feaInstances : new Map<string, AsyncTriggerArcFEAProcessBase>() ;
            
            object o = null;
            
            if(instances.size() == 0 && feaInstances.size() == 0)
            {
                o = RequestInstance(currentSetting.ApexHelperClassName__c, currentSetting.breakIfError__c);
                if(o instanceof AsyncTriggerArcProcessBase){
                    instances =  new Map < string, AsyncTriggerArcProcessBase > {
                        
                        currentSetting.Name => (AsyncTriggerArcProcessBase)o 
                            };
                                }
                
                if(o instanceof AsyncTriggerArcFEAProcessBase){
                    feaInstances =  new Map < string, AsyncTriggerArcFEAProcessBase > {
                        currentSetting.Name => (AsyncTriggerArcFEAProcessBase)o
                            };
                                }
                
                
            }
            
            
            customData = pCustomData;
            
            //TODO: TEST THIS SCENARIO FOR runningAsyncContext = true
            //to overcome sfdc limit 
            //(only one queueable can be called from within a queueable so any dlm inside the implementation 
            //of the this context will be executed within this transaction unfortunately)
            runningAsyncContext = false;
            
            //tracking of the executed processes so far
            processesExecStatuses = pstatuses;
            
            skips = pSkips;
            
            boolean deletionContext = config.triggerContext.isdelete == true || config.triggerContext.isUndelete == true;
            
            if (feaInstances.containsKey(currentSetting.name))//(includePattern(PATTERN_FILTER, currentSetting))
                runFilterPattern(config, deletionContext, feaInstances, new List < AsyncTriggerArqSettings__c > {
                    currentSetting
                        }, fromAsync);
            
            
            //to fix specific issue
            //globalConfig is empty when queueable is executed
            //
            //Also in the unit test when the starttest and stoptest happen
            //every async jobs or processes are treated as synchronous
            //but a new transaction is created anyway
            //globalConfig will be empty by that time 
            //assigning the config to the globalConfig will allow unit test context
            //to have the config data
            //globalConfig = config;
            atarcDebug('instances on async '+instances + ' '+feaInstances);
            object output = RunClass(instances,feaInstances, config, currentSetting);
            //run the class of the current setting
            /*if ( includePattern(PATTERN_EXECUTE, currentSetting)
&& 
( ( includePattern(PATTERN_FILTER, currentSetting) &&  processesExecStatuses.get(currentSetting.name).status == PROCESS_EXECUTED)
|| !includePattern(PATTERN_FILTER, currentSetting) 
)

)
output = RunClass(instances,feaInstances, config, currentSetting);*/
            
            //store the output of the current invocation
            customData.put(currentSetting.Name, output);
            
            //unflaggin this allows the eval process to run/chain another queueable
            runningAsyncContext = false;
            
            
            /*
* SECOND LOOP TO DO ACTIONS
*/
            if (feaInstances.containsKey(currentSetting.name))//(includePattern(PATTERN_ACTION, currentSetting))
                runActionPattern(config, true, false, deletionContext, feaInstances, new List < AsyncTriggerArqSettings__c > {
                    currentSetting
                        });
            
            
            
            
            //chain operations
            //call the next operation according to the order.            
            List<AsyncTriggerArqSettings__c> dummyList = new List<AsyncTriggerArqSettings__c>();
            runExecutePattern(config, fromAsync, instances, feaInstances, dummyList);
            
        }
    }
    
    public class AsyncTriggerArcException extends Exception {}
    
}