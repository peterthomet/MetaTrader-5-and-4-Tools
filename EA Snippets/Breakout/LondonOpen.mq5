
//| ---------------------------------------
//| Breakout1.mq5
//| Copyright 2018, getYourNet.ch
//| ---------------------------------------

#property version   "1.00"

#include <MultiPivots.mqh>
#include <Trade\Trade.mqh>

enum REVERSAL_MODE {
   PIPS,       // In pips
   PERCENT     // In percentage
};

enum REVERSAL {
   TO_DOWN = -1,
   NO_CHANGE = 0,
   TO_UP = 1
};

input int            MagicNumber = 5555;     // Magic Number
input int            BOMargin = 15;          // Breakout Margin
input int            OpenHour = 9;           // Open Hour
input double         RiskPerTrade = 3;       // Risk per Trade
input int            HedgeCycles = 1;        // Hedge Cycles
input double         VolumeMultiply = 2;     // Volume Multiply

double               delta;
double               stopLoss;
double               takeProfit;
//int                  bbtHandle;
//int                  MaHandle;
int                  negatives;
int lastupday;
int lastdownday;
double peakwin;
int dayinuse;

struct TypeTradesinfo
{
   double initprice;
   double hedgeprice;
   bool initup;
   int tplevel;
   double initvolume;
   int hedgelevel;
};
TypeTradesinfo Tradesinfo;


int OnInit() {
   return(0);
}


void OnDeinit(const int reason) {
   //IndicatorRelease(bbtHandle);
   //IndicatorRelease(MaHandle);
}


double checkVolumeValue(double volume) {
   double minVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if ( volume < minVolume ) {
      volume = minVolume;
   } else if ( volume > maxVolume ) {
      volume = maxVolume;
   }
   int digits = (int)MathCeil(MathLog10(1/volumeStep));
   return(NormalizeDouble(volume, digits));
}

datetime getCurrentTime() {
   datetime time[1];
   CopyTime(_Symbol, _Period, 0, 1, time);
   return(time[0]);
}


double calculateDistance(double price, double distance) {
   //if ( InpReversal == PIPS ) {
      return(NormalizeDouble(distance*_Point, _Digits));
   //}
   //return(NormalizeDouble((price/100)*distance, _Digits));
}


bool IsTRadeOpen()
{
   bool _IsTradeOpen=false;
   int i=PositionsTotal()-1;
   while(i>=0)
   {
      PositionGetSymbol(i);
      long posmagic=PositionGetInteger(POSITION_MAGIC);
      if(posmagic==MagicNumber)
      {
         _IsTradeOpen=true;
         i=0;
      }
      i--;
   }
   return _IsTradeOpen;
}


double GetProfits()
{
   double profits=0;
   int i=PositionsTotal()-1;
   while(i>=0)
   {
      PositionGetSymbol(i);
      profits+=PositionGetDouble(POSITION_PROFIT);
      i--;
   }
   return profits;
}


void CloseAll()
{
   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);

   int i=PositionsTotal()-1;
   while(i>=0)
   {
      trade.PositionClose(PositionGetSymbol(i));
      i--;
   }
}


void checkForClose()
{
   MqlRates current[];
   if(CopyRates(_Symbol,_Period,0,1,current)==-1)
      return;

   datetime curTime = getCurrentTime();

   MqlDateTime dt;
   TimeToStruct(curTime,dt);

   if(dt.hour>=OpenHour)
      dayinuse=dt.day;

   if(Tradesinfo.tplevel==3)
      return;
      
   bool hedgeup=false, hedgedown=false;
   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);
   if(Tradesinfo.initup)
   {
      if(current[0].close>=Tradesinfo.initprice+((Tradesinfo.initprice-Tradesinfo.hedgeprice)*Tradesinfo.tplevel))
      {
         trade.PositionClosePartial(_Symbol,NormalizeDouble(Tradesinfo.initvolume/3,2));
         trade.PositionModify(_Symbol,Tradesinfo.initprice+((Tradesinfo.initprice-Tradesinfo.hedgeprice)*(Tradesinfo.tplevel-1)),PositionGetDouble(POSITION_TP));
         Tradesinfo.tplevel++;
      }
      if(current[0].close<=Tradesinfo.hedgeprice)
      {
         trade.PositionClose(_Symbol);
         hedgedown=true;
      }
   }
   else
   {
      if(current[0].close<=Tradesinfo.initprice-((Tradesinfo.hedgeprice-Tradesinfo.initprice)*Tradesinfo.tplevel))
      {
         trade.PositionClosePartial(_Symbol,NormalizeDouble(Tradesinfo.initvolume/3,2));
         trade.PositionModify(_Symbol,Tradesinfo.initprice-((Tradesinfo.hedgeprice-Tradesinfo.initprice)*(Tradesinfo.tplevel-1)),PositionGetDouble(POSITION_TP));
         Tradesinfo.tplevel++;
      }
      if(current[0].close>=Tradesinfo.hedgeprice)
      {
         trade.PositionClose(_Symbol);
         hedgeup=true;
      }
   }


   if((hedgeup||hedgedown)&&Tradesinfo.hedgelevel<HedgeCycles)
   {
      Tradesinfo.tplevel=1;
      Tradesinfo.hedgelevel++;

      ENUM_ORDER_TYPE type=ORDER_TYPE_BUY;
      double price=0, sl=0, tp=0, volume=0;

      Tradesinfo.hedgeprice=Tradesinfo.initprice;
      if(hedgeup)
      {
         type=ORDER_TYPE_BUY;
         price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         tp = price+((price-Tradesinfo.hedgeprice)*3);
         Tradesinfo.initup=true;
      }
      if(hedgedown)
      {
         type=ORDER_TYPE_SELL;
         price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         tp = price-((Tradesinfo.hedgeprice-price)*3);
         Tradesinfo.initup=false;
      }
      Tradesinfo.initprice=price;
      volume = NormalizeDouble(Tradesinfo.initvolume*VolumeMultiply,2);
      Tradesinfo.initvolume=volume;
      trade.PositionOpen(_Symbol, type, volume, price, NULL, tp);
   }
}


void checkForOpen() {
   datetime curTime = getCurrentTime();
   static datetime prevTime;
   
   //if ( curTime == prevTime ) {
   //   return;
   //}

   MqlDateTime dt;
   TimeToStruct(curTime,dt);
   if(dt.hour<OpenHour||dt.hour>(OpenHour+2)||dayinuse==dt.day)
      return;

   dt.hour=OpenHour;
   dt.min=0;
   dt.sec=0;
   datetime endtime = StructToTime(dt);
   //datetime starttime = endtime-14400;
   //datetime starttime = endtime-28800;
   datetime starttime = endtime-3600;
   //datetime starttime = endtime-7200;
   endtime=endtime-1;

   double highs[], lows[], MaValues[];
   MqlRates current[];
   if(CopyHigh(_Symbol,_Period,starttime,endtime,highs)==-1)
      return;
   if(CopyLow(_Symbol,_Period,starttime,endtime,lows)==-1)
      return;
   if(CopyRates(_Symbol,_Period,0,1,current)==-1)
      return;
   //if(CopyBuffer(MaHandle,0,0,10,MaValues)<10)
      //return;

   double highrange=highs[ArrayMaximum(highs)];
   double lowrange=lows[ArrayMinimum(lows)];

   int margin=BOMargin;
   bool upbreakout=current[0].high-(_Point*margin)>highrange;
   bool downbreakout=current[0].low+(_Point*margin)<lowrange;

   //if(upbreakout)
   //{
   //   lastupday=dt.day;
   //   return;
   //}
   //if(downbreakout)
   //{
   //   lastdownday=dt.day;
   //   return;
   //}

   //if((upbreakout&&lastupday==dt.day) || (downbreakout&&lastdownday==dt.day))
   //   return;
   //if(downbreakout&&lastdownday==dt.day)
   //   return;
   if(lastupday==dt.day || lastdownday==dt.day)
      return;


   int hedgerange=300;
   if(upbreakout||downbreakout)
   {
      Tradesinfo.tplevel=1;
      Tradesinfo.hedgelevel=0;
   
      ENUM_ORDER_TYPE type=ORDER_TYPE_BUY;
      double price=0, sl=0, tp=0, volume=0, riskrange=0;
      double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      CTrade trade;
      trade.SetExpertMagicNumber(MagicNumber);

      if(upbreakout)
      {
         type = ORDER_TYPE_BUY;
         price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         Tradesinfo.initup=true;
         Tradesinfo.initprice=price;
         //Tradesinfo.hedgeprice=price-(hedgerange*_Point);
         Tradesinfo.hedgeprice=lowrange;
         sl = lowrange;
         riskrange=price-sl;
         //sl = price-calculateDistance(price, 200);
         //tp = price+calculateDistance(price, 15000);
         tp = price+((price-lowrange)*3);
         //tp = price+calculateDistance(price, 300);
      }
   
      if(downbreakout)
      {
         Print("Short Breakout");
         type = ORDER_TYPE_SELL;
         price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         Tradesinfo.initup=false;
         Tradesinfo.initprice=price;
         //Tradesinfo.hedgeprice=price+(hedgerange*_Point);
         Tradesinfo.hedgeprice=highrange;
         sl = highrange;
         riskrange=sl-price;
         //sl = price+calculateDistance(price, 200);
         //tp = price-calculateDistance(price, 15000);
         tp = price-((highrange-price)*3);
         //tp = price-calculateDistance(price, 300);
      }


      //double tickSize      = SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE);
      //double tickValue     = SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE);
      //double valueToRisk   = risk / 100 * capital;
      //double tickCount     = sldistance / tickSize;
      //double lots          = valueToRisk / (tickCount * tickValue);
      ////--
      //double tickValueSize = tickValue * _Point / tickSize;
      //double spread        = (double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
      //double stoploss      = valueToRisk  / (lots * tickValueSize) - spread;


      double TickValue=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE); //tick value deposit ccy
      double TickSize=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE);  //tick size in points
      double PointValue=TickValue/(TickSize/Point());                     //1 point in deposit ccy

      double riskpoints=MathAbs(NormalizeDouble(riskrange,Digits())/Point());
      double amounttorisk=(AccountInfoDouble(ACCOUNT_BALANCE)/100)*RiskPerTrade;
      volume=NormalizeDouble(amounttorisk/(riskpoints*PointValue),2);

//      Print(DoubleToString(PointValue));
//      Print(DoubleToString(riskpoints));
//      Print(DoubleToString(amounttorisk));
//      Print(DoubleToString(riskpoints*PointValue));
//      Print(DoubleToString(volume));
//
//      double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
//      double sl_value=tick_value*riskrange;
//      double amount_to_risk=(AccountInfoDouble(ACCOUNT_BALANCE)/100)*0.00003;
      //volume=NormalizeDouble(amount_to_risk/sl_value,2);
      //volume = 0.3;
      Tradesinfo.initvolume=volume;
      trade.PositionOpen(_Symbol, type, volume, price, NULL, tp);
      //trade.PositionOpen(_Symbol, type, volume, price, sl, tp);
      //trade.PositionOpen(_Symbol, type, volume, price, NULL, NULL);
      
      if(upbreakout)
         lastupday=dt.day;
      if(downbreakout)
         lastdownday=dt.day;
   }

   prevTime = curTime;
}


void OnTick() {

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

   //if ( PositionSelect(_Symbol) ) {
   if(IsTRadeOpen())
   {
      checkForClose();
   }
   else
   {
      checkForOpen();
   }
}
