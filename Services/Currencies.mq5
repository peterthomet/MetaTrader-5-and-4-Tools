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
enum StateLevels
{
   Initial,
   ZeroBarAvailable,
   InitialCSLoaded
};
StateLevels InitState=Initial;


void OnStart()
{
   InitCS();

   CreateAndSelectSymbols();

   LoadInitialCS();

   while(!IsStopped())
   {
      if(CS_CalculateIndex(CS,0))
         AddTick(CS.Currencies.Currency[1].index[bars-1].laging.close*100000+1000,CS.Currencies.Currency[1].index[bars-1].time,"EUR");

      Sleep(1000);
   }

   DeleteSymbols();
}


void AddTick(double price, datetime time, string symbol)
{
   MqlTick t[1];
   t[0].time=time;
   t[0].last=price;
   t[0].bid=t[0].last;
   t[0].ask=t[0].last;
   CustomTicksAdd(symbol,t);
}


bool LoadInitialCS()
{
   MqlRates rates[];
   ArrayResize(rates,bars-1);
 
   if(CS_CalculateIndex(CS,0))
   {
      for(int i=1; i<bars; i++)
      {
         rates[i-1].time=CS.Currencies.Currency[1].index[i].time;
         rates[i-1].open=CS.Currencies.Currency[1].index[i-1].laging.close*100000+1000;
         rates[i-1].high=CS.Currencies.Currency[1].index[i].laging.high*100000+1000;
         rates[i-1].low=CS.Currencies.Currency[1].index[i].laging.low*100000+1000;
         rates[i-1].close=CS.Currencies.Currency[1].index[i].laging.close*100000+1000;
      }
      
      CustomRatesDelete("EUR",TimeCurrent()-(PeriodSeconds(PERIOD_MN1)*24),TimeCurrent());
      CustomTicksDelete("EUR",(TimeCurrent()-(PeriodSeconds(PERIOD_MN1)*24))*1000,TimeCurrent()*1000);
      CustomRatesUpdate("EUR",rates);

      return true;
   }
   else
      return false;
}


void DeleteSymbols()
{
   SymbolSelect("EUR",false);
   CustomSymbolDelete("EUR");
}


void CreateAndSelectSymbols()
{
   CustomSymbolCreate("EUR",NULL,"EURUSD");
   SymbolSelect("EUR",true);
}


bool InitCS()
{
   int ZeroBar=GetZeroBar();
   if(ZeroBar==0)
      return false;

   CS.Init(
      bars,
      ZeroBar,
      "",
      PERIOD_M1,
      false,
      pr_close,
      0,
      0,
      false
      );

   return true;
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
