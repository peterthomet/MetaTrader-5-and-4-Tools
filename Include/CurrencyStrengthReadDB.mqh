//
// CurrencyStrengthReadDB.mqh
// getYourNet.ch
//

//#include <Ado\Providers\OleDb.mqh>

//COleDbConnection* conn1;
//COleDbCommand* cmd1;

//bool connectionopen=false;

#import "MqlSqlDemo.dll"

int CreateConnection(string sConnStr);
string GetLastMessage();
int ExecuteSql(string sSql);
int ReadInt(string sSql);
string ReadString(string sSql);
void CloseConnection();

#define iResSuccess 0
#define iResError 1

#import


void OpenDBConnection()
{
   CreateConnection("Server=HOST2012\\SQLEXPRESS;Database=CurrencyStrength;Integrated Security=True");
   
   //if(!connectionopen)
   //{

//      conn1=new COleDbConnection();
//      cmd1=new COleDbCommand();
//      
//      //conn1.ConnectionString("Provider=Microsoft.ACE.OLEDB.12.0;Mode=1;Data Source=C:\\Data\\Trading\\MT5AdoSuite\\SampleDB\\CurrencyStrength.accdb");
//      //conn1.ConnectionString("Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\\Data\\Trading\\MT5AdoSuite\\SampleDB\\CurrencyStrength.accdb");
//      conn1.ConnectionString("Data Source=HOST2012\\SQLEXPRESS;Initial Catalog=CurrencyStrength;Provider=SQLOLEDB;Integrated Security=SSPI;Auto Translate=false;");
//      
//      cmd1.Connection(conn1);
//      conn1.Open();

      //connectionopen=true;
   //}
}


void CloseDBConnection()
{
   //CloseConnection();

   //if(connectionopen)
   //{

      //conn1.Close();
      //delete conn1;
      //conn1=NULL;
      //delete cmd1;

      //connectionopen=false;
   //}
}


bool CS_CalculateIndexReadDB(TypeCurrencyStrength& cs, MqlDateTime& dt)
{






//      COleDbConnection* conn1=new COleDbConnection();
//      COleDbCommand* cmd1=new COleDbCommand();
//      
//      //conn1.ConnectionString("Provider=Microsoft.ACE.OLEDB.12.0;Mode=1;Data Source=C:\\Data\\Trading\\MT5AdoSuite\\SampleDB\\CurrencyStrength.accdb");
//      //conn1.ConnectionString("Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\\Data\\Trading\\MT5AdoSuite\\SampleDB\\CurrencyStrength.accdb");
//      conn1.ConnectionString("Data Source=HOST2012\\SQLEXPRESS;Initial Catalog=CurrencyStrength;Provider=SQLOLEDB;Integrated Security=SSPI;Auto Translate=false;");
//      
//      cmd1.Connection(conn1);
//      conn1.Open();
//
//
//   cmd1.CommandText("SELECT [65] FROM Strength WHERE Zeit = " + DTString());
//
//   CAdoValue *valTrades=cmd1.ExecuteScalar();
//
//   //if(CheckPointer(valTrades)==POINTER_INVALID)
//   //{
//   //   CloseDBConnection();
//   //   return false;
//   //}
//
//   string trades=valTrades.AnyToString();
   string sql="SELECT [65] FROM Strength WHERE Zeit = " + DTString(dt);
   string trades=ReadString(sql);

   int start=0;
   if(cs.timeframe==PERIOD_M5)
      start=0;
   if(cs.timeframe==PERIOD_M15)
      start=28;
   if(cs.timeframe==PERIOD_M30)
      start=56;
   if(cs.timeframe==PERIOD_H1)
      start=84;
   if(cs.timeframe==PERIOD_H4)
      start=112;
   if(cs.timeframe==PERIOD_D1)
      start=140;
   if(cs.timeframe==PERIOD_W1)
      start=168;
   if(cs.timeframe==PERIOD_MN1)
      start=196;

   string tradeseval="";
   for(int x=0; x<4; x++)
   {
      string t=StringSubstr(trades,start+(x*7),7);
      tradeseval+=t;
      cs.Currencies.Trade[x].name=StringSubstr(t,0,6);
      cs.Currencies.Trade[x].buy=false;
      if(StringSubstr(t,6,1)=="b")
         cs.Currencies.Trade[x].buy=true;
   }

   //if(dt.hour==3&&dt.min==14)
   //{
   //   int file_handle=FileOpen("SQL-Log.txt",FILE_WRITE|FILE_READ|FILE_TXT);
   //   FileSeek(file_handle,0,SEEK_END);
   //   FileWriteString(file_handle,sql+" "+tradeseval+"\r\n");
   //   FileClose(file_handle);
   //}


//
//   delete valTrades;
//
//      conn1.Close();
//      delete conn1;
//      delete cmd1;

   return(true);
}


string DTString(MqlDateTime& dt)
{
   //datetime currentTime=TimeTradeServer();
   //MqlDateTime dt;
   //TimeToStruct(currentTime,dt);

   string ret;
   ret+="'";
   ret+=IntegerToString(dt.year);
   ret+="-";
   ret+=IntegerToString(dt.mon);
   ret+="-";
   ret+=IntegerToString(dt.day);
   ret+=" ";
   ret+=IntegerToString(dt.hour);
   ret+=":";
   ret+=IntegerToString(dt.min);
   ret+=":";

   //int file_handle=FileOpen("SQL-Log.txt",FILE_WRITE|FILE_READ|FILE_TXT);
   //FileSeek(file_handle,0,SEEK_END);
   //FileWriteString(file_handle,ret+IntegerToString(dt.sec)+"\r\n");
   //FileClose(file_handle);

   ret+="0";
   ret+="'";
   return ret;
}
