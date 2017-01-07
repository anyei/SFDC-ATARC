# ATARC

Inbound request ahead but Opportunity triggers are at their limits!! 

Triggers are flooded with functionalities and salesforce governor limits are a pain in my.... neck, how can i come up with somethign so that at least let us make some extra space to include another process that needs to run within this trigger?. I think i'm not the only one nor the first one who have asked that question.

Imagine you could found a framework that allows you to fight against the de-facto governor limit situation. Let me introduce ATARC (heroic music playing in the background). 

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

You may manually create the class within your org and copy paste the content of AsyncTriggerArc class as for the AsyncTriggerArcTest and create the custom settings AsyncTriggerArqSettings__c but that's the long path, just use the button above its gonna be esaier. 

### Implementation & Usage
_____
Because nothing is magic, actually we have to do some setup.

#### Implementing with Existing Triggers

#### Implementing with Fresh empty Triggers

#### Custom Settings


### Issues
Please refer to the <a href="https://github.com/anyei/SFDC-ATARC/issues">Issues</a> section.

### Pending
1. Revisit the code to optimize and document better
2. Update the repos readme, is not complete yet.


