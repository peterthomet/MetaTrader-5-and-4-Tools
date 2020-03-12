//
// CurrencyStrengtWrite2.mq5
// getYourNet.ch
//

#include <CurrencyStrength.mqh>
#include <Ado\Providers\OleDb.mqh>

bool working=false;
datetime lastTime;
int lastMinute=-1;
int barshift=1;
datetime lastmaxtime=-1;

TypeCurrencyStrength CS[1];
int bars=20;

COleDbConnection *conn1=new COleDbConnection();
COleDbCommand *cmd1=new COleDbCommand();


void OnInit()
{
   CS[0].Init(
      bars,
      bars,
      StringSubstr(Symbol(),6),
      PERIOD_MN1,
      false,
      pr_close
      );

   conn1.ConnectionString("Data Source=HOST2012\\SQLEXPRESS;Initial Catalog=CurrencyStrength2;Provider=SQLOLEDB;Integrated Security=SSPI;Auto Translate=false;");
   cmd1.Connection(conn1);
   conn1.Open();

   EventSetMillisecondTimer(100);
}


void OnDeinit(const int reason)
{
   EventKillTimer();

   conn1.Close();
   delete conn1;
   delete cmd1;
}


void OnTick()
{
}


void OnTimer()
{
   Manage();
}


void Manage()
{
   if(working)
      return;
   working=true;


   datetime currentTime=TimeTradeServer();
   MqlDateTime dt;
   TimeToStruct(currentTime,dt);
   
   if(dt.min!=lastMinute)
   {
      if(CS_CalculateIndex(CS[0]))
      {
         if(lastmaxtime==-1)
            lastmaxtime=CS[0].Pairs.maxtime;

         if(lastmaxtime!=CS[0].Pairs.maxtime)
         {
            barshift++;
            lastmaxtime=CS[0].Pairs.maxtime;
         }
      
         string valstring;
         for(int i=0; i<8; i++)
         {
            valstring+=",";
            double value=CS[0].Currencies.Currency[i].index[bars-1]-CS[0].Currencies.Currency[i].index[bars-(1+barshift)];  // Index bezieht sich auf letzte Bar!!!
            valstring+=DoubleToString(value*1000,0);
         }

         cmd1.CommandText("INSERT INTO Strength(Zeit,[1],[2],[3],[4],[5],[6],[7],[8]) VALUES("
            +DTString(dt)
            +valstring
            +")");
         cmd1.ExecuteNonQuery();
         
         lastTime=currentTime;
         lastMinute=dt.min;
      }
   }


   working=false;
}


string DTString(MqlDateTime& dt)
{
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
   ret+="0";
   ret+="'";
   return ret;
}