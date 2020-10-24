//
// Currencies.mq5
//

#property service
#property copyright "Copyright 2020, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"

#include <CurrencyStrength.mqh>
const int bars=90000;
TypeCurrencyStrength CS;


void OnStart()
{
   CS.Init(
      bars,
      GetZeroBar(),
      "",
      PERIOD_M1,
      false,
      pr_close,
      0,
      0,
      false
      );

   CustomSymbolCreate("EUR",NULL,"EURUSD");
   SymbolSelect("EUR",true);

   //datetime LastTime=TimeCurrent();
   MqlRates rates[];
   ArrayResize(rates,bars-1);
 
   if(CS_CalculateIndex(CS,0))
   {
      //Print(CS.Currencies.Currency[1].index[0].laging.close);
      for(int i=1; i<bars; i++)
      {
         //LastTime=TimeCurrent()-(((bars-1)-i)*60);
         rates[i-1].time=CS.Currencies.Currency[1].index[i].time;
         rates[i-1].open=CS.Currencies.Currency[1].index[i-1].laging.close*100000+1000;
         rates[i-1].high=CS.Currencies.Currency[1].index[i].laging.high*100000+1000;
         rates[i-1].low=CS.Currencies.Currency[1].index[i].laging.low*100000+1000;
         rates[i-1].close=CS.Currencies.Currency[1].index[i].laging.close*100000+1000;
      }
      
      CustomRatesUpdate("EUR",rates);
   }
   else
   {
      Print("FAIL");
   }


/*
   rates[0].time=TimeCurrent()-120;
   rates[0].open=120;
   rates[0].high=200;
   rates[0].low=100;
   rates[0].close=150;

   rates[1].time=TimeCurrent()-60;
   rates[1].open=150;
   rates[1].high=160;
   rates[1].low=120;
   rates[1].close=130;

   rates[2].time=TimeCurrent();
   rates[2].open=130;
   rates[2].high=140;
   rates[2].low=90;
   rates[2].close=100;
*/

   //CustomRatesUpdate("USD",rates);

   MqlRates r[1];
   while(!IsStopped())
   {
      if(CS_CalculateIndex(CS,0))
      {
         r[0].time=CS.Currencies.Currency[1].index[99].time;
         r[0].open=CS.Currencies.Currency[1].index[99-1].laging.close*100000+1000;
         r[0].high=CS.Currencies.Currency[1].index[99].laging.high*100000+1000;
         r[0].low=CS.Currencies.Currency[1].index[99].laging.low*100000+1000;
         r[0].close=CS.Currencies.Currency[1].index[99].laging.close*100000+1000;
         
         //CustomRatesUpdate("EUR",r);
      }

      Sleep(1000);
   }

   SymbolSelect("EUR",false);
   CustomSymbolDelete("EUR");
}


int GetZeroBar()
{
   int bar=0, barsback=1500;
   datetime Arr[];
   if(CopyTime("EURUSD",PERIOD_M1,0,barsback,Arr)==barsback)
   {
      for(int i=barsback-2; i>=0; i--)
      {
         MqlDateTime dt;
         MqlDateTime dtp;
         TimeToStruct(Arr[i],dt);
         TimeToStruct(Arr[i+1],dtp);
         bar=barsback-1-i;
         if(dt.day!=dtp.day)
            break;
      }
   }
   return bar;
}
