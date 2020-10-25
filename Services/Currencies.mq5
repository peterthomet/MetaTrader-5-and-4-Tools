//
// Currencies.mq5
//

#property service
#property copyright "Copyright 2020, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"

input int TotalBars = 90000; // Total Bars

#include <CurrencyStrength.mqh>
TypeCurrencyStrength CS;
enum States
{
   Initial,
   ZeroBarAvailable,
   InitialCSLoaded
};
States InitState=Initial;


void OnStart()
{
   while(!IsStopped())
   {
      if(InitState==Initial)
      {
         if(InitCS())
         {
            CreateAndSelectSymbols();
            InitState=ZeroBarAvailable;
         }
      }

      if(InitState==ZeroBarAvailable)
      {
         if(LoadInitialCS())
         {
            //AddTick(CS.Currencies.Currency[1].index[TotalBars-1].laging.close*100000+1000,(CS.Currencies.Currency[1].index[TotalBars-1].time*1000)+1,"EUR");

            InitState=InitialCSLoaded;
         }
      }

      if(InitState==InitialCSLoaded)
      {
         //if(CS_CalculateIndex(CS,0))
         //   AddTick(CS.Currencies.Currency[1].index[TotalBars-1].laging.close*100000+1000,CS.Currencies.Currency[1].index[TotalBars-1].time,"EUR");

      }

      Sleep(1000);
   }

   //DeleteSymbols();
}


void AddTick(double price, long time, string symbol)
{
   MqlTick t[1];
   t[0].time_msc=time;
   t[0].last=price;
   t[0].bid=t[0].last;
   t[0].ask=t[0].last;
   CustomTicksAdd(symbol,t);
}


bool LoadInitialCS()
{
   MqlRates rates[];
   ArrayResize(rates,TotalBars-1);
 
   if(CS_CalculateIndex(CS,0))
   {
      for(int i=1; i<TotalBars; i++)
      {
         rates[i-1].time=CS.Currencies.Currency[1].index[i].time;
         rates[i-1].open=CS.Currencies.Currency[1].index[i-1].laging.close*100000+1000;
         rates[i-1].high=CS.Currencies.Currency[1].index[i].laging.high*100000+1000;
         rates[i-1].low=CS.Currencies.Currency[1].index[i].laging.low*100000+1000;
         rates[i-1].close=CS.Currencies.Currency[1].index[i].laging.close*100000+1000;
      }
      
      CustomRatesDelete("EUR",TimeCurrent()-(PeriodSeconds(PERIOD_MN1)*24),TimeCurrent());
      CustomTicksDelete("EUR",(TimeCurrent()-(PeriodSeconds(PERIOD_MN1)*24))*1000,(TimeCurrent()+1000)*1000);
      CustomRatesUpdate("EUR",rates);

      return true;
   }
   else
      return false;
}


void DeleteSymbols()
{
   SymbolSelect("USD",false);
   CustomSymbolDelete("USD");
   SymbolSelect("EUR",false);
   CustomSymbolDelete("EUR");
   SymbolSelect("GBP",false);
   CustomSymbolDelete("GBP");
   SymbolSelect("JPY",false);
   CustomSymbolDelete("JPY");
   SymbolSelect("CHF",false);
   CustomSymbolDelete("CHF");
   SymbolSelect("CAD",false);
   CustomSymbolDelete("CAD");
   SymbolSelect("AUD",false);
   CustomSymbolDelete("AUD");
   SymbolSelect("NZD",false);
   CustomSymbolDelete("NZD");
}


void CreateAndSelectSymbols()
{
   CustomSymbolCreate("USD");
   SymbolSelect("USD",true);
   CustomSymbolCreate("EUR");
   SymbolSelect("EUR",true);
   CustomSymbolCreate("GBP");
   SymbolSelect("GBP",true);
   CustomSymbolCreate("JPY");
   SymbolSelect("JPY",true);
   CustomSymbolCreate("CHF");
   SymbolSelect("CHF",true);
   CustomSymbolCreate("CAD");
   SymbolSelect("CAD",true);
   CustomSymbolCreate("AUD");
   SymbolSelect("AUD",true);
   CustomSymbolCreate("NZD");
   SymbolSelect("NZD",true);
}


bool InitCS()
{
   int ZeroBar=GetZeroBar();
   if(ZeroBar==0)
      return false;

   CS.Init(
      TotalBars,
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
