//
// CurrencyStrengtWrite3.mq5
// getYourNet.ch
//

#include <CurrencyStrength.mqh>

bool working=false;
datetime lastTime;
int lastMinute=-1;
int barshift=1;
datetime lastmaxtime=-1;

TypeCurrencyStrength CS[1];
int bars=45;
int db;


void OnInit()
{
   CS[0].Init(
      bars,
      bars,
      StringSubstr(Symbol(),6),
      PERIOD_M1,
      false,
      pr_close,
      0,
      0,
      true
      );

   db=DatabaseOpen("CS.sqlite", DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE |DATABASE_OPEN_COMMON);
   if(db!=INVALID_HANDLE)
   {
      if(DatabaseTableExists(db, "Minutes45MinuteRange"))
         DatabaseExecute(db, "DROP TABLE Minutes45MinuteRange");

      DatabaseExecute(db, "CREATE TABLE Minutes45MinuteRange("
                       "TIME INT PRIMARY KEY NOT NULL,"
                       "C1 INT NOT NULL,"
                       "C2 INT NOT NULL,"
                       "C3 INT NOT NULL,"
                       "C4 INT NOT NULL,"
                       "C5 INT NOT NULL,"
                       "C6 INT NOT NULL,"
                       "C7 INT NOT NULL,"
                       "C8 INT NOT NULL );");
   }
}


void OnDeinit(const int reason)
{
   DatabaseClose(db);
}


void OnTick()
{
   datetime currentTime=TimeTradeServer();
   MqlDateTime dt;
   TimeToStruct(currentTime,dt);
   if(dt.hour<2)
      return;

   if(CS_CalculateIndex(CS[0],1))
   {
   
   }
}


//void Manage()
//{
//   if(working)
//      return;
//   working=true;
//
//
//   datetime currentTime=TimeTradeServer();
//   MqlDateTime dt;
//   TimeToStruct(currentTime,dt);
//   
//   if(dt.min!=lastMinute)
//   {
//      if(CS_CalculateIndex(CS[0]))
//      {
//         if(lastmaxtime==-1)
//            lastmaxtime=CS[0].Pairs.maxtime;
//
//         if(lastmaxtime!=CS[0].Pairs.maxtime)
//         {
//            barshift++;
//            lastmaxtime=CS[0].Pairs.maxtime;
//         }
//      
//         string valstring;
//         for(int i=0; i<8; i++)
//         {
//            valstring+=",";
//            double value=CS[0].Currencies.Currency[i].index[bars-1]-CS[0].Currencies.Currency[i].index[bars-(1+barshift)];  // Index bezieht sich auf letzte Bar!!!
//            valstring+=DoubleToString(value*1000,0);
//         }
//
//         cmd1.CommandText("INSERT INTO Strength(Zeit,[1],[2],[3],[4],[5],[6],[7],[8]) VALUES("
//            +DTString(dt)
//            +valstring
//            +")");
//         cmd1.ExecuteNonQuery();
//         
//         lastTime=currentTime;
//         lastMinute=dt.min;
//      }
//   }
//
//
//   working=false;
//}


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