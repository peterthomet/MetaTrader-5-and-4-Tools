//
// Currencies.mq5
//

#property service
#property copyright "Copyright 2020, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"

input int TotalBars = 90000; // Total Bars

#include <CurrencyStrength.mqh>

enum States
{
   Initial,
   InitialCSReady,
   InitialCSLoaded,
   DayCSReady
};

TypeCurrencyStrength CS;
States InitState=Initial;
datetime lastm1bar=0;


void OnStart()
{
   while(!IsStopped())
   {
      bool reset=false;

      if(InitState==Initial)
      {
         if(InitCS(TotalBars))
         {
            CreateAndSelectSymbols();
            InitState=InitialCSReady;
         }
      }

      if(InitState==InitialCSReady)
      {
         if(LoadCS(CS.bars-1,true))
         {
            InitState=InitialCSLoaded;
         }
      }

      if(InitState==InitialCSLoaded)
      {
         if(InitCS(1450))
         {
            CS.recalculate=true;
            InitState=DayCSReady;
         }
      }

      if(InitState==DayCSReady)
      {
         datetime dt[1];
         if(CopyTime("EURUSD",PERIOD_M1,0,1,dt)==1)
         {
            if(dt[0]!=lastm1bar)
            {
               InitState=InitialCSLoaded;
               lastm1bar=dt[0];
               reset=true;
            }
            else
            {
               LoadCS(3,false);
            }
         }
      }

      if(!reset)
         Sleep(1000);
   }

   //DeleteSymbols();
}


void AddTick(double price, datetime time, string symbol)
{
   MqlTick t[1];
   t[0].time_msc=time*1000;
   t[0].last=price;
   t[0].bid=t[0].last;
   t[0].ask=t[0].last;
   CustomTicksAdd(symbol,t);
}


bool LoadCS(int updatebars, bool deleteall)
{
   if(CS_CalculateIndex(CS,0))
   {
      MqlRates ratesUSD[], ratesEUR[], ratesGBP[], ratesJPY[], ratesCHF[], ratesCAD[], ratesAUD[], ratesNZD[];
      ArrayResize(ratesUSD,updatebars);
      ArrayResize(ratesEUR,updatebars);
      ArrayResize(ratesGBP,updatebars);
      ArrayResize(ratesJPY,updatebars);
      ArrayResize(ratesCHF,updatebars);
      ArrayResize(ratesCAD,updatebars);
      ArrayResize(ratesAUD,updatebars);
      ArrayResize(ratesNZD,updatebars);

      for(int i=(CS.bars-updatebars); i<CS.bars; i++)
      {
         int n=i-(CS.bars-updatebars);
         GetValues(ratesUSD[n],CS.Currencies.Currency[0],i);
         GetValues(ratesEUR[n],CS.Currencies.Currency[1],i);
         GetValues(ratesGBP[n],CS.Currencies.Currency[2],i);
         GetValues(ratesJPY[n],CS.Currencies.Currency[3],i);
         GetValues(ratesCHF[n],CS.Currencies.Currency[4],i);
         GetValues(ratesCAD[n],CS.Currencies.Currency[5],i);
         GetValues(ratesAUD[n],CS.Currencies.Currency[6],i);
         GetValues(ratesNZD[n],CS.Currencies.Currency[7],i);
      }
      
      UpdateRates(ratesUSD,"USD",deleteall);
      UpdateRates(ratesEUR,"EUR",deleteall);
      UpdateRates(ratesGBP,"GBP",deleteall);
      UpdateRates(ratesJPY,"JPY",deleteall);
      UpdateRates(ratesCHF,"CHF",deleteall);
      UpdateRates(ratesCAD,"CAD",deleteall);
      UpdateRates(ratesAUD,"AUD",deleteall);
      UpdateRates(ratesNZD,"NZD",deleteall);

      return true;
   }
   else
      return false;
}


void UpdateRates(MqlRates& rates[], string symbol, bool deleteall)
{
   if(deleteall)
   {
      CustomRatesDelete(symbol,TimeCurrent()-(PeriodSeconds(PERIOD_MN1)*24),TimeCurrent());
      CustomTicksDelete(symbol,(TimeCurrent()-(PeriodSeconds(PERIOD_MN1)*24))*1000,(TimeCurrent()+1000)*1000);
   }
   CustomRatesUpdate(symbol,rates);
   
   int s=ArraySize(rates);
   AddTick(rates[s-1].close,rates[s-1].time,symbol);
}


void GetValues(MqlRates& rates, TypeCurrency& currency, int i)
{
   rates.time=currency.index[i].time;
   rates.open=currency.index[i-1].laging.close*100000+1000;
   rates.high=currency.index[i].laging.high*100000+1000;
   rates.low=currency.index[i].laging.low*100000+1000;
   rates.close=currency.index[i].laging.close*100000+1000;
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


bool InitCS(int bars)
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
