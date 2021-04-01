//
// CurrencyStrengtWrite3.mq5
// getYourNet.ch
//

#include <CurrencyStrength.mqh>

bool working=false;
datetime lastTime;
int lastMinute=-1;
int lastM15=-1;
int lastDay=-1;
int barshift=1;
datetime lastmaxtime=-1;

TypeCurrencyStrength CS[5];
int bars=45;
int db;
string table;


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

   CS[1].Init(
      3,
      3,
      StringSubstr(Symbol(),6),
      PERIOD_D1,
      false,
      pr_close,
      0,
      0,
      false
      );

   CS[2].Init(
      3,
      3,
      StringSubstr(Symbol(),6),
      PERIOD_D1,
      false,
      pr_close,
      0,
      0,
      true
      );

   CS[3].Init(
      4,
      4,
      StringSubstr(Symbol(),6),
      PERIOD_D1,
      false,
      pr_close,
      0,
      0,
      true
      );

   CS[4].Init(
      10,
      10,
      StringSubstr(Symbol(),6),
      PERIOD_M15,
      false,
      pr_close,
      19,
      5,
      true
      );

   db=DatabaseOpen("CS.sqlite", DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE |DATABASE_OPEN_COMMON);
   if(db!=INVALID_HANDLE)
   {
      table="MinutesCS";
   
      if(DatabaseTableExists(db, table))
         DatabaseExecute(db, "DROP TABLE "+table);

      DatabaseExecute(db, "CREATE TABLE "+table+"("
                       +"TIME INT PRIMARY KEY NOT NULL,"
                       +"YEAR INT NOT NULL,"
                       +"MONTH INT NOT NULL,"
                       +"DAY INT NOT NULL,"
                       +"DAYOFWEEK INT NOT NULL,"
                       +"HOUR INT NOT NULL,"
                       +"MINUTE INT NOT NULL,"
                       +"C1 INT NOT NULL,"
                       +"C2 INT NOT NULL,"
                       +"C3 INT NOT NULL,"
                       +"C4 INT NOT NULL,"
                       +"C5 INT NOT NULL,"
                       +"C6 INT NOT NULL,"
                       +"C7 INT NOT NULL,"
                       +"C8 INT NOT NULL,"
                       +"D1 INT NOT NULL,"
                       +"D2 INT NOT NULL,"
                       +"D3 INT NOT NULL,"
                       +"D4 INT NOT NULL,"
                       +"D5 INT NOT NULL,"
                       +"D6 INT NOT NULL,"
                       +"D7 INT NOT NULL,"
                       +"D8 INT NOT NULL,"
                       +"DD1 INT NOT NULL,"
                       +"DD2 INT NOT NULL,"
                       +"DD3 INT NOT NULL,"
                       +"DD4 INT NOT NULL,"
                       +"DD5 INT NOT NULL,"
                       +"DD6 INT NOT NULL,"
                       +"DD7 INT NOT NULL,"
                       +"DD8 INT NOT NULL,"
                       +"DDD1 INT NOT NULL,"
                       +"DDD2 INT NOT NULL,"
                       +"DDD3 INT NOT NULL,"
                       +"DDD4 INT NOT NULL,"
                       +"DDD5 INT NOT NULL,"
                       +"DDD6 INT NOT NULL,"
                       +"DDD7 INT NOT NULL,"
                       +"DDD8 INT NOT NULL,"
                       +"O1 INT NOT NULL,"
                       +"O2 INT NOT NULL,"
                       +"O3 INT NOT NULL,"
                       +"O4 INT NOT NULL,"
                       +"O5 INT NOT NULL,"
                       +"O6 INT NOT NULL,"
                       +"O7 INT NOT NULL,"
                       +"O8 INT NOT NULL );");
   }
}


void OnDeinit(const int reason)
{
   DatabaseClose(db);
}


void OnTick()
{
   MqlRates bar[1];
   if(CopyRates(_Symbol,_Period,1,1,bar)==-1)
      return;

   MqlDateTime dt;
   TimeToStruct(bar[0].time,dt);
   if(dt.hour<2||dt.hour>22)
      return;

   if(dt.min!=lastMinute)
   {
      CS[0].recalculate=true;
      if(lastDay!=dt.day_of_year)
      {
         CS[1].recalculate=true;
         CS[2].recalculate=true;
         CS[3].recalculate=true;
         lastDay=dt.day_of_year;
      }
      if(lastM15!=MathAbs(dt.min/15))
      {
         CS[4].recalculate=true;
         lastM15=MathAbs(dt.min/15);
      }
      if(CS_CalculateIndex(CS[0],1) && CS_CalculateIndex(CS[1]) && CS_CalculateIndex(CS[2]) && CS_CalculateIndex(CS[3]) && CS_CalculateIndex(CS[4]))
      {
         string valstring;
         for(int i=0; i<8; i++)
         {
            int idx=CS[0].Currencies.GetValueIndex(i+1);
            double value=CS[0].Currencies.LastValues[idx][0];
            valstring+=",";
            valstring+=DoubleToString(value*100000,0);
         }
         for(int i=0; i<8; i++)
         {
            int idx=CS[1].Currencies.GetValueIndex(i+1);
            double value=CS[1].Currencies.LastValues[idx][0];
            valstring+=",";
            valstring+=DoubleToString(value*100000,0);
         }
         for(int i=0; i<8; i++)
         {
            int idx=CS[2].Currencies.GetValueIndex(i+1);
            double value=CS[2].Currencies.LastValues[idx][0];
            valstring+=",";
            valstring+=DoubleToString(value*100000,0);
         }
         for(int i=0; i<8; i++)
         {
            int idx=CS[3].Currencies.GetValueIndex(i+1);
            double value=CS[3].Currencies.LastValues[idx][0];
            valstring+=",";
            valstring+=DoubleToString(value*100000,0);
         }
         for(int i=0; i<8; i++)
         {
            int idx=CS[4].Currencies.GetValueIndex(i+1);
            double value=CS[4].Currencies.LastValues[idx][0];
            valstring+=",";
            valstring+=DoubleToString(value*100000,0);
         }

         string command="INSERT INTO "+table+"(TIME,YEAR,MONTH,DAY,DAYOFWEEK,HOUR,MINUTE,C1,C2,C3,C4,C5,C6,C7,C8,D1,D2,D3,D4,D5,D6,D7,D8,DD1,DD2,DD3,DD4,DD5,DD6,DD7,DD8,DDD1,DDD2,DDD3,DDD4,DDD5,DDD6,DDD7,DDD8,O1,O2,O3,O4,O5,O6,O7,O8) VALUES("
            +IntegerToString(bar[0].time)
            +","+IntegerToString(dt.year)
            +","+IntegerToString(dt.mon)
            +","+IntegerToString(dt.day_of_year)
            +","+IntegerToString(dt.day_of_week)
            +","+IntegerToString(dt.hour)
            +","+IntegerToString(dt.min)
            +valstring
            +")";
            
         DatabaseExecute(db,command);
      
         lastMinute=dt.min;
      }
   }
}

