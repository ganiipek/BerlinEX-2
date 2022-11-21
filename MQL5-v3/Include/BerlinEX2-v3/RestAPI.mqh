#include <BerlinEX2-v3/JAson.mqh>

class RestAPI
{
   string   base_url;
   char     post[], result[];
   bool     developer_debug;
   int      login_attempt_count;
   
   public:
      RestAPI(bool _developer_debug=false, bool _connection_safe=true)
      {
        developer_debug = _developer_debug;
        if(developer_debug)   base_url = "http://localhost/yalcinex/api/v1/";
        else                  base_url = "https://yalcinex.com/api/v1/";
        
        if(_connection_safe)  base_url = "https://yalcinex.com/api/v1/";
        else                  base_url = "http://yalcinex.com/api/v1/";

        login_attempt_count = 0;
      }
   
      CJAVal request(string method, string request)
      {
         CJAVal result_json;
         if(!MQLInfoInteger(MQL_TESTER))
         {
            string cookie=NULL, headers;

            if(developer_debug) Print(request);
            int res = WebRequest(method, request, cookie, NULL, 500, post, 0, result, headers);
            
            result_json.Deserialize(result);
            if(developer_debug) Print("res: " + IntegerToString(res));
         }
         return result_json;
      }
      
      CJAVal login(int account_id, string broker_name, string account_name, string program_version)
      {
         string _request = StringFormat(base_url + "emirhan_bb_stoch/login?mt4_id=%s&broker_name=%s&account_name=%s&version=%s", 
            IntegerToString(account_id),
            broker_name,
            account_name,
            program_version
         );
         
         return request("GET", _request);
      }

      bool loginCheck(int account_id, string broker_name, string account_name, string program_version)
      {
         CJAVal result_json = login(account_id, broker_name, account_name, program_version);

         if(result_json["status"].ToInt() == 200)
         {
            login_attempt_count = 0;
         }
         else
         {
            login_attempt_count++;
         }

         if(login_attempt_count >= 5)
         {
            Print("Login attempt limit reached. Exiting...");
            return false;
         }

         return true;
      }
};