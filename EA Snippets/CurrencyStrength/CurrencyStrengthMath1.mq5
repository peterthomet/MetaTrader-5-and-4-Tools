//
// CurrencyStrengtMath1.mq5
// getYourNet.ch
//

#property tester_no_cache

#include <Ado\Providers\OleDb.mqh>

input datetime starttime=D'2018.12.01 00:00:00';
input datetime endtime=D'2018.12.14 23:59:59';
input int x = 0;

COleDbConnection *conn1;
COleDbCommand *cmd1;

struct TypeCurrency
{
   int current;
   int daystart;
   int entry;
   bool up;
   int daymax;
   int daymin;
   double maxddgainratio;
};

struct TypeTrades
{
   TypeCurrency currency[8];
};
TypeTrades trades;


void OnInit()
{
   conn1=new COleDbConnection();
   cmd1=new COleDbCommand();
   conn1.ConnectionString("Data Source=HOST2012\\SQLEXPRESS;Initial Catalog=CurrencyStrength2;Provider=SQLOLEDB;Integrated Security=SSPI;Auto Translate=false;");
   cmd1.Connection(conn1);
   conn1.Open();
}


void OnDeinit(const int reason)
{
   conn1.Close();
   delete conn1;
   //delete cmd1;
}


double OnTester()
{
   MqlDateTime dtstart;
   TimeToStruct(starttime,dtstart);
   MqlDateTime dtend;
   TimeToStruct(endtime,dtend);

   cmd1.CommandText("SELECT * FROM Strength WHERE Zeit BETWEEN " + DTString(dtstart) + " AND " + DTString(dtend) + " ORDER BY Zeit");

   COleDbDataReader *reader=cmd1.ExecuteReader();

   MqlDateTime time;
   datetime timeint;
   datetime timedaystart=0;
   double traderesult=0;
   int count=0;
   while(reader.Read())
   {
      time=reader.GetValue("Zeit").ToDatetime();
      timeint=StructToTime(time);
      for(int i=0;i<8;i++)
         trades.currency[i].current=(int)reader.GetValue(IntegerToString(i+1)).ToLong();

      if(time.hour==0&&time.min==0)
      {
         timedaystart=timeint;
         SetDayStart();
      }
      
      if(timedaystart+(x*60)==timeint)
         SetEntry();

      if(timedaystart+(x*60)<timeint)
         SetTradeValues();

      if(time.hour==22&&time.min==30)
      {
         traderesult+=GetTradeResult();
         count++;
      }

   }
   if(count>0)
      traderesult=traderesult/count;

   delete reader;

   return traderesult;
}


double GetTradeResult()
{
   double ret=0;
   int count=0;
   for(int i=0;i<8;i++)
   {
      if(trades.currency[i].entry!=0)
      {
         count++;

         //if(trades.currency[i].up)
         //{
         //   ret+=trades.currency[i].daymax-trades.currency[i].entry;
         //}
         //else
         //{
         //   ret+=trades.currency[i].entry-trades.currency[i].daymax;
         //}

         ret+=trades.currency[i].maxddgainratio;
      }
      if(count>0)
         ret=ret/count;
   }
   return ret;
}


void SetTradeValues()
{
   for(int i=0;i<8;i++)
   {
      if(trades.currency[i].up)
      {
         trades.currency[i].daymax=MathMax(trades.currency[i].daymax,trades.currency[i].current);
         trades.currency[i].daymin=MathMin(trades.currency[i].daymin,trades.currency[i].current);
         int maxgain=trades.currency[i].daymax-trades.currency[i].entry;
         int maxdd=trades.currency[i].entry-trades.currency[i].daymin;
         if(maxdd>0)
            trades.currency[i].maxddgainratio=MathMax(trades.currency[i].maxddgainratio,maxgain/maxdd);
      }
      else
      {
         trades.currency[i].daymax=MathMin(trades.currency[i].daymax,trades.currency[i].current);
         trades.currency[i].daymin=MathMax(trades.currency[i].daymin,trades.currency[i].current);
         int maxgain=trades.currency[i].entry-trades.currency[i].daymax;
         int maxdd=trades.currency[i].daymin-trades.currency[i].entry;
         if(maxdd>0)
            trades.currency[i].maxddgainratio=MathMax(trades.currency[i].maxddgainratio,maxgain/maxdd);
      }
   }
}


void SetEntry()
{
   int values[8][2];
   for(int i=0;i<8;i++)
      values[i][1]=i;
   for(int i=0;i<8;i++)
      values[i][0]=trades.currency[i].current-trades.currency[i].daystart;
   ArraySort(values);
   trades.currency[values[7][1]].entry=trades.currency[values[7][1]].current;
   trades.currency[values[7][1]].up=true;
   trades.currency[values[6][1]].entry=trades.currency[values[6][1]].current;
   trades.currency[values[6][1]].up=true;
   trades.currency[values[0][1]].entry=trades.currency[values[0][1]].current;
   trades.currency[values[0][1]].up=false;
   trades.currency[values[1][1]].entry=trades.currency[values[1][1]].current;
   trades.currency[values[1][1]].up=false;
}


void SetDayStart()
{
   for(int i=0;i<8;i++)
   {
      trades.currency[i].daystart=trades.currency[i].current;
      trades.currency[i].daymax=0;
      trades.currency[i].daymin=0;
      trades.currency[i].entry=0;
      trades.currency[i].maxddgainratio=0;
   }
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
