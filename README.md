# ATARC

Inbound request ahead but Opportunity triggers are at their limits!! 

Triggers are flooded with functionalities and salesforce governor limits are a pain in my.... neck, how can i come up with something so that at least let us make some extra space to include another process that needs to run within this trigger?. I think i'm not the only one nor the first one who have asked that question.

Imagine you could found a framework that allows you to fight against the de-facto governor limit situation. Let me introduce ATARC (heroic music playing in the background). 

I understand there are many good trigger frameworks out there already but I also understand none of them treated the topic as this approach.

# What is ATARC

ATARC is a framework or toolset and guideline (i'm not sure how to call it actually) created with that single purpose in mind, to optimize process executions within triggers hence maximize resources availability within a transaction.

With ATARC besides what I just said above, you could control the order of execution of your processes or unit of work, make them active or inactivate whenever the heck you want and last but not least control dependencies execution.... all of this on runtime! This is the overall idea, i hope you get it.

### Install

##### Deploy to Salesforce Button

<a href="https://githubsfdeploy.herokuapp.com?owner=anyei&repo=SFDC-ATARC">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

##### Manual Install

You may manually create the class within your org and copy paste the content of AsyncTriggerArc class as for the AsyncTriggerArcTest and create the custom settings AsyncTriggerArqSettings__c but that's the long path, just use the button above its gonna be easier. 

### The simplest form of Implementation & Usage
_____
Because nothing is magic, actually we have to do some setup. The first step is to tell the trigger you are using ATARC.
Let's take a look at how the triggers where you want to implement ATARC should be.

####  Implementing with Fresh empty Triggers

With a fresh trigger with no code, you just need to instantiate an ATARC object passing the necessary parameters:

```java
trigger OpportunityBeforeTrigger on Opportunity (before insert) {
    
    AsyncTriggerArc atarc = new AsyncTriggerArc('OpportunityBeforeTrigger',
                                             trigger.isBefore, 
                                              trigger.isAfter, 
                                              trigger.isInsert, 
                                              trigger.isUpdate, 
                                              trigger.isDelete,
                                              trigger.new,
                                              trigger.old,
                                              trigger.newmap, 
                                              trigger.oldmap);
    
    atarc.start();

}
```

In the code above, the constructor accept a bunch of parameters, mainly taken from the **trigger** context variable. The first argument is actually very important, it is the name of the current trigger, in this case is **OpportunityBeforeTrigger**. The call to the **start** method makes the engine run (this is also very important). 

Now that we have our ATARC instance within our trigger, let's build processes to inject them into this trigger. Real apex classes should be created and of course implement a specific interface.

### Apex Classes (processes)

This is how you should implement your helper class.

```java
public class NameChanger implements AsyncTriggerArc.IAsyncTriggerArc {    
    
    public object execute(AsyncTriggerArc.AsyncTriggerArcContext triggerContext)
    {  
       
        
        return null;
        
    }

}

```

The above apex class is a simple implementation of the interface **AsyncTriggerArc.IAsyncTriggerArc**. It is mandatory to implement this interface. So far it doesn't do much, it is just returning null. The parameter **triggerContext** is provided by ATARC engine and contains a lot of trigger context variables such as isBefore, isAfter, isInsert etc.

Now in this example, let's put some functionality to this class, it will change the name of opportunities to 'name changed' (I know this is super silly and not a real or common business scenario but i just want to explain how to implement this ok!).

```java
public class NameChanger implements AsyncTriggerArc.IAsyncTriggerArc {
    
    
    public object execute(AsyncTriggerArc.AsyncTriggerArcContext triggerContext)
    {  
        Map<id, Opportunity> ops = (Map<id, Opportunity>)ops;
        
        for(Opportunity op : ops.values()){
            op.Name = ' name changer ';
        }
        
        return null;
        
    }

}
```

The last piece in order to make this work is to hook this class into the engine and tell the engine OpportunityBeforeTrigger is who will execute this class or process (let's call it process). So the way to hook this up to the trigger is via a Custom Setting entry, you should have a custom setting called **AsyncTriggerArqSettings**. This is how the entry should look:

| name           | ApexHelperClassName | SObject     | ApexTriggerName          | Event        | IsActive | isAsync | Order | breakIfError | DependsOn |
|----------------|---------------------|-------------|--------------------------|--------------|----------|---------|-------|--------------|-----------|
| NameChanger1.0 | NameChanger         | Opportunity | OpportunityBeforeTrigger | BeforeInsert | true     | false   | 1     | true         |           |
|                |                     |             |                          |              |          |         |       |              |           |
|                |                     |             |                          |              |          |         |       |              |           |

So, the **name** field is just an irrelevant identifier, but you can use this field to give a name to the process, the rest of the fields are sort of self explanatories but i'll include a section dedicated to the meaning of each of these fields later. For now just take a good look at this table.

If you were to have more apex classes (processes) to hook them into the trigger, you will need to add multiple entries to the custom setting.. this is how it would look.

| name | ApexHelperClassName | SObject | ApexTriggerName | Event | IsActive | isAsync | Order | breakIfError | DependsOn |
|---------------------------|---------------------|-------------|--------------------------|--------------|----------|---------|-------|--------------|-----------|
| NameChanger1.0 | NameChanger | Opportunity | OpportunityBeforeTrigger | BeforeInsert | true | false | 1 | true |  |
| WinProbabilityCalc | ProCalculator | Opportunity | OpportunityBeforeTrigger | BeforeInsert | true | false | 2 | false |  |
| ComplexNotificationCenter | ComplexNotifyier | Opportunity | OpportunityAfterTrigger | AfterInsert | true | false | 1 | true |  |

In the above example, there are more custom setting entries now and if you look closer there is an **order** field which tells the engine what is the order of execution of each apex class (process). 

So.....

And.... we are done setting up. That's it. If you try to insert a new opportunity record, this apex class will be executed by ATARC calling the **execute** method of the interface passing in the ATARC's trigger context. This is the simplest scenario. I know there are a lot more complex scenarios related to triggers, I will try to cover some of them in later posts (I'm not sure where to post them, i'll post here later, maybe a blog or something or.. or.. maybe a github page :) ). 


### Issues
Please refer to the <a href="https://github.com/anyei/SFDC-ATARC/issues">Issues</a> section.

### Pending
1. Revisit the code to optimize and document better
2. Update the repos readme, is not complete yet.
3. Test this with delete triggers.


