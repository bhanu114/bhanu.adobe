/*
 HISTORY                                                                  
 |                                                                           
 |   DATE            DEVELOPER        WR/Req         DESCRIPTION                               
 |   ====            =========        ======         ===========
 |  4-July-2019       BhanuPrakash    Generic    Initial Creatoin
*/
/*
*   Class Name  :   GenericOperationsHelper
*   Class Type  :   GENERIC CLASS
*   Description :   This class is combination of many generic methods to perform a flow of logic on multiple objects without type specific
*/
public class Adobe_GenericOperationsHelper {

    /******************************************************************************************
    * Method Name : getFieldValueKeyListOfObjectsFromList
    * Parameters  : List<SObject> - List of SObjects
                    keyFieldAPIName - Key field API name
    * Return Type : Map<String,List<SObject>> - result with Map of Key field value and respective List of SObjects as value
    * Description : This method processess List and prepares Map of custom key and key related List of SObjects to return
    ******************************************************************************************/
    public static Map<String,List<SObject>> getFieldValueKeyListOfObjectsFromList(List<SObject> sobjectList,String keyFieldAPIName){
        Map<String, List<SObject>> resultMap = new Map<String, List<SObject>>();
        if( sobjectList != null && !String.isEmpty(keyFieldAPIName)){
            List<SObject> sobjList = null;
            for(SObject sobj :  sobjectList) {
                //Parant Id n Child count map creation
                if(sobj.get(keyFieldAPIName) != null){
                    sobjList = resultMap.containsKey((String)sobj.get((String)keyFieldAPIName)) ? resultMap.get((String)sobj.get((String)keyFieldAPIName)) : new List<SObject>() ;
                    sobjList.add(sobj);
                    resultMap.put((String)sobj.get((String)keyFieldAPIName), sobjList);
                }
            }
        } 
        return resultMap;
    }
    
    
    /******************************************************************************************
    * Method Name : getFieldValueKeyListOfObjectIDSetFromList
    * Parameters  : List<SObject> - List of SObjects
                    keyFieldAPIName - Key field API name
    * Return Type : Map<String,Set<String>> - result with Map of Key field value and respective List of SObjects Ids as value
    * Description : This method processess List and prepares Map of custom key and key related List of SObjects Ids to return
    ******************************************************************************************/
    public static Map<String,Set<String>> getFieldValueKeyListOfObjectIDSetFromList(List<SObject> sobjectList,String keyFieldAPIName){
        Map<String, Set<String>> resultMap = new Map<String, Set<String>>();
        if( sobjectList != null && !String.isEmpty(keyFieldAPIName)){
            Set<String> sobjList = null;
            for(SObject sobj :  sobjectList) {
                //Parant Id n Child count map creation
                if(sobj.get(keyFieldAPIName) != null){
                    sobjList = resultMap.containsKey((String)sobj.get((String)keyFieldAPIName)) ? resultMap.get((String)sobj.get((String)keyFieldAPIName)) : new Set<String>() ;
                    sobjList.add((String)sobj.get('Id'));
                    resultMap.put((String)sobj.get((String)keyFieldAPIName), sobjList);
                }
            }
        }
        return resultMap;
    }
    
}