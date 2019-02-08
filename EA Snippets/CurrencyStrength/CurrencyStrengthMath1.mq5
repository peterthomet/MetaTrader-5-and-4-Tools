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
   delete cmd1;
   delete conn1;
}


double OnTester()
{
   MqlDateTime dtstart;
   TimeToStruct(starttime,dtstart);
   MqlDateTime dtend;
   TimeToStruct(endtime,dtend);

   cmd1.CommandText("SELECT * FROM Strength WHERE Zeit BETWEEN " + DTString(dtstart) + " AND " + DTString(dtend) + " ORDER BY Zeit");

   COleDbDataReader *reader=cmd1.ExecuteReader();

   double count=0, ret=0;
   long val=0;
   MqlDateTime time;
   while(reader.Read())
   {
      time=reader.GetValue("Zeit").ToDatetime();
      val=reader.GetValue("1").ToLong();
      count++;
      if(count==x)
         ret=(double)val;
   }
   ret=count;

   delete reader;

   return(ret);
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
