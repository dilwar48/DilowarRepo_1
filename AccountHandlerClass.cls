/************************************************************
* Created By                 : Jade Global
* Created Date               : 3rd July 2015
* LastModified By            : Vinay Vernekar
* LastModified Date          : 28th July 2015
* Purpose                    : This is used to  
*                              1. CreateEntitlementRecord - create entitlement on account insertion 
*                              2. MergeIntoBillingAddress - Merge 5 address fields into standard billing field
*                              
* 
* **********************************************************/

public class AccountHandlerClass {

    
    /***----------------------------------------------------------------------------------------------------------------------------------
    BEFORE INSERT HANDLER----PLACE HERE YOUR CODE TO BE EXECUTE BEFORE INSERTING THE RECORDS
    -----------------------------------------------------------------------------------------------------------------------------------***/ 
    public static void beforeInsertHandler(List<Account> newList, Map<Id,Account> newMap, List<Account> oldList, Map<Id,Account> oldMap){  
      //Merge 5 address fields into standard billing field
        AccountHelperClass.MergeIntoBillingAddress(newList);
        AccountHelperClass.AutopopulateAccountForPSEAccess(newList);
        
        // Assign Last Modified By User and Last Modified Date (Custom fields)
        AccountHelperClass.AutopopulateLastModifiedByDetail(newList);
      AccountHelperClass.updateMarketingGeoBasedOnCountry(newList,oldMap);
      AccountHelperClass.associateToCustomerHierarchy(newList,oldMap);
    }
    
    /***-----------------------------------------------------------------------------------------------------------
    BEFORE UPDATE HANDLER----PLACE HERE YOUR PROCESS TO BE EXECUTE BEFORE UPDATING THE RECORDS
    ---------------------------------------------------------------------------------------------------------------***/ 
    public static void beforeUpdateHandler(List<Account> newList, Map<Id,Account> newMap, List<Account> oldList, Map<Id,Account> oldMap){
            //Merge 5 address fields into standard billing field
            AccountHelperClass.MergeIntoBillingAddress(newList);
            
            // Assign Last Modified By User and Last Modified Date (Custom fields)
            AccountHelperClass.AutopopulateLastModifiedByDetail(newList);
            AccountHelperClass.populateValueInAnnualRevenue(newList,oldMap);
            AccountHelperClass.updateMarketingGeoBasedOnCountry(newList,oldMap);
            AccountHelperClass.associateToCustomerHierarchy(newList,oldMap);
            AccountHelperClass.CreateEntitlementOnAccountUpdate(newList,oldMap);
            AccountHelperClass.CreateServiceAccountOnSoldToOnUpdate(newList,oldMap);
    }
    
    /***-----------------------------------------------------------------------------------------------------------
    BEFORE DELETE HANDLER----PLACE HERE YOUR PROCESS TO BE EXECUTE BEFORE DELETING THE RECORDS
    ---------------------------------------------------------------------------------------------------------------***/   
    public static void beforeDeleteHandler(List<Account> oldList, Map<Id,Account> oldMap){
       
    }
    
    /***-----------------------------------------------------------------------------------------------------------
    AFTER INSERT HANDLER----PLACE HERE YOUR PROCESS TO BE EXECUTE AFTER INSERTING THE RECORDS
    ---------------------------------------------------------------------------------------------------------------***/   
    public static void afterInsertHandler(List<Account> newList, Map<Id,Account> newMap, List<Account> oldList, Map<Id,Account> oldMap){
          // create entitlement on account insertion
            AccountHelperClass.CreateEntitlementRecord(newList);
            //create service account on sold to creation
            AccountHelperClass.CreateServiceAccountOnSoldTo(newList);
          //RR: T-761616 : Commented as approval process is deactivated
          //AccountHelperClass.callProspectAccountApproval(newList);
    }
      
      
    /***-----------------------------------------------------------------------------------------------------------
    AFTER UPDATE HANDLER----PLACE HERE YOUR PROCESS TO BE EXECUTE AFTER UPDATING THE RECORDS
    ---------------------------------------------------------------------------------------------------------------***/   
    public static void afterUpdateHandler(List<Account> newList, Map<Id,Account> newMap, List<Account> oldList, Map<Id,Account> oldMap){
        AccountHelperClass.updateOpportunityAccountAliasEmail(newList,oldMap);
         AccountHelperClass.createAccountTeamRecord(newList,oldMap);
         AccountHelperClass.updateServiceAccountOnSoldToOnUpdate(newList,oldMap);
    }
    
    /***-----------------------------------------------------------------------------------------------------------
    AFTER DELETE HANDLER----PLACE HERE YOUR PROCESS TO BE EXECUTE AFTER DELETING THE RECORDS
    ---------------------------------------------------------------------------------------------------------------***/   
    public static void afterDeleteHandler(List<Account> newList, List<Account> oldList, Map<Id,Account> oldMap){
        
    }
    
    /***-----------------------------------------------------------------------------------------------------------
    AFTER UNDELETE HANDLER----PLACE HERE YOUR PROCESS TO BE EXECUTE AFTER DELETING THE RECORDS
    ---------------------------------------------------------------------------------------------------------------***/   
    public static void afterUnDeleteHandler(List<Account> newList, Map<Id,Account> newMap){
        
    }
        
}//END CLASS