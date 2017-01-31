# ATARC

Inbound request ahead but Opportunity triggers are at their limits!! 

Triggers are flooded with functionalities and salesforce governor limits within DML transactions are a pain in my.... neck, how can i come up with something so that at least let us make some extra space within the transaction to include another process that needs to run within this trigger with a better performance and efficiency?. I think i'm not the only one nor the first one who have asked that question.

Imagine you could found a framework that allows you to fight against the de-facto governor limit situation within transactions. Let me introduce ATARC (heroic music playing in the background). 

I understand there are many good trigger frameworks out there already but I also understand none of them treated the topic as this approach. 

**Please go to our wiki for a more detailed information and api reference!** https://github.com/anyei/SFDC-ATARC/wiki

# What is ATARC

ATARC is a framework or toolset and guidelines (i'm not sure how to call it actually) created with that single purpose in mind, to optimize process executions within triggers hence maximize resources availability within a DML transaction.

With ATARC besides what I just said above, you could control the order of execution of your processes or unit of work, make them active or inactivate whenever the heck you want and last but not least control dependencies execution.... all of this on runtime! This is the overall idea, I hope you get it, and also there are other cool features I have included in the framework.

### Install Components into your org

##### Deploy to Salesforce Button

<a href="https://githubsfdeploy.herokuapp.com?owner=anyei&repo=SFDC-ATARC">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

##### Manual Install

You may manually create the class within your org and copy paste the content of AsyncTriggerArc class as for the AsyncTriggerArcTest and create the custom settings AsyncTriggerArqSettings__c and AsyncTriggerArqModeSettings__c but that's the long path, just use the button above its gonna be easier. 

### Resume of logical steps to implement this framework

Based on friends feedbacks, here a resume of the steps needed to implement this framework:

* Create an instance of the ATARC engine within the trigger.
* Create apex handler class that implements the interface AsyncTriggerArc.IAsyncTriggerArc.
* Add record to the custom setting AsyncTriggerArqSettings, actually this is how the engine knows what helper class to use in a specific object/event combination.

But, please read the <a href="https://github.com/anyei/SFDC-ATARC/wiki/ATARC-Phylosophy-(ATARC-BIBLE)">ATARC BIBLE</a> so that you get the phylosophy of the framework. Including the best practices, suggestions and considerations when using ATARC. https://github.com/anyei/SFDC-ATARC/wiki/ATARC-Phylosophy-(ATARC-BIBLE)



## The simplest form of Implementation & Usage
_____
Because nothing is magic, actually we have to do some setup. The first step is to tell the trigger you are using ATARC.
Let's take a look at how the triggers where you want to implement ATARC should be.

####  Create an instance of the ATARC engine within the trigger (a.k.a atarc engine)

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

In the code above, the constructor accept a bunch of parameters, mainly taken from the **trigger** context variable. The call to the **start** method makes the engine run (this is also very important). Only one trigger is enought but if it works if you have multiple triggers as well but make sure they are attach to different events.

Now that we have our ATARC instance within our trigger, let's build processes to inject them into this trigger. Real apex classes should be created and of course implement a specific interface.

### Create apex handler class that implements the interface AsyncTriggerArc.IAsyncTriggerArc (a.k.a atarc process)

This is how you should implement your helper class.

```java
public class NameChanger implements AsyncTriggerArc.IAsyncTriggerArc {    
    
    public void filter(sObject oldRecord, sObject newRecord, AsyncTriggerArc.AsyncTriggerArcContext triggerContext){
      //called one time per each record
    }
    
    public object execute(AsyncTriggerArc.AsyncTriggerArcContext triggerContext)
    {  
       //calle one time 
        
        return null;
        
    }
    
    public void action(sObject oldRecord, sObject newRecord, AsyncTriggerArc.AsyncTriggerArcContext triggerContext){
      //called one time per each record
    }

}

```

The above apex class is a simple implementation of the interface **AsyncTriggerArc.IAsyncTriggerArc**, this is a process for ATARC. It is mandatory to implement this interface and of course that you have to at least declare an empty place holder for the **filter**, **execute** and **action** methods. For now, just know the three of them plays their role but the execute we could say is the main one as it is the bulkified one. 

The example above doesn't do much, it is just returning null value. The parameter **triggerContext** is provided by ATARC engine and contains a lot of trigger context variables such as isBefore, isAfter, isInsert etc.

Now in this example, let's put some functionality to this class, it will change the name of opportunities to 'name changed' (I know this is super silly and not a real or common business scenario but i just want to explain how to implement this ok!).

```java
public class NameChanger implements AsyncTriggerArc.IAsyncTriggerArc {
    
   
    public void filter(sObject oldRecord, sObject newRecord, AsyncTriggerArc.AsyncTriggerArcContext triggerContext){
      
      //called one time per each record
     
    }
    
    public object execute(AsyncTriggerArc.AsyncTriggerArcContext triggerContext)
    {  
       //called onces within the transaction
        
        List<Opportunity> ops = (List<Opportunity>)triggerContext.newList;
        
        for(Opportunity op : ops){
            op.Name = ' name changer ';
        }
        
        return null;
        
    }
    
    public void action(sObject oldRecord, sObject newRecord, AsyncTriggerArc.AsyncTriggerArcContext triggerContext){
      //called one time per each record
    }

}
```

### Add record to the custom setting AsyncTriggerArqSettings (a.k.a atarc injector)

The last piece in order to make this work is to hook your apex class into the engine and tell the engine what is the trigger executing the class.

In the example above our handler apex class is NameChanger and the trigger executing it is OpportunityBeforeTrigger. 

So what we need is a Custom Setting entry, you should have the custom setting called **AsyncTriggerArqSettings** within this repository. This is how the entry should look:

| Name           | ApexHelperClassName | SObject     | Event        | IsActive | IsAsync | Order | DependsOnSuccess | DependsOnError | Debug | DebugLevel |
|----------------|---------------------|-------------|--------------|----------|---------|-------|------------------|----------------|-------|------------|
| NameChanger1.0 | NameChanger         | Opportunity | BeforeInsert | true     | false   | 1     |                  |                | true  | DEBUG      |

So, the **name** field is just an irrelevant identifier, but you can use this field to give a name to the process, the rest of the fields are sort of self explanatories but i'll include a section dedicated to the meaning of each of these fields later. For now just take a good look at this table.

**Here the custom setting reference for more info https://github.com/anyei/SFDC-ATARC/wiki/Custom-Setting-Reference**

So.....

And.... we are done setting up. That's it. If you try to insert a new opportunity record, this apex class will be executed by ATARC calling the **execute** method of the interface passing in the ATARC's trigger context. This is the simplest scenario. I know there are a lot more complex scenarios related to triggers, I will try to cover some of them in later posts (I'm not sure where to post them, I'll post here later, maybe a blog or something or.. or.. maybe a github page :) ). 


### Issues
Please refer to the <a href="https://github.com/anyei/SFDC-ATARC/issues">Issues</a> section.




