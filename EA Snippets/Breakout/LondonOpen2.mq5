
//| ---------------------------------------
//| LondonOpen2.mq5
//| Copyright 2018, getYourNet.ch
//| ---------------------------------------

#property version   "1.00"

//#include <MultiPivots.mqh>
#include <Trade\Trade.mqh>

input int            MagicNumber = 5000;     // Magic Number
input int            BOMargin = 10;          // Breakout Margin
input int            RangeMinSize = 0;       // Range Min Size
input int            RangeMaxSize = 0;     // Range Max Size
input int            OpenHour = 9;           // Open Hour
input int            OpenMinute = 0;         // Open Minute
input int            OpenDayOfWeek = -1;      // Open Day of Week
input int            RangeBars = 1;         // Range Bars
input double         RiskPerTrade = 9;       // Risk per Trade
input int            HedgeCycles = 1;        // Hedge Cycles
input bool           HedgeNoClose = false;   // Hedge No Close
input bool           SetNoTP = true;        // Set No Take Profit
input double         VolumeMultiply = 2;     // Volume Multiply
input double         TPRangeSize = 95;      // Take Profit Range Size %
input bool           CurrentPairOnly = true; // Current Pair Only
input bool           CustomPairOpen = false;  // Custom Pair Open
input bool           TradeEURUSD = true;     // EURUSD
input int            EURUSDOpen = 0;        // EURUSD Open
input int            EURUSDBars = 0;        // EURUSD Range Bars
input bool           TradeGBPJPY = true;    // GBPJPY
input int            GBPJPYOpen = 0;        // GBPJPY Open
input int            GBPJPYBars = 0;        // GBPJPY Range Bars
input bool           TradeGBPUSD = true;     // GBPUSD
input int            GBPUSDOpen = 0;        // GBPUSD Open
input int            GBPUSDBars = 0;        // GBPUSD Range Bars
input bool           TradeGBPCAD = true;    // GBPCAD
input int            GBPCADOpen = 0;        // GBPCAD Open
input int            GBPCADBars = 0;        // GBPCAD Range Bars

struct TypeTradeInfo
{
   double initprice;
   double hedgeprice;
   bool initup;
   int tplevel;
   double initvolume;
   int hedgelevel;
   bool hedgeclosed;
};

struct TypePairInfo
{
   string symbol;
   TypeTradeInfo TradeInfo;
   int dayinuse;
   double point;
   int breakoutmargin;
   double tprangesize;
   bool tradeit;
   int openhour;
   int openminute;
   int rangebars;
};

TypePairInfo PairInfo[];

string pairs[]={"EURUSD","GBPJPY","GBPUSD","GBPCAD"};

string thischartpair;
int pairscount;

string namespace2="LondonOpen2 EA";
string context;
bool intimer=false;


void OnInit()
{
   string ExtraChars=StringSubstr(_Symbol, 6);
   thischartpair=StringSubstr(_Symbol, 0, 6);

   context=namespace2+" on "+thischartpair+" ";

   pairscount=ArraySize(pairs);
   bool contains=false;
   for(int i=0; i<pairscount; i++)
   {
      if(pairs[i]==thischartpair)
         contains=true;
   }
   if(!contains)
      pairscount++;

   datetime curTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(curTime,dt);
   
   Print(context+"Initialization Started, Server Time: "+IntegerToString(dt.hour)+":"+IntegerToString(dt.min));
   
   ArrayResize(PairInfo,pairscount);
   for(int i=0; i<pairscount; i++)
   {
      if(!contains&&i==(pairscount-1))
         PairInfo[i].symbol=thischartpair+ExtraChars;
      else
         PairInfo[i].symbol=pairs[i]+ExtraChars;
      PairInfo[i].point=SymbolInfoDouble(PairInfo[i].symbol,SYMBOL_POINT);
      PairInfo[i].breakoutmargin=BOMargin;
      PairInfo[i].tprangesize=TPRangeSize;
      PairInfo[i].openhour=OpenHour;
      PairInfo[i].openminute=OpenMinute;
      PairInfo[i].rangebars=RangeBars;

      PairInfo[i].tradeit=false;
      if(CurrentPairOnly&&PairInfo[i].symbol==(thischartpair+ExtraChars))
         PairInfo[i].tradeit=true;

      string p=StringSubstr(PairInfo[i].symbol,0,6);

      if(p=="EURUSD")
      {
         //PairInfo[i].breakoutmargin=95;
         //PairInfo[i].breakoutmargin=45;

         //PairInfo[i].breakoutmargin=75;
         //PairInfo[i].tprangesize=90;
         
         if(CustomPairOpen)
         {
            PairInfo[i].openhour=EURUSDOpen;
            PairInfo[i].rangebars=EURUSDBars;
         }

         if(!CurrentPairOnly)
            PairInfo[i].tradeit=TradeEURUSD;
      }
      if(p=="GBPJPY")
      {
         //PairInfo[i].breakoutmargin=15;
         //PairInfo[i].breakoutmargin=35;

         //PairInfo[i].breakoutmargin=30;
         //PairInfo[i].tprangesize=88;

         if(CustomPairOpen)
         {
            PairInfo[i].openhour=GBPJPYOpen;
            PairInfo[i].rangebars=GBPJPYBars;
         }

         if(!CurrentPairOnly)
            PairInfo[i].tradeit=TradeGBPJPY;
      }
      if(p=="GBPUSD")
      {
         //PairInfo[i].breakoutmargin=40;
         //PairInfo[i].breakoutmargin=55;

         //PairInfo[i].breakoutmargin=55;
         //PairInfo[i].tprangesize=98;

         if(CustomPairOpen)
         {
            PairInfo[i].openhour=GBPUSDOpen;
            PairInfo[i].rangebars=GBPUSDBars;
         }

         if(!CurrentPairOnly)
            PairInfo[i].tradeit=TradeGBPUSD;
      }
      if(p=="GBPCAD")
      {
         if(CustomPairOpen)
         {
            PairInfo[i].openhour=GBPCADOpen;
            PairInfo[i].rangebars=GBPCADBars;
         }

         if(!CurrentPairOnly)
            PairInfo[i].tradeit=TradeGBPCAD;
      }

      PairInfo[i].dayinuse=-1;
      if(dt.hour>PairInfo[i].openhour||(dt.hour==PairInfo[i].openhour&&PairInfo[i].openminute>=dt.min))
         PairInfo[i].dayinuse=dt.day;

   }

   EventSetTimer(1);
}


void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0,namespace2,0);
}


datetime GetCurrentCandleTime(TypePairInfo& pi)
{
   datetime time[1];
   CopyTime(pi.symbol, _Period, 0, 1, time);
   return(time[0]);
}


bool IsTradeOpen(TypePairInfo& pi)
{
   bool _IsTradeOpen=false;
   int i=PositionsTotal()-1;
   while(i>=0)
   {
      string symbol=PositionGetSymbol(i);
      long posmagic=PositionGetInteger(POSITION_MAGIC);
      //string poscomment=PositionGetString(POSITION_COMMENT);
      //if(poscomment==(namespace+" "+pi.symbol))
      if(posmagic==MagicNumber&&symbol==pi.symbol)
      {
         _IsTradeOpen=true;
         i=0;
      }
      i--;
   }
   return _IsTradeOpen;
}


double GetBasketProfit(TypePairInfo& pi)
{
   double profits=0;
   int i=PositionsTotal()-1;
   while(i>=0)
   {
      PositionGetSymbol(i);
      long posmagic=PositionGetInteger(POSITION_MAGIC);
      if(posmagic==MagicNumber)
      {
         profits+=PositionGetDouble(POSITION_PROFIT);
         //if(commissonperlot>0)
         //   profits-=(PositionGetDouble(POSITION_VOLUME)*commissonperlot);
      }
      i--;
   }
   IsTradeOpen(pi);
   return profits;
}


void ClosePosition(TypePairInfo& pi, bool all=false)
{
   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);
   int i=PositionsTotal()-1;
   while(i>=0)
   {
      string symbol=PositionGetSymbol(i);
      long posmagic=PositionGetInteger(POSITION_MAGIC);
      if(posmagic==MagicNumber)
      {
         if(symbol==pi.symbol||all)
            trade.PositionClose(PositionGetSymbol(i));
      }
      i--;
   }
}


void CheckForClose(TypePairInfo& pi)
{
   if(pi.TradeInfo.hedgeclosed)
      return;

   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);

   double basketprofit=GetBasketProfit(pi);

   MqlRates current[];
   if(CopyRates(pi.symbol,_Period,0,1,current)==-1)
      return;

   datetime curTime=GetCurrentCandleTime(pi);
   MqlDateTime dt;
   TimeToStruct(curTime,dt);

   if(dt.hour>pi.openhour||(dt.hour==pi.openhour&&dt.min>=pi.openminute))
      pi.dayinuse=dt.day;

   //if(basketprofit>0&&dt.hour>=(pi.openhour+3))
   //{
   //   ClosePosition(pi,true);
   //   return;
   //}

   if(pi.TradeInfo.tplevel==3)
      return;
      
   bool hedgeup=false, hedgedown=false;
   int margin=pi.breakoutmargin;
   if(pi.TradeInfo.initup)
   {
      if(current[0].close>=pi.TradeInfo.initprice+(((pi.TradeInfo.initprice-pi.TradeInfo.hedgeprice)*(pi.tprangesize/100))*pi.TradeInfo.tplevel))
      {
         if(!trade.PositionClosePartial(pi.symbol,NormalizeDouble(pi.TradeInfo.initvolume/2,2)))
            return;
         double newsl=pi.TradeInfo.initprice+((pi.TradeInfo.initprice-pi.TradeInfo.hedgeprice)*(pi.TradeInfo.tplevel-1));
         if(!trade.PositionModify(pi.symbol,newsl,PositionGetDouble(POSITION_TP)))
            return;
         pi.TradeInfo.tplevel++;
      }
      if(current[0].close<=pi.TradeInfo.hedgeprice)
      {
         if(!HedgeNoClose)
            trade.PositionClose(pi.symbol);
         else
            pi.TradeInfo.hedgeclosed=true;
         hedgedown=true;
      }
   }
   else
   {
      if(current[0].close<=pi.TradeInfo.initprice-(((pi.TradeInfo.hedgeprice-pi.TradeInfo.initprice)*(pi.tprangesize/100))*pi.TradeInfo.tplevel))
      {
         if(!trade.PositionClosePartial(pi.symbol,NormalizeDouble(pi.TradeInfo.initvolume/2,2)))
            return;
         double newsl=pi.TradeInfo.initprice-((pi.TradeInfo.hedgeprice-pi.TradeInfo.initprice)*(pi.TradeInfo.tplevel-1));
         if(!trade.PositionModify(pi.symbol,newsl,PositionGetDouble(POSITION_TP)))
            return;
         pi.TradeInfo.tplevel++;
      }
      if(current[0].close>=pi.TradeInfo.hedgeprice)
      {
         if(!HedgeNoClose)
            trade.PositionClose(pi.symbol);
         else
            pi.TradeInfo.hedgeclosed=true;
         hedgeup=true;
      }
   }


   if((hedgeup||hedgedown)&&pi.TradeInfo.hedgelevel<HedgeCycles)
   {
      pi.TradeInfo.tplevel=1;
      pi.TradeInfo.hedgelevel++;

      ENUM_ORDER_TYPE type=ORDER_TYPE_BUY;
      double price=0, sl=0, tp=0, volume=0;

      pi.TradeInfo.hedgeprice=pi.TradeInfo.initprice;
      if(hedgeup)
      {
         type=ORDER_TYPE_BUY;
         price = SymbolInfoDouble(pi.symbol, SYMBOL_ASK);
         tp = price+((price-pi.TradeInfo.hedgeprice)*3);
         pi.TradeInfo.initup=true;
         sl=price-((price-pi.TradeInfo.hedgeprice)/2);
      }
      if(hedgedown)
      {
         type=ORDER_TYPE_SELL;
         price = SymbolInfoDouble(pi.symbol, SYMBOL_BID);
         tp = price-((pi.TradeInfo.hedgeprice-price)*3);
         pi.TradeInfo.initup=false;
         sl=price+((pi.TradeInfo.hedgeprice-price)/2);
      }
      pi.TradeInfo.initprice=price;
      volume = NormalizeDouble(pi.TradeInfo.initvolume*VolumeMultiply,2);
      pi.TradeInfo.initvolume=volume;
      if(SetNoTP)
         tp=NULL;
      trade.PositionOpen(pi.symbol, type, volume, price, NULL, tp, namespace2+" "+pi.symbol);
   }
}


void CheckForOpen(TypePairInfo& pi)
{
   datetime curTime=GetCurrentCandleTime(pi);
   static datetime prevTime;
   
   //if ( curTime == prevTime ) {
   //   return;
   //}

   MqlDateTime dt;
   TimeToStruct(curTime,dt);
   if(OpenDayOfWeek>-1&&OpenDayOfWeek!=dt.day_of_week)
      return;
   if((dt.hour<pi.openhour||(dt.hour==pi.openhour&&dt.min<pi.openminute))||dt.hour>(pi.openhour+2)||pi.dayinuse==dt.day)
      return;

   //if(dt.day_of_week!=2&&dt.day_of_week!=1)
   //if(dt.day_of_week!=2)
   //   return;

   dt.hour=pi.openhour;
   dt.min=pi.openminute;
   dt.sec=0;
   datetime endtime = StructToTime(dt);
   //datetime starttime = endtime-14400;
   //datetime starttime = endtime-28800;
   datetime starttime = endtime-(PeriodSeconds(_Period)*pi.rangebars);
   //datetime starttime = endtime-7200;
   endtime=endtime-1;

   double highs[], lows[], MaValues[];
   MqlRates current[];
   if(CopyHigh(pi.symbol,_Period,starttime,endtime,highs)==-1)
      return;
   if(CopyLow(pi.symbol,_Period,starttime,endtime,lows)==-1)
      return;
   if(CopyRates(pi.symbol,_Period,0,1,current)==-1)
      return;
   //if(CopyBuffer(MaHandle,0,0,10,MaValues)<10)
      //return;

   int margin=pi.breakoutmargin;
   double highrange=highs[ArrayMaximum(highs)]+(pi.point*margin);
   double lowrange=lows[ArrayMinimum(lows)]-(pi.point*margin);
   double maxhighrange=highrange+(pi.point*margin);
   double minlowrange=lowrange-(pi.point*margin);

   double rangepoints=(highrange-lowrange)/pi.point;
   if(RangeMinSize>0&&rangepoints<RangeMinSize)
      return;
   if(RangeMaxSize>0&&rangepoints>RangeMaxSize)
      return;

   if(CurrentPairOnly)
   {
      string objname=namespace2+" Range";
      ObjectDelete(0,objname);
      ObjectCreate(0,objname,OBJ_RECTANGLE,0,starttime,highrange,endtime+1,lowrange);
      ObjectSetInteger(0,objname,OBJPROP_BACK,true);
      ObjectSetInteger(0,objname,OBJPROP_FILL,true);
      ObjectSetInteger(0,objname,OBJPROP_COLOR,C'248,248,248');
   }

   //bool upbreakout=current[0].close>=highrange+(pi.point*margin);
   //bool downbreakout=current[0].close<=lowrange-(pi.point*margin);
   bool upbreakout=current[0].close>=highrange&&current[0].close<=maxhighrange;
   bool downbreakout=current[0].close<=lowrange&&current[0].close>=minlowrange;

   //if(upbreakout)
   //   return;

   //int hedgerange=300;
   if(upbreakout||downbreakout)
   {
      pi.TradeInfo.tplevel=1;
      pi.TradeInfo.hedgelevel=0;
      pi.TradeInfo.hedgeclosed=false;
   
      ENUM_ORDER_TYPE type=ORDER_TYPE_BUY;
      double price=0, sl=0, tp=0, volume=0, riskrange=0;
      double stopLevel = SymbolInfoInteger(pi.symbol, SYMBOL_TRADE_STOPS_LEVEL) * pi.point;
      CTrade trade;
      trade.SetExpertMagicNumber(MagicNumber);

      if(upbreakout)
      {
         type = ORDER_TYPE_BUY;
         price = SymbolInfoDouble(pi.symbol, SYMBOL_ASK);
         pi.TradeInfo.initup=true;
         //pi.TradeInfo.initprice=price;
         pi.TradeInfo.initprice=highrange;
         //pi.TradeInfo.hedgeprice=price-(hedgerange*pi.point);
         pi.TradeInfo.hedgeprice=lowrange;
         sl = lowrange;
         riskrange=price-sl;
         //sl = price-calculateDistance(price, 200);
         //tp = price+calculateDistance(price, 15000);
         //tp = price+((price-lowrange)*3);
         tp = highrange+(((highrange-lowrange)*(pi.tprangesize/100))*3);
         //tp = price+calculateDistance(price, 300);
      }
   
      if(downbreakout)
      {
         type = ORDER_TYPE_SELL;
         price = SymbolInfoDouble(pi.symbol, SYMBOL_BID);
         pi.TradeInfo.initup=false;
         //pi.TradeInfo.initprice=price;
         pi.TradeInfo.initprice=lowrange;
         //pi.TradeInfo.hedgeprice=price+(hedgerange*pi.point);
         pi.TradeInfo.hedgeprice=highrange;
         sl = highrange;
         riskrange=sl-price;
         //sl = price+calculateDistance(price, 200);
         //tp = price-calculateDistance(price, 15000);
         //tp = price-((highrange-price)*3);
         tp = lowrange-(((highrange-lowrange)*(pi.tprangesize/100))*3);
         //tp = price-calculateDistance(price, 300);
      }
      if(SetNoTP)
         tp=NULL;


      //double tickSize      = SymbolInfoDouble(pi.symbol,SYMBOL_TRADE_TICK_SIZE);
      //double tickValue     = SymbolInfoDouble(pi.symbol,SYMBOL_TRADE_TICK_VALUE);
      //double valueToRisk   = risk / 100 * capital;
      //double tickCount     = sldistance / tickSize;
      //double lots          = valueToRisk / (tickCount * tickValue);
      ////--
      //double tickValueSize = tickValue * pi.point / tickSize;
      //double spread        = (double)SymbolInfoInteger(pi.symbol,SYMBOL_SPREAD);
      //double stoploss      = valueToRisk  / (lots * tickValueSize) - spread;


      double TickValue=SymbolInfoDouble(pi.symbol,SYMBOL_TRADE_TICK_VALUE); //tick value deposit ccy
      if(TickValue==0)
         return;
      double TickSize=SymbolInfoDouble(pi.symbol,SYMBOL_TRADE_TICK_SIZE);  //tick size in points
      double PointValue=TickValue/(TickSize/pi.point);                     //1 point in deposit ccy

      double riskpoints=MathAbs(NormalizeDouble(riskrange,(int)SymbolInfoInteger(pi.symbol,SYMBOL_DIGITS))/pi.point);
      double amounttorisk=(AccountInfoDouble(ACCOUNT_BALANCE)/100)*RiskPerTrade;
      volume=NormalizeDouble(amounttorisk/(riskpoints*PointValue),2);

//      Print(DoubleToString(PointValue));
//      Print(DoubleToString(riskpoints));
//      Print(DoubleToString(amounttorisk));
//      Print(DoubleToString(riskpoints*PointValue));
//      Print(DoubleToString(volume));
//
//      double tick_value=SymbolInfoDouble(pi.symbol,SYMBOL_TRADE_TICK_VALUE);
//      double sl_value=tick_value*riskrange;
//      double amount_to_risk=(AccountInfoDouble(ACCOUNT_BALANCE)/100)*0.00003;
      //volume=NormalizeDouble(amount_to_risk/sl_value,2);
      //volume = 0.3;
      pi.TradeInfo.initvolume=volume;
      trade.PositionOpen(pi.symbol, type, volume, price, NULL, tp, namespace2+" "+pi.symbol);
      //trade.PositionOpen(pi.symbol, type, volume, price, sl, tp);
      //trade.PositionOpen(pi.symbol, type, volume, price, NULL, NULL);
      
   }

   prevTime = curTime;
}


void OnTimer()
{
   if(intimer)
      return;
   intimer=true;
   for(int i=0; i<pairscount; i++)
   {
      if(PairInfo[i].tradeit)
      {
         if(IsTradeOpen(PairInfo[i]))
            CheckForClose(PairInfo[i]);
         else
            CheckForOpen(PairInfo[i]);
      }
   }
   intimer=false;
}


void OnTick()
{
   static datetime Old_Time;
   datetime New_Time[1];
   bool IsNewBar=false;
   int barcount=Bars(_Symbol,_Period);

   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0)
   {
      if(Old_Time!=New_Time[0])
      {
         IsNewBar=true;
         Old_Time=New_Time[0];
      }
   }
   if(IsNewBar)
   {
      //PD.Calculate(New_Time[0]);
   }
}
