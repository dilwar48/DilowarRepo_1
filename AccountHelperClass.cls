/************************************************************
* Created By                 : Jade Global
* Created Date               : 3rd July 2015
* LastModified By            : Vinay Vernekar
* LastModified Date          : 28th July 2015
* Purpose                    : This is used to  
*                              1. create entitlement on account insertion
*                              2. Merge 5 address fields into standard billing field
*                              
* 
* **********************************************************/
public class AccountHelperClass {
/*********************************************************************************************************************************************************************************
 * Purpose                   : This method is called when Parent is updated on account to create account team record for child account's owner
*********************************************************************************************************************************************************************************/    
        public static void createAccountTeamRecord(list<Account> NewRecords,Map<Id,Account> accOldMap){
            
            List<AccountTeamMember> teamMemberList = new List<AccountTeamMember>();
            Set<Id> accIdSet = new Set<Id>();
            
            for(Account acc : NewRecords){
                system.debug('************'+acc.Parentid);
                system.debug(accOldMap.get(acc.Id).ParentId);
                if(acc.Parentid!=null && accOldMap.containsKey(acc.Id) && accOldMap.get(acc.Id).ParentId==null){
                    AccountTeamMember member = new AccountTeamMember(AccountId=acc.ParentId,UserId=acc.ownerId,TeamMemberRole='Sales Engineer');
                    teamMemberList.add(member);
                    accIdSet.add(acc.ParentId);
                }
            }
            
            if(teamMemberList.size()>0 && accIdSet.size()>0){
                
                //Database.insert(teamMemberList,false);
                insert teamMemberList;
                // get all of the team members' sharing records
                List<AccountShare> shares = [select Id, AccountAccessLevel,RowCause 
                                             from AccountShare 
                                             where AccountId IN : accIdSet and RowCause = 'Team'];
                
                // set all team members access to read/write
                if(shares.size()>0 ){
                    for (AccountShare share : shares) { 
                        share.AccountAccessLevel = 'Edit';
                    }
                }
                update shares;
                //Database.update(shares,false);  
                
                
            }
        }

/*********************************************************************************************************************************************************************************
 * Purpose                   : This method is called while creating sold to account. It creates one entitlement and marks as Default entitlement
*********************************************************************************************************************************************************************************/    
        public static void CreateEntitlementRecord(list<Account> NewRecords)
        {
            set<string> AllowedProfiles = AutomationOfEntitlementCreation__c.getall().keyset();
            set<id> ProfileIds = new set<id>();
            for(Profile P : [select id from profile where name in : AllowedProfiles])
                ProfileIds.add(p.id);
            if(profileids.contains(userinfo.getProfileId()))
            {
                list<Entitlement> NewEntitlements = new list<Entitlement>();
                /*
                 * List of Service Contract Overview
                 */
                list<ServiceContractOverview__c> serviceContractOLst = new list<ServiceContractOverview__c>();
                ID SoldToAccId = Schema.SObjectType.Account.RecordTypeInfosByName.get('Sold To').RecordTypeId;
                String SLAName = Label.EntitlementProcessName;
                list<SlaProcess> SLAIds = [select id from SlaProcess where name =: SLAName and IsVersionDefault = true];  //IsVersionDefault = true added as Entitlement versioning has been enabled 
                if(!SLAIds.isEmpty())
                {
                    SlaProcess SLAID = SLAIds.get(0);
                    DateTime dT = System.now();
                    Date StartDate = Date.newinstance(dT.year(), dT.month(), dT.day());
                    Date EndDate = Date.newinstance(2099, dT.month(), dT.day());
                    for(Account Acc: NewRecords)
                    {
                        if(Acc.RecordTypeId == SoldToAccId)
                        {
                            Entitlement Ent = new Entitlement(
                                        SlaProcessId = SLAID.id,
                                        Accountid = Acc.id,
                                        StartDate = StartDate,
                                        EndDate = EndDate,
                                        Name = Acc.Name+'-MPA',
                                        DefaultEntitlement__c = true
                            );
                            /*
                             * To create ServiceContractOverview__c record for each MPA entitlement record
                             */
                            ServiceContractOverview__c SCOverview = new ServiceContractOverview__c(
                                        Account__c = Acc.id,
                                        StartDate__c = StartDate,
                                        EndDate__c= EndDate,
                                        Name = Acc.Name+'-MPA'
                                        //Status__c = 'Active'
                            );
                            NewEntitlements.add(Ent);
                            serviceContractOLst.add(SCOverview);
                        }//END IF
                    }//END FOR
                    if(!NewEntitlements.isEmpty())
                        insert NewEntitlements;
                    if(!serviceContractOLst.isEmpty())
                        insert serviceContractOLst;
                }
            }
        }//END METHOD

/*********************************************************************************************************************************************************************************
 * Purpose                   : This method is called while creating or updating Ship to account. It merges five address fields into shtandard Shipping street.
*********************************************************************************************************************************************************************************/ 
    public static void MergeIntoBillingAddress(list<account> NewRecords)
    {
        id ShipToID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Ship To').getRecordTypeId();
        for(Account SingleAccount : NewRecords)
        {
            if((SingleAccount.Address1__c!=null || SingleAccount.Address2__c!=null || SingleAccount.Address3__c != null || SingleAccount.Address4__c != null || SingleAccount.Address5__c!=null) && SingleAccount.SAP_Sold_To_Id__c == null && SingleAccount.RecordTypeId == ShipToID)
            {
                if(SingleAccount.Address1__c!=null)
                    SingleAccount.ShippingStreet = SingleAccount.Address1__c;
                if(SingleAccount.Address2__c!=null)
                    SingleAccount.ShippingStreet = SingleAccount.ShippingStreet +', '+SingleAccount.Address2__c;
                if(SingleAccount.Address3__c!=null)
                    SingleAccount.ShippingStreet = SingleAccount.ShippingStreet +', '+SingleAccount.Address3__c;
                if(SingleAccount.Address4__c!=null)
                    SingleAccount.ShippingStreet = SingleAccount.ShippingStreet +', '+SingleAccount.Address4__c;
                if(SingleAccount.Address5__c!=null)
                    SingleAccount.ShippingStreet = SingleAccount.ShippingStreet +', '+SingleAccount.Address5__c;
            }//END IF
      
        }//END FOR
        
    }//END METHOD
    
    public static void CreateServiceAccountOnSoldTo(list<Account> NewList)
    {
       set<string> AllowedProfiles = AutomationOfEntitlementCreation__c.getall().keyset();
       set<id> ProfileIds = new set<id>();
       for(Profile P : [select id from profile where name in : AllowedProfiles])
       ProfileIds.add(p.id);
       if(profileids.contains(userinfo.getProfileId()))
       {
        List<Account> ServiceAccounts = new List<Account>();
        ID SoldToAccId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Sold To').getRecordTypeId();
        ID ServiceAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Account').getRecordTypeId();
        for(Account AllAccs : NewList)
        {
            if(AllAccs.recordtypeid == SoldToAccId)
            {
                ServiceAccounts.add(new Account(recordtypeid = ServiceAccountId,
                                                name = AllAccs.name,
                                                AccountType__c = 'Service Account',
                                                Parentid = AllAccs.id,
                                                SAP_Sold_To_Id__c = (AllAccs.SAP_Sold_To_Id__c == null ? '' : AllAccs.SAP_Sold_To_Id__c+'_S')));
            }//END IF
        }//END FOR
        if(!ServiceAccounts.isEmpty())
            insert ServiceAccounts;
       }
    }//END METHOD
    public static void AutopopulateAccountForPSEAccess(list<account> newAccountList){
        for(Account acc : newAccountList){
            if(acc.RecordtypeID == label.ServiceAccountRecordTypeID && acc.AccountType__c == 'Service Account'){
                acc.AccountForPSEAccess__C = label.AccountForPSEAccess;
            }//End of if
        }//End of for
    }//End of method
    
    /**************************************************************************
       Purpose: Assign Last Modified By User and Last Modified Date (Custom fields)
       Parameters: listAccounts - List of accounts (From Trigger)
       Returns:
       Throws [Exceptions]: 
    ****************************************************************************/
    public static void AutopopulateLastModifiedByDetail(List<Account> listAccounts){
        if(!PreventRunningLogic__c.getInstance(System.UserInfo.getUserId()).DontRunLogic__c){
            if(!listAccounts.isEmpty()){
                for(Account objAccount:listAccounts){
                    objAccount.Last_Modified_By_User__c = System.UserInfo.getUserId();
                    objAccount.LastModifiedDate__c =  System.Now();
                }
            }
        }
    }
    
    
    
    /**********************************************************************************************************
    * Modified By           :   Jade Global
    * Parameters            :   listNewAccount - List of new Account (Trigger.New)
                                mapOldAccount  - Map of old Account (Trigger.oldMap)
    * Returns               :
    * Throws [Exceptions]   :
    * Purpose/Description   :   This method is to update Account team alias email on all related Opportunity records
    *                           when the Sales Team email alias is changed
    **********************************************************************************************************/
    public static void updateOpportunityAccountAliasEmail(List<Account> listNewAccount, Map<Id, Account> mapOldAccount){  
        
        try{
            set<Id> accIds = new set<Id>();
            list<Opportunity> oppList = new list<Opportunity>();
            
                for(Account accObj : listNewAccount){
                if(accObj.Sales_Team_Email_Alias__c != null && accObj.Sales_Team_Email_Alias__c != mapOldAccount.get(accObj.Id).Sales_Team_Email_Alias__c){
                    accIds.add(accObj.Id);
                }
            }
           system.debug('accIds:' + accIds );
            if(accIds.size() > 0){
                
                set<String> excludeStageNames = new set<String>{'Closed Won','Closed Lost'};
                oppList = [select id,Account_Team_Alias__c,Account.Sales_Team_Email_Alias__c from Opportunity where AccountId in: accIds and StageName not in: excludeStageNames];
                system.debug('oppList: '+oppList);
                if(oppList.size() > 0){
                    
                    for(Opportunity oppObj : oppList){
                        oppObj.Account_Team_Alias__c = oppObj.Account.Sales_Team_Email_Alias__c;
                    }
                    
                    database.update(oppList,false);
                }
            }
        }
        catch(Exception ex){
            system.debug('-----Exception occurred-----'+ex);
        }
        
    }
    
     /**********************************************************************************************************
    * Modified By           :   Jade Global
    * Parameters            :   listNewAccount - List of new Account (Trigger.New)
                                mapOldAccount  - Map of old Account (Trigger.oldMap)
    * Returns               :
    * Throws [Exceptions]   :
    * Purpose/Description   :   This method is for when Annual Revenue field is filled by Data.com, then the *corresponding range in the Annual Revenue Range field value is selected and overwrites the value that was  *previously on the Annual Revenue Range field.
    **********************************************************************************************************/
    public static void populateValueInAnnualRevenue(List<Account> listNewAccount, Map<Id, Account> mapOldAccount){
    
        
        for(Account accountObj : listNewAccount ){
                if(accountObj.AnnualRevenue != null && accountObj.AnnualRevenue != mapOldAccount.get(accountObj.id).AnnualRevenue){
                    if( accountObj.AnnualRevenue > 1000000 && accountObj.AnnualRevenue < 10000000 ){
                        //accountObj.Annual_Revenue__c = '<$10M';
                    }
                    else if(accountObj.AnnualRevenue >= 10000000.1 && accountObj.AnnualRevenue <= 25000000 ){
                      //accountObj.Annual_Revenue__c = '$10.1 - $25M' ;
                    }
                    else if(accountObj.AnnualRevenue > = 25000000.1 && accountObj.AnnualRevenue <= 100000000 ){
                        //accountObj.Annual_Revenue__c = '$25.1 - $100M' ;
                    }
                    else if(accountObj.AnnualRevenue >= 100000000.1 && accountObj.AnnualRevenue <= 500000000 ){
                        //accountObj.Annual_Revenue__c = '$100.1 - $500M' ;
                    }
                    else if(accountObj.AnnualRevenue >= 500000000.1 && accountObj.AnnualRevenue <= 1000000000 ){
                        //accountObj.Annual_Revenue__c = '$501.1 - $1B' ;
                    }       
                    else if(accountObj.AnnualRevenue > 1000000000.1 )
                    {
                        //accountObj.Annual_Revenue__c = '>$1B' ;
                    }
                    else
                    {
                        //accountObj.Annual_Revenue__c = null;
                    }
                }
        }
    
    }
    
     /**********************************************************************************************************
    * Modified By           :   Jade Global
    * Parameters            :                                
    * Returns               :
    * Throws [Exceptions]   :
    * Purpose/Description   :   This method is to update Geo Marketing Region on Account based on Country when
    *                           Account record is created/updated
    **********************************************************************************************************/
    public static void updateMarketingGeoBasedOnCountry(List<Account> listNewAccount, Map<Id, Account> mapOldAccount){  
        
        try{
            
            Map<String,String> countryNameRegionMap = new Map<String,String>();
            Map<String, CountryRegionMapping__c> countryRegionSettingMap = CountryRegionMapping__c.getAll();
            
            if(countryRegionSettingMap != null && countryRegionSettingMap.size() > 0){
                for(CountryRegionMapping__c countryRegionObj : countryRegionSettingMap.values()){
                    countryNameRegionMap.put(countryRegionObj.Name__c,countryRegionObj.Region__c);
                }
            }
            
            for(Account accountObj : listNewAccount){
            system.debug('-----accountObj-----'+accountObj);
                
                //Logic for Accounts created/updated via salesforce UI
                if(accountObj.BillingCountryCode != null){
                    
                    //Logic for Accounts created/updated via salesforce UI
                    if (trigger.isInsert || (trigger.isUpdate && accountObj.BillingCountryCode != mapOldAccount.get(accountObj.Id).BillingCountryCode) ) {
                        CountryRegionMapping__c countryRegionObj = CountryRegionMapping__c.getValues(accountObj.BillingCountryCode);
                        system.debug('-----countryRegionObj-----'+countryRegionObj);
                        if(countryRegionObj != null){
                            accountObj.Geo_Location__c = countryRegionObj.Region__c;
                        }
                    }
                    //Logic for Accounts updated via APIs - Data Loader, External system, etc
                    else if (trigger.isUpdate && accountObj.BillingCountry != null && accountObj.BillingCountry != '' && accountObj.BillingCountry != mapOldAccount.get(accountObj.Id).BillingCountry){
                        if (trigger.isUpdate && countryNameRegionMap.containsKey(accountObj.BillingCountry)){
                            accountObj.Geo_Location__c = countryNameRegionMap.get(accountObj.BillingCountry);
                        }
                    }
                }
                else if(accountObj.BillingCountry != null && accountObj.BillingCountryCode == null){
                    //Logic for Accounts created via APIs - Data Loader, External system, etc
                    if (trigger.isInsert && countryNameRegionMap.containsKey(accountObj.BillingCountry)){
                        accountObj.Geo_Location__c = countryNameRegionMap.get(accountObj.BillingCountry);
                    }
                    //Logic to clean the Marketing Geo Loaction field when Country field is updated to blank/not valued via Salesforce UI
                    else if(trigger.isUpdate && (accountObj.BillingCountryCode == null || accountObj.BillingCountryCode == '')){
                        accountObj.Geo_Location__c = '';
                    }
                }       
            }
        }
        catch(Exception ex){
            system.debug('-----Exception occurred-----'+ex);
        }  
    }
    
      /**********************************************************************************************************
    * Modified By           :   Jade Global
    * Parameters            :                                
    * Returns               :
    * Throws [Exceptions]   :
    * Purpose/Description   :   This method is to associate Sold To Account to Customer Hierarchy Account based 
    *                           on SAP Id field when the Sold Account record is created/updated
    **********************************************************************************************************/
    public static void associateToCustomerHierarchy(List<Account> listNewAccount, Map<Id, Account> mapOldAccount){  
     list<Account> listSoldToAccounts = new list<Account>();
     list<account> listCustomerhierarchyAcc = new list<Account>();
     list<account> newAccAssociation = new list<account>();
     set<String> HierarchyAccountIds = new set<String>();
     Map<String,Account> mapCustomerHierarchy = new Map<String,Account>();
     Map<String,Account> newCustomerHierarchyAcc = new Map<String,Account>();
     ID SoldToAccId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Sold To').getRecordTypeId();
     ID CustomerHierarchyId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Hierarchy').getRecordTypeId();

        for(Account acc: listNewAccount){
            if(acc.recordTypeid == SoldToAccId && acc.SAP_Id__c != null && acc.SAPExternalId__c != null && acc.Customer_Hierarchy_Name__c != null){
                
                system.debug('*****InsideNewList***'+acc);
                HierarchyAccountIds.add(acc.SAP_Id__c);  
                listSoldToAccounts.add(acc);
            }//End of IF
            
        }//End of FOR   
       system.debug('*****Before IF Hierarchy Acc***'+HierarchyAccountIds); 
        if(!HierarchyAccountIds.isEmpty()){
          listCustomerhierarchyAcc = [Select Id,Name,SAP_Id__c,SAPExternalId__c,RecordTypeId,SAP_Sold_To_Id__c from Account where SAP_Sold_To_Id__c IN :HierarchyAccountIds and RecordTypeId = :CustomerHierarchyId]; 
          system.debug('*****Query Data***'+listCustomerhierarchyAcc); 
            if(!listCustomerhierarchyAcc.isEmpty()){
              for(Account a: listCustomerhierarchyAcc){
                 mapCustomerHierarchy.put(a.SAP_Sold_To_Id__c,a); 
              }//End of FOR
            }//End of IF  
              if(!listSoldToAccounts.isEmpty()){
                  for(Account a:listSoldToAccounts){
                     if(!mapCustomerHierarchy.isEmpty() && mapCustomerHierarchy.containsKey(a.SAP_Id__c)){
                        a.ParentId = mapCustomerHierarchy.get(a.SAP_Id__c).id;   
                     }else{
                        system.debug('*****New Customer hierarchy Account***'); 
                        account newAcc = new account();
                        newAcc.RecordTypeId = CustomerHierarchyId;
                        newAcc.Name = a.Customer_Hierarchy_Name__c;
                        newAcc.SAP_Sold_To_Id__c = a.SAP_Id__c;
                        newAcc.SAPExternalId__c = a.SAP_Id__c+'CustId';
                        newCustomerHierarchyAcc.put(a.SAP_Id__c,newAcc);
                        newAccAssociation.add(a);
                     }//End of IF-ELSE 
                  }//End of FOR
                  
                  if(!newCustomerHierarchyAcc.isEmpty() && newCustomerHierarchyAcc != null){
                      insert newCustomerHierarchyAcc.values();
                      for(Account a :newAccAssociation ){
                          if(newCustomerHierarchyAcc.containsKey(a.SAP_Id__c)){
                              system.debug('*****Customer hierarchy Account association***'); 
                              a.ParentId = newCustomerHierarchyAcc.get(a.SAP_Id__c).Id;
                          }//End of IF
                      }//End of FOR
                  }//End of IF                
              }//End of IF
        }//End of IF
    }//End of Method
    
/**********************************************************************************************************
    * Modified By           :   Jade Global
    * Parameters            :                                
    * Returns               :
    * Throws [Exceptions]   :
    * Purpose/Description   :   This method is used to call ProspectAccountApproval Approval process.
    **********************************************************************************************************/
    public static void callProspectAccountApproval(List<Account> listNewAccount){
        ID SoldToAccId = Schema.SObjectType.Account.RecordTypeInfosByName.get('Sold To').RecordTypeId;
        for(Account accObj: listNewAccount){
            system.debug('--accObj--'+accObj);
            if(accObj.RecordTypeId == SoldToAccId){
                system.debug('--Entered If accObj--'+accObj);
                if(accObj.Current_Customer__c != null && accObj.SAP_Sold_To_Id__c == null && accObj.Current_Customer__c == 'Prospect'){
                    system.debug('--Entered second If accObj--'+accObj);
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setObjectId(accObj.Id);
                    req.setComments('Sold To Account Submitted for approval');
                    Approval.ProcessResult result = Approval.process(req);
                }
            }
        }
    }//End of Method
     /*********************************************************************************************************************************************************************************
 * Purpose   :  This method is called while updating a sold to account. 
                If the Current Customer field gets updated from Prospect to Customer and the 
                Sold to does not already have an MPA Entitlement in it.
                It creates one MPA Entitlement and marks as Default entitlement.
                
 * Parameter :  list<Account> NewRecords, Map<Id, Account> oldAccountMap
 * Return    :  Void
*********************************************************************************************************************************************************************************/    
        public static void CreateEntitlementOnAccountUpdate(list<Account> NewRecords, Map<Id, Account> oldAccountMap)
        {
            Set<id> accountIds = new Set<Id>();
            //set<string> AllowedProfiles = AutomationOfEntitlementCreation__c.getall().keyset();
            /*set<string> AllowedProfiles = new set<String>();
            AllowedProfiles.add('Integration User');
            AllowedProfiles.add('Power User');
            set<id> ProfileIds = new set<id>();*/
            for(Account acc: NewRecords){
                if(acc.Current_Customer__c != NULL && acc.Current_Customer__c == 'Customer' 
                    && oldAccountMap.get(acc.id).Current_Customer__c != acc.Current_Customer__c 
                        && oldAccountMap.get(acc.id).Current_Customer__c == 'Prospect' && acc.SAP_Sold_To_Id__c != NULL){
                            accountIds.add(acc.id);
                        }
                
            }
            if(!accountIds.isEmpty()){
                List<AggregateResult> lstEntitlements = [select count(Id),Accountid from Entitlement where Accountid IN :accountIds and DefaultEntitlement__c = true group by Accountid];
                if(lstEntitlements.isEmpty()){
                   /* for(Profile P : [select id from profile where name in : AllowedProfiles]){
                        ProfileIds.add(p.id);
                    }
                    if(profileids.contains(userinfo.getProfileId()))
                    {*/
                        list<Entitlement> NewEntitlements = new list<Entitlement>();
                        /*
                         * List of Service Contract Overview
                         */
                        list<ServiceContractOverview__c> serviceContractOLst = new list<ServiceContractOverview__c>();
                        ID SoldToAccId = Schema.SObjectType.Account.RecordTypeInfosByName.get('Sold To').RecordTypeId;
                        String SLAName = Label.EntitlementProcessName;
                        list<SlaProcess> SLAIds = [select id from SlaProcess where name =: SLAName and IsVersionDefault = true];  //IsVersionDefault = true added as Entitlement versioning has been enabled 
                        if(!SLAIds.isEmpty())
                        {
                            SlaProcess SLAID = SLAIds.get(0);
                            DateTime dT = System.now();
                            Date StartDate = Date.newinstance(dT.year(), dT.month(), dT.day());
                            Date EndDate = Date.newinstance(2099, dT.month(), dT.day());
                            for(Account Acc: NewRecords)
                            {
                                if(Acc.RecordTypeId == SoldToAccId)
                                {
                                    Entitlement Ent = new Entitlement(
                                                SlaProcessId = SLAID.id,
                                                Accountid = Acc.id,
                                                StartDate = StartDate,
                                                EndDate = EndDate,
                                                Name = Acc.Name+'-MPA',
                                                DefaultEntitlement__c = true
                                    );
                                    /*
                                     * To create ServiceContractOverview__c record for each MPA entitlement record
                                     */
                                    ServiceContractOverview__c SCOverview = new ServiceContractOverview__c(
                                                Account__c = Acc.id,
                                                StartDate__c = StartDate,
                                                EndDate__c= EndDate,
                                                Name = Acc.Name+'-MPA'
                                                //Status__c = 'Active'
                                    );
                                    NewEntitlements.add(Ent);
                                    serviceContractOLst.add(SCOverview);
                                }//END IF
                            }//END FOR
                            if(!NewEntitlements.isEmpty())
                                insert NewEntitlements;
                            if(!serviceContractOLst.isEmpty())
                                insert serviceContractOLst;
                        }
                   // }
                }
            }
        }//END METHOD
         
    /*************************************************************************************************************************************
    ***
    Method Description: This method gets called if a SoldTo Account gets updated and Current Customer field gets 
                        changed to 'Customer' from 'Prospect'. A service Account gets created automatically making 
                        the SoldTo Account as Parent.
                         
    Method Param:       list<Account> NewList, Map<Id, Account> oldMap
    Method Return:      None
    ***
    ****************************************************************************************************************************/
    
    public static void CreateServiceAccountOnSoldToOnUpdate(list<Account> NewList, Map<Id, Account> oldAccountMap)
    {
        Set<id> accountIds = new Set<Id>();
        List<Account> updatedAccount = new List<Account>();
        List<Account> lstServiceAccounts = new List<Account>();
        //set<string> AllowedProfiles = AutomationOfEntitlementCreation__c.getall().keyset();
        /*set<string> AllowedProfiles = new set<String>();
        AllowedProfiles.add('Integration User');
        AllowedProfiles.add('Power User');*/
        List<Account> ServiceAccounts = new List<Account>();
        ID SoldToAccId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Sold To').getRecordTypeId();
        ID ServiceAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Account').getRecordTypeId();
        
        for(Account acc: NewList){
           if(acc.RecordTypeId == SoldToAccId && acc.Current_Customer__c != NULL && acc.Current_Customer__c == 'Customer' 
                && oldAccountMap.get(acc.id).Current_Customer__c != acc.Current_Customer__c 
                    && oldAccountMap.get(acc.id).Current_Customer__c == 'Prospect' && acc.SAP_Sold_To_Id__c != NULL){
                        accountIds.add(acc.id);
                        updatedAccount.add(acc);
            }
                
        }
        if(!accountIds.isEmpty()){
            //List<RecordType> serAccTypeid = [select id, name from RecordType where sObjectType = 'Account' and name = 'Service Account'];
            //lstServiceAccounts = [Select id, name, ServiceAccount__c, parentId from Account where parentId in :accountIds AND recordTypeId = :serAccTypeid[0].id];
            List<AggregateResult> lstAccounts = [Select ParentId,Count(Id) from Account where parentId IN :accountIds and recordTypeId = :ServiceAccountId group by parentid];
            if(lstAccounts.isEmpty()){
                /*set<id> ProfileIds = new set<id>();
                for(Profile P : [select id from profile where name in : AllowedProfiles]){
                    ProfileIds.add(p.id);
                } 
                system.debug('Profile Ids are:' +ProfileIds);
                system.debug('User Profile Id is:' +userinfo.getProfileId()); */
                
                    for(Account AllAccs : updatedAccount)
                    {
                        system.debug('Yes 1');
                        ServiceAccounts.add(new Account(recordtypeid = ServiceAccountId,
                                                        name = AllAccs.name,
                                                        AccountType__c = 'Service Account',
                                                        Parentid = AllAccs.id,
                                                        SAP_Sold_To_Id__c = (AllAccs.SAP_Sold_To_Id__c == null ? '' : AllAccs.SAP_Sold_To_Id__c+'_S'),
														SAPExternalId__c = (AllAccs.SAP_Sold_To_Id__c == null ? '' : AllAccs.SAP_Sold_To_Id__c+'_S')));
                    }//END FOR
                     system.debug('Service Account is:' +ServiceAccounts);
                    if(!ServiceAccounts.isEmpty()){
                        insert ServiceAccounts;
                    }
               }
        }
    }//END METHOD
    /*************************************************************************************************************************************
    ***
    Method Description: This method updates the Customer_Currency__c (Customer currency) field with CurrencyISOCode
                        (Account Currency) field values.
                         
    Method Param:       List<Account> newAccounts, Map<Id, Account> oldAccounts
    Method Return:      None
    ***
    ****************************************************************************************************************************/
    
    public static void updateCustomerCurrencyValue(List<Account> newAccounts, Map<id, Account> mapAccount){
        Set<id> accountIDS = new Set<ID>();
        List<Account> accountsRetrieved = new List<Account>();
        List<Account> accountsToUpdate = new List<Account>();
        for(Account acc: newAccounts){
            if(acc.currencyISOCode != acc.customer_currency__c || (mapAccount!=null && mapAccount.containsKey(acc.id)&&mapAccount.get(acc.id) != NULL && 
                (mapAccount.get(acc.id).currencyISOCode != acc.currencyISOCode ||
                mapAccount.get(acc.id).customer_currency__c != acc.customer_currency__c))){
                //accountIDS.add(acc.id);
                acc.customer_currency__c = acc.currencyISOCode;
            }
        }
       /* if(!accountIDS.isEmpty()){
            accountsRetrieved = [select id, name, currencyISOCode, customer_currency__c from Account where id = :accountIDS];
            for(Account accU : accountsRetrieved){
                accU.customer_currency__c = accU.currencyISOCode;
                accountsToUpdate.add(accU);
                
            }
            if(!accountsToUpdate.isEmpty()){
                update accountsToUpdate;
                
            }
        }*/
    }
         /*************************************************************************************************************************************
    ***
    Method Name       : updateServiceAccountOnSoldToOnUpdate
    Method Description: This method gets invoked, when the SOLD TO Account gets updated with new SAP_Sold_TO_ID, the respective 
                        service accounts gets updated with similar SAP_Sold_To_IDs appended with '_s'.
                         
    Method Param:       list<Account> NewList, Map<Id, Account> oldMap
    Method Return:      None
    ***
    ****************************************************************************************************************************/
public static void updateServiceAccountOnSoldToOnUpdate(list<Account> NewList, Map<Id, Account> oldAccountMap)
    {
        List<Account> updatedAccount = new List<Account>();
        List<Account> lstServiceAccounts = new List<Account>();
        Map<ID, Account> mapSoldToAccount = new Map<ID, Account>();
        List<Account> ServiceAccounts;
        List<Account> serviceAccountsToUpdate = new List<Account>();
        ID SoldToAccId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Sold To').getRecordTypeId();
        ID ServiceAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Account').getRecordTypeId();
        
        for(Account acc: NewList){
           if(acc.RecordTypeId == SoldToAccId && acc.SAP_Sold_To_Id__c != NULL && String.valueOf(acc.SAP_Sold_To_Id__c).startsWith('1') 
                && oldAccountMap != NULL && oldAccountMap.get(acc.id).SAP_Sold_To_Id__c != acc.SAP_Sold_To_Id__c 
                    && String.valueOf(oldAccountMap.get(acc.id).SAP_Sold_To_Id__c).startsWith('9')){
                        mapSoldToAccount.put(acc.id, acc);
            }      
        }
        if(mapSoldToAccount != NULL){
            lstServiceAccounts = [Select id,ParentId, SAP_Sold_To_Id__c from Account where parentId IN :mapSoldToAccount.keySet() and recordTypeId = :ServiceAccountId];
            for(Account serviceAcc: lstServiceAccounts){
                serviceAcc.SAP_Sold_To_Id__c = mapSoldToAccount.get(serviceAcc.ParentId).SAP_Sold_To_Id__c+'_S';
                serviceAcc.SAPExternalId__c = mapSoldToAccount.get(serviceAcc.ParentId).SAP_Sold_To_Id__c+'_S';
                serviceAccountsToUpdate.add(serviceAcc);
            }
            if(!serviceAccountsToUpdate.isEmpty()){
                update serviceAccountsToUpdate;
            }
        }
    }//END METHOD
    
    
} //END HELPER CLASS