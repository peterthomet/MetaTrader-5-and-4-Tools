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

   db=DatabaseOpen("CS.sqlite", DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE |DATABASE_OPEN_COMMON);
   if(db!=INVALID_HANDLE)
   {
      table="Minutes45MinuteRange";
   
      if(DatabaseTableExists(db, table))
         DatabaseExecute(db, "DROP TABLE "+table);

      DatabaseExecute(db, "CREATE TABLE "+table+"("
                       "TIME INT PRIMARY KEY NOT NULL,"
                       "YYYYDDDHHMM INT NOT NULL,"
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
      if(CS_CalculateIndex(CS[0],1))
      {
         string valstring;
         for(int i=0; i<8; i++)
         {
            int idx=CS[0].Currencies.GetValueIndex(i+1);
            double value=CS[0].Currencies.LastValues[idx][0];

            valstring+=",";
            valstring+=DoubleToString(value*100000,0);
         }

         string command="INSERT INTO "+table+"(TIME,YYYYDDDHHMM,C1,C2,C3,C4,C5,C6,C7,C8) VALUES("
            +IntegerToString(bar[0].time)
            +","+IntegerToString(dt.year)+IntegerToString(dt.day_of_year,3,'0')+IntegerToString(dt.hour,2,'0')+IntegerToString(dt.min,2,'0')
            +valstring
            +")";
            
         DatabaseExecute(db,command);
      
         lastMinute=dt.min;
      }
   }
}

