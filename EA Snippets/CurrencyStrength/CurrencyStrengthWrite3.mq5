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

TypeCurrencyStrength CS[9];
int bars=45;
int db;
string table;


void M15DayInit()
{
   int zeropoint=100;

   datetime Arr[];
   if(CopyTime(Symbol(),PERIOD_M15,0,100,Arr)==100)
   {
      for(int i=100-2; i>=0; i--)
      {
         MqlDateTime dt;
         MqlDateTime dtp;
         TimeToStruct(Arr[i],dt);
         TimeToStruct(Arr[i+1],dtp);
         zeropoint=100-1-i;
         if(dt.day!=dtp.day)
            break;
      }
   }

   CS[4].Init(
      100,
      zeropoint,
      StringSubstr(Symbol(),6),
      PERIOD_M15,
      false,
      pr_close,
      //pr_haaverage,
      19,
      5,
      true
      );
   CS[4].recalculate=true;

   CS[5].Init(
      100,
      zeropoint,
      StringSubstr(Symbol(),6),
      PERIOD_M15,
      false,
      pr_close,
      //pr_haaverage,
      6,
      0,
      true
      );
   CS[5].recalculate=true;

   CS[6].Init(
      70,
      70,
      StringSubstr(Symbol(),6),
      PERIOD_H3,
      false,
      pr_close,
      6,
      0,
      true
      );
   CS[6].recalculate=true;

   CS[7].Init(
      70,
      70,
      StringSubstr(Symbol(),6),
      PERIOD_H3,
      false,
      pr_close,
      19,
      5,
      true
      );
   CS[7].recalculate=true;

   CS[8].Init(
      70,
      70,
      StringSubstr(Symbol(),6),
      PERIOD_H3,
      false,
      pr_close,
      0,
      0,
      true
      );
   CS[8].recalculate=true;
}


void OnInit()
{
   //CS[0].Init(
   //   bars,
   //   bars,
   //   StringSubstr(Symbol(),6),
   //   PERIOD_M1,
   //   false,
   //   pr_close,
   //   0,
   //   0,
   //   true
   //   );

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

   M15DayInit();

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
                       +"O8 INT NOT NULL,"
                       +"MA1 INT NOT NULL,"
                       +"MA2 INT NOT NULL,"
                       +"MA3 INT NOT NULL,"
                       +"MA4 INT NOT NULL,"
                       +"MA5 INT NOT NULL,"
                       +"MA6 INT NOT NULL,"
                       +"MA7 INT NOT NULL,"
                       +"MA8 INT NOT NULL,"
                       +"MAL1 INT NOT NULL,"
                       +"MAL2 INT NOT NULL,"
                       +"MAL3 INT NOT NULL,"
                       +"MAL4 INT NOT NULL,"
                       +"MAL5 INT NOT NULL,"
                       +"MAL6 INT NOT NULL,"
                       +"MAL7 INT NOT NULL,"
                       +"MAL8 INT NOT NULL,"
                       +"OL1 INT NOT NULL,"
                       +"OL2 INT NOT NULL,"
                       +"OL3 INT NOT NULL,"
                       +"OL4 INT NOT NULL,"
                       +"OL5 INT NOT NULL,"
                       +"OL6 INT NOT NULL,"
                       +"OL7 INT NOT NULL,"
                       +"OL8 INT NOT NULL,"
                       +"L1 INT NOT NULL,"
                       +"L2 INT NOT NULL,"
                       +"L3 INT NOT NULL,"
                       +"L4 INT NOT NULL,"
                       +"L5 INT NOT NULL,"
                       +"L6 INT NOT NULL,"
                       +"L7 INT NOT NULL,"
                       +"L8 INT NOT NULL );");
   }
   DatabaseTransactionBegin(db);
}


void OnDeinit(const int reason)
{
   DatabaseTransactionCommit(db);
   DatabaseClose(db);
}


void OnTick()
{
   MqlRates bar[2];
   if(CopyRates(_Symbol,_Period,0,2,bar)==-1)
      return;

   MqlDateTime dtcurrent;
   TimeToStruct(bar[1].time,dtcurrent);

   MqlDateTime dtlast;
   TimeToStruct(bar[0].time,dtlast);

//   if(dtlast.hour<2||dtlast.hour>22)
//      return;

   if(lastM15!=MathAbs(dtcurrent.min/15))
   {
      M15DayInit();
      lastM15=MathAbs(dtcurrent.min/15);
   }

   if(lastDay!=dtcurrent.day_of_year)
   {
      CS[1].recalculate=true;
      CS[2].recalculate=true;
      CS[3].recalculate=true;
      lastDay=dtcurrent.day_of_year;
   }

   if(dtlast.min!=lastMinute)
   {
      //CS[0].recalculate=true;
      //if(CS_CalculateIndex(CS[0],1))
      //{
         if(lastMinute!=-1)
         {
            string valstring;
            for(int i=0; i<8; i++)
            {
               //int idx=CS[0].Currencies.GetValueIndex(i+1);
               //double value=CS[0].Currencies.LastValues[idx][0];
               valstring+=",";
               //valstring+=DoubleToString(value*100000,0);
               valstring+="0";
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
            for(int i=0; i<8; i++)
            {
               int idx=CS[5].Currencies.GetValueIndex(i+1);
               double value=CS[5].Currencies.LastValues[idx][0];
               valstring+=",";
               valstring+=DoubleToString(value*100000,0);
            }
            for(int i=0; i<8; i++)
            {
               int idx=CS[6].Currencies.GetValueIndex(i+1);
               double value=CS[6].Currencies.LastValues[idx][0];
               valstring+=",";
               valstring+=DoubleToString(value*100000,0);
            }
            for(int i=0; i<8; i++)
            {
               int idx=CS[7].Currencies.GetValueIndex(i+1);
               double value=CS[7].Currencies.LastValues[idx][0];
               valstring+=",";
               valstring+=DoubleToString(value*100000,0);
            }
            for(int i=0; i<8; i++)
            {
               int idx=CS[8].Currencies.GetValueIndex(i+1);
               double value=CS[8].Currencies.LastValues[idx][0];
               valstring+=",";
               valstring+=DoubleToString(value*100000,0);
            }
   
            string command="INSERT INTO "+table+"(TIME,YEAR,MONTH,DAY,DAYOFWEEK,HOUR,MINUTE,C1,C2,C3,C4,C5,C6,C7,C8,D1,D2,D3,D4,D5,D6,D7,D8,DD1,DD2,DD3,DD4,DD5,DD6,DD7,DD8,DDD1,DDD2,DDD3,DDD4,DDD5,DDD6,DDD7,DDD8,O1,O2,O3,O4,O5,O6,O7,O8,MA1,MA2,MA3,MA4,MA5,MA6,MA7,MA8,MAL1,MAL2,MAL3,MAL4,MAL5,MAL6,MAL7,MAL8,OL1,OL2,OL3,OL4,OL5,OL6,OL7,OL8,L1,L2,L3,L4,L5,L6,L7,L8) VALUES("
               +IntegerToString(bar[0].time)
               +","+IntegerToString(dtlast.year)
               +","+IntegerToString(dtlast.mon)
               +","+IntegerToString(dtlast.day_of_year)
               +","+IntegerToString(dtlast.day_of_week)
               +","+IntegerToString(dtlast.hour)
               +","+IntegerToString(dtlast.min)
               +valstring
               +")";
               
            DatabaseExecute(db,command);
         }
      
         lastMinute=dtlast.min;
      //}
   }
   else
   {
      CS_CalculateIndex(CS[1]);
      CS_CalculateIndex(CS[2]);
      CS_CalculateIndex(CS[3]);
      CS_CalculateIndex(CS[4]);
      CS_CalculateIndex(CS[5]);
      CS_CalculateIndex(CS[6]);
      CS_CalculateIndex(CS[7]);
      CS_CalculateIndex(CS[8]);
   }
}

