//
// CurrencyStrengtWrite.mq5
// getYourNet.ch
//

#include <CurrencyStrength.mqh>
#include <Ado\Providers\OleDb.mqh>

bool working=false;
datetime lastTime;
int lastMinute=-1;

TypeCurrencyStrength CS[8];

COleDbConnection *conn1=new COleDbConnection();
COleDbCommand *cmd1=new COleDbCommand();


void OnInit()
{
   CS[0].Init(
      10,
      10,
      StringSubstr(Symbol(),6),
      PERIOD_M5,
      false,
      pr_close
      );
   CS[1].Init(
      10,
      10,
      StringSubstr(Symbol(),6),
      PERIOD_M15,
      false,
      pr_close
      );
   CS[2].Init(
      10,
      10,
      StringSubstr(Symbol(),6),
      PERIOD_M30,
      false,
      pr_close
      );
   CS[3].Init(
      10,
      10,
      StringSubstr(Symbol(),6),
      PERIOD_H1,
      false,
      pr_close
      );
   CS[4].Init(
      10,
      10,
      StringSubstr(Symbol(),6),
      PERIOD_H4,
      false,
      pr_close
      );
   CS[5].Init(
      10,
      10,
      StringSubstr(Symbol(),6),
      PERIOD_D1,
      false,
      pr_close
      );
   CS[6].Init(
      10,
      10,
      StringSubstr(Symbol(),6),
      PERIOD_W1,
      false,
      pr_close
      );
   CS[7].Init(
      10,
      10,
      StringSubstr(Symbol(),6),
      PERIOD_MN1,
      false,
      pr_close
      );

   //conn1.ConnectionString("Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\\Data\\Trading\\MT5AdoSuite\\SampleDB\\CurrencyStrength.accdb");
   conn1.ConnectionString("Data Source=HOST2012\\SQLEXPRESS;Initial Catalog=CurrencyStrength;Provider=SQLOLEDB;Integrated Security=SSPI;Auto Translate=false;");
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

   //if(currentTime!=lastTime)
   if(dt.min!=lastMinute)
   {
      if(CS_CalculateIndex(CS[0])&&CS_CalculateIndex(CS[1])&&CS_CalculateIndex(CS[2])&&CS_CalculateIndex(CS[3])&&CS_CalculateIndex(CS[4])&&CS_CalculateIndex(CS[5])&&CS_CalculateIndex(CS[6])&&CS_CalculateIndex(CS[7]))
      {
         string valstring;
         string tradestring;
         for(int i=1; i<=8; i++)
         {
            for(int x=0; x<8; x++)
            {
               valstring+=",";
               int idx=CS[x].Currencies.GetValueIndex(i);
               double value=CS[x].Currencies.LastValues[idx][0];
               valstring+=DoubleToString(value*1000,0);
            }
         }

         tradestring+="'";
         for(int x=0; x<8; x++)
         {
            for(int y=0; y<4; y++)
            {
               tradestring+=CS[x].Currencies.Trade[y].name;
               if(CS[x].Currencies.Trade[y].buy)
                  tradestring+="b";
               else
                  tradestring+="s";
            }
         }
         tradestring+="'";

         
         cmd1.CommandText("INSERT INTO Strength(Zeit,[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25],[26],[27],[28],[29],[30],[31],[32],[33],[34],[35],[36],[37],[38],[39],[40],[41],[42],[43],[44],[45],[46],[47],[48],[49],[50],[51],[52],[53],[54],[55],[56],[57],[58],[59],[60],[61],[62],[63],[64],[65]) VALUES("
            +DTString(dt)
            +valstring+","
            +tradestring
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
   //datetime t1=StructToTime(dtin);
   //t1-=10;
   //MqlDateTime dt;
   //TimeToStruct(t1,dt);
   dt.sec=0;

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
   ret+=IntegerToString(dt.sec);
   ret+="'";
   return ret;
}