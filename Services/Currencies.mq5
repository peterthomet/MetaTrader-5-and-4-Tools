//
// Currencies.mq5
//

#property service
#property copyright "Copyright 2020, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"

input int TotalBars = 200000; // Total Bars
input bool FillGaps = false; // Fill Gaps

#include <CurrencyStrength.mqh>

enum States
{
   Prep1,
   Prep2,
   Initial,
   InitialCSReady,
   InitialCSLoaded,
   DayCSReady
};

struct TypeCurrencyRates
{
   MqlRates r[];
};

struct TypeCurrenciesRates
{
   TypeCurrencyRates c[8];
   void Init(int size)
   {
      for(int i=0; i<8; i++)
         ArrayResize(c[i].r,size,size/2);
   }
   void Resize(int size, int gap, int index)
   {
      for(int i=0; i<8; i++)
      {
         ArrayResize(c[i].r,size);
         for(int y=0; y<gap; y++)
         {
            c[i].r[index+y].time=c[i].r[index-1].time+(60*(y+1));
            c[i].r[index+y].open=c[i].r[index-1].close;
            c[i].r[index+y].high=c[i].r[index-1].close;
            c[i].r[index+y].low=c[i].r[index-1].close;
            c[i].r[index+y].close=c[i].r[index-1].close;
         }
      }
   }
};

TypeCurrencyStrength CS;
States InitState=Prep1;
datetime lastm1bar=0;
datetime m1initbar=0;
double lasttick[8];
bool secondinit=false;


int IdBySymbol(string symbol)
{
   if(symbol=="USD") return 0;
   if(symbol=="EUR") return 1;
   if(symbol=="GBP") return 2;
   if(symbol=="JPY") return 3;
   if(symbol=="CHF") return 4;
   if(symbol=="CAD") return 5;
   if(symbol=="AUD") return 6;
   if(symbol=="NZD") return 7;
   return -1;
}


string SymbolById(int id)
{
   if(id==0) return "USD";
   if(id==1) return "EUR";
   if(id==2) return "GBP";
   if(id==3) return "JPY";
   if(id==4) return "CHF";
   if(id==5) return "CAD";
   if(id==6) return "AUD";
   if(id==7) return "NZD";
   return "";
}


void OnStart()
{

   ArrayInitialize(lasttick,0);

   while(!IsStopped())
   {
      bool reset=false;

      if(InitState==Prep1 || InitState==Prep2)
      {
         Sleep(3000);
         TypePairs p;
         datetime dt[1];
         for(int i=0; i<28; i++)
         {
            if(CopyTime(p.Pair[i].name,PERIOD_M1,0,1,dt)==1)
            {
               if(i==0)
               {
                  Print("Prep M1 Bar Time: "+TimeToString(dt[0]));
                  if(m1initbar==dt[0])
                     InitState++;
                  m1initbar=dt[0];
               }
            }
         }
      }

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
         Print("Init Start");
         if(LoadCS(CS.bars-1,true))
         {
            InitState=InitialCSLoaded;
            Print("Ready");
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
            
            secondinit=true;
            if(!secondinit)
            {
               Print("First Init done, we wait one minute and run the second Init");
               Sleep(60000);
               InitState=Initial;
               secondinit=true;
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
//   if(lasttick[IdBySymbol(symbol)]==0)
//   {
//      lasttick[IdBySymbol(symbol)]=price;
//      return;
//   }
//
//   if(lasttick[IdBySymbol(symbol)]==price)
//      return;

   MqlTick t[1];
   t[0].time_msc=time*1000;
   t[0].last=price;
   t[0].bid=t[0].last;
   t[0].ask=t[0].last;
   t[0].volume=0;
   //Print("Add Tick "+time);
   CustomTicksAdd(symbol,t);
   //CustomTicksReplace(symbol,t[0].time_msc-(PeriodSeconds(PERIOD_MN1)*1000),t[0].time_msc,t);

//   lasttick[IdBySymbol(symbol)]=price;
}


bool LoadCS(int updatebars, bool deleteall)
{
   if(CS_CalculateIndex(CS,0))
   {
      TypeCurrenciesRates cr,cr2;
      cr.Init(updatebars);
      cr2.Init(updatebars);
      int gapshift=0;

      for(int i=(CS.bars-updatebars); i<CS.bars; i++)
      {
         int n=i-(CS.bars-updatebars);

         for(int z=0; z<8; z++)
            GetValues(cr.c[z].r[n],CS.Currencies.Currency[z],i);

         if(FillGaps && n>0)
         {
            int minutesgap=(int)((cr.c[0].r[n].time-cr.c[0].r[n-1].time)/60)-1;
            gapshift+=minutesgap;

            if(minutesgap>0)
               cr2.Resize(updatebars+gapshift,minutesgap,n+gapshift-minutesgap);
         }

         for(int z=0; z<8; z++)
            cr2.c[z].r[n+gapshift]=cr.c[z].r[n];
      }
      
      for(int z=0; z<8; z++)
         UpdateRates(cr2.c[z].r,SymbolById(z),deleteall);

      return true;
   }
   else
      return false;
}


void ClearAllSymbolRates()
{
   for(int z=0; z<8; z++)
      ClearSymbolRates(SymbolById(z));
}


void ClearSymbolRates(string symbol)
{
   CustomRatesDelete(symbol,TimeCurrent()-(PeriodSeconds(PERIOD_MN1)*24),TimeCurrent());
   CustomTicksDelete(symbol,(TimeCurrent()-(PeriodSeconds(PERIOD_MN1)*24))*1000,(TimeCurrent()+1000)*1000);
}


void UpdateRates(MqlRates& rates[], string symbol, bool deleteall)
{
   if(deleteall)
   {
      ClearSymbolRates(symbol);
      CustomRatesUpdate(symbol,rates);
   }

   int s=ArraySize(rates);
   AddTick(rates[s-1].close,rates[s-1].time,symbol);
}


void GetValues(MqlRates& rates, TypeCurrency& currency, int i)
{
   rates.time=currency.index[i].time;
   rates.open=currency.index[i-1].laging.close*100000+100000;
   rates.high=currency.index[i].laging.high*100000+100000;
   rates.low=currency.index[i].laging.low*100000+100000;
   rates.close=currency.index[i].laging.close*100000+100000;
}


void DeleteSymbols()
{
   for(int z=0; z<8; z++)
   {
      SymbolSelect(SymbolById(z),false);
      CustomSymbolDelete(SymbolById(z));
   }
}


void CreateAndSelectSymbols()
{
   for(int z=0; z<8; z++)
   {
      CustomSymbolCreate(SymbolById(z));
      SymbolSelect(SymbolById(z),true);
   }
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
