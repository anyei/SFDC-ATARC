# ATARC

# MAJOR CHANGES, DOCUMENTATION REVAMP PENDING 2020-02-08

Inbound request ahead but Opportunity triggers are too many not sure where to add this new feature!!! 

Triggers are flooded with functionalities and salesforce governor limits within DML transactions are a pain in my.... neck, how can i come up with something so that at least let us make some extra space within the transaction to include another process that needs to run within this trigger with a better performance and efficiency?. I think i'm not the only one nor the first one who have asked that question.

Imagine you could found a framework that allows you to fight against the de-facto governor limit situation within transactions. Let me introduce ATARC (heroic music playing in the background). 

I understand there are many good trigger frameworks out there already but I also understand none of them treated the topic with this approach. 

**Please go to our wiki for a more detailed information and api reference!** https://github.com/anyei/SFDC-ATARC/wiki

# What is ATARC

ATARC is a framework, toolset and guidelines (i'm not sure how to call it actually) created with that single purpose in mind, to optimize process executions within triggers hence maximize resources availability within a DML transaction.

With ATARC besides what I just said above, you could control the order of execution of your processes, make them active or inactivate whenever the heck you want and and also control dependencies execution.... all of this on runtime! This is the overall idea, I hope you get it, and also there are other cool features I have included in the framework.

### Install Components into your org

##### Deploy to Salesforce Button

<a href="https://githubsfdeploy.herokuapp.com?owner=anyei&repo=SFDC-ATARC">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

##### Manual Install

You may manually create the class within your org and copy paste the content of AsyncTriggerArc class as for the AsyncTriggerArcTest and create the custom settings ATARC_Global_Setting__c and ATARC_Process_Setting__mdt custom metadata type but that's the long path, just use the button above its gonna be easier. 

### Steps to implement this framework

Here a resume of the steps needed to implement this framework:

* Create an instance of the ATARC engine within the trigger.
* Create apex handler class that extends the base class AsyncTriggerArc.AsyncTriggerArcProcessBase.
* Setup a record in ATARC Global Setting custom setting.
* Add a record to the custom metadata type ATARC Process Setting with the appropriate values to make sure the class is picked up by the engine, actually this is how the engine knows what class implementation to use in a specific object/event combination.

But, please read the <a href="https://github.com/anyei/SFDC-ATARC/wiki/ATARC-Phylosophy-(ATARC-BIBLE)">ATARC BIBLE</a> so that you get the phylosophy of the framework. Including the best practices, suggestions and considerations when using ATARC. https://github.com/anyei/SFDC-ATARC/wiki/ATARC-Phylosophy-(ATARC-BIBLE)


## Setup a record in ATARC Global Setting
The custom setting ATARC Global Setting is a hierarchy type of custom setting, you add a default organization value record and populate the Debug, SkipAll and LoopLimit fields. LoopLimit in particular, gives you the ability to define how many times will loop recursion do, which its highly recommended to just set this value to 1. In the other hand, you can turn off all the processes just by setting the SkipAll field to true, false should enable back the processes.


## The simplest form of Implementation & Usage
_____
The first step is to tell the trigger you are using ATARC.
Let's take a look at how the triggers where you want to implement ATARC should be.

####  Create an instance of the ATARC engine within the trigger

With a fresh trigger with no code, you just need to instantiate an ATARC object passing the necessary parameters:

```java
trigger ATARCOpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    AsyncTriggerArc atarc = new AsyncTriggerArc(
                                             trigger.isBefore, 
                                              trigger.isAfter, 
                                              trigger.isInsert, 
                                              trigger.isUpdate, 
                                              trigger.isDelete,
                                              trigger.isUndelete,
                                              trigger.new,
                                              trigger.old,
                                              trigger.newmap, 
                                              trigger.oldmap);
    
    atarc.start();

}
```

In the code above, the constructor accept a bunch of parameters, mainly taken from the **trigger** context variable. The call to the **start** method makes the engine run (this is also very important). Only one trigger is enought and highly recommended, but if you have multiple triggers as well make sure they are attached to different events to make sure you can control the order of execution.

Now that we have our ATARC instance within our trigger, let's build processes to inject them into this trigger. Apex classes should be created and of course extends from a base class.

### Create apex handler class that extends either base classes AsyncTriggerArc.AsyncTriggerArcProcessBase or AsyncTriggerArc.AsyncTriggerArcFEAProcessBase (so the handler class is what we a.k.a atarc process)

This is how you should implement your class.

```java
/*
Created By : anyei
ATARC Process: NameChanger1.0
Created Date : 2020-02-09
*/
public class ChangeNameProcess extends AsyncTriggerArc.AsyncTriggerArcProcessBase{
    
    protected override object execute(AsyncTriggerArc.AsyncTriggerArcContext triggerContext){
       
        //TODO: code
        triggerContext.debug('Process running from ATARC framework engine');
        return null;
    }

}

```

The above apex class is a simple implementation with the base class **AsyncTriggerArc.AsyncTriggerArcProcessBase**, this is a process for ATARC. It is mandatory to extend either base class AsyncTriggerArc.AsyncTriggerArcProcessBase or AsyncTriggerArc.AsyncTriggerArcFEAProcessBase.

The example above doesn't do much, it is writing something to the debug console and then just returning null value. The parameter **triggerContext** is provided by ATARC engine and contains a lot of trigger context variables such as isBefore, isAfter, isInsert etc.

Now in this example, let's put some more functionality to this class, it will change the name of opportunities to 'name changed' (I know this is super silly and not a real or common business scenario but i just want to explain how to implement this ok!).

```java
/*
Created By : anyei
ATARC Process: NameChanger1.0
Created Date : 2020-02-09
*/
public class ChangeNameProcess extends AsyncTriggerArc.AsyncTriggerArcProcessBase {
    
    /*
    *@method
    * executed only a single time from a transaction
    */
    protected override object execute(AsyncTriggerArc.AsyncTriggerArcContext triggerContext)
    {  
        triggerContext.debug('Process running from ATARC framework engine');
        
        List<Opportunity> ops = (List<Opportunity>)triggerContext.newList;
        
        for(Opportunity op : ops){
            op.Name = ' name changed';
        }
        
        return null;
        
    }
    
  

}
```

### Add a record to the custom metadata type "ATARC Process Setting"

The last piece in order to make this work is to hook your apex class into the engine and tell the engine what is the object/event  in which the class will execute.

In the example above our handler apex class is ChangeNameProcess and the trigger object/event executing it is **Opportunity** **Before Insert**. 

So what we need is an entry in the custom metadata type "ATARC Process Setting", This is how the entry should look:

| Label | Custom Metadata Record Name                      | ApexHelperClassName | SObject     | Event        | IsActive | IsAsync | Order | DependsOnSuccess | DependsOnError | Debug | DebugLevel | breakIfError |
|---------------------------|---------------------------|---------------------|-------------|--------------|----------|---------|-------|------------------|----------------|-------|------------|--------------|
| Name Changer | NameChanger1.0            | ChangeNameProcess         | Opportunity | BeforeInsert | true     | false   | 1     |                  |                | true  | DEBUG      | false        |

So, the **Custom Metadata Record Name** (api name is DeveloperName) field is an identifier, you can use this field to give a name to the process but be aware it should respect the custom metadata type name rules (i guess it should be unique and not having double underscores together and so on...), the rest of the fields are sort of self explanatories but i'll include a section dedicated to the meaning of each of these fields later. For now just take a good look at this table.

**Here the custom metadata type and custom setting reference for more info https://github.com/anyei/SFDC-ATARC/wiki/Custom-Setting-Reference**

So.....

And.... we are done setting up. That's it. If you try to insert a new opportunity record, this apex class will be executed by ATARC calling the **execute** method of the class ChangeNameProcess passing in the ATARC's trigger context. This is the simplest scenario. I know there are a lot more complex scenarios related to triggers, I will try to cover some of them in later posts (I'm not sure where to post them, I'll post here later, maybe a blog or something or.. or.. maybe a github page). 


### Issues
Please refer to the <a href="https://github.com/anyei/SFDC-ATARC/issues">Issues</a> section.




