
//| ---------------------------------------
//| CurrencyStrength1.mq5
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

input REVERSAL_MODE  InpReversal = PERCENT;  // Reversal
input double         InpDelta = 1.0;         // Delta
input int            InpNegatives = 1;       // Number of negative signals
input double         InpStopLoss = 100;      // Stop Loss
input double         InpTakeProfit = 100;    // Take Profit
input double         InpPivotOverShot = 100; // Pivot Overshot
input double         InpLot = 1.0;           // Lot
input int            BOMargin = 0;           // Breakout Margin
input double         TPFactor = 1;           // TP/SL Factor
input int            S1 = 1;                 // Indicator Signal Index 1
//input int            S2 = 1;                 // Indicator Signal Index 2
input int            houropen = 0;                 // Hour to open Trades

double               delta;
double               stopLoss;
double               takeProfit;
//int                  bbtHandle;
//int                  MaHandle;
int                  CSHandle;
//int                  CSHandle2;
int                  negatives;
int lastupday;
int lastdownday;
double lastpivotset;
TypePivotsData pivotsdata;


int OnInit() {
   if ( negatives < 0 ) {
      negatives = 0;
      printf("The \"InpNegatives\" parameter is specified incorrectly: %d. the: %d. value will be used",
         InpNegatives, negatives);
   } else {
      negatives = InpNegatives;
   }
   checkParameter(InpDelta, delta);
   checkParameter(InpStopLoss, stopLoss);
   checkParameter(InpTakeProfit, takeProfit);

   CSHandle = iCustom(_Symbol, _Period, "Development\\Currency Index\\CurrencyStrength",0,9,0);
   if ( CSHandle == INVALID_HANDLE ) {
      Print("Failed to create the CurrencyStrength indicator. Error code: ", GetLastError());
      return(-1);
   }
   
   //CSHandle2 = iCustom(_Symbol, PERIOD_D1, "Development\\Currency Index\\CurrencyStrength",0,9,0);
   //if ( CSHandle2 == INVALID_HANDLE ) {
   //   Print("Failed to create the CurrencyStrength indicator. Error code: ", GetLastError());
   //   return(-1);
   //}
   
   //MaHandle = iMA(NULL,0,50,0,MODE_SMA,PRICE_CLOSE);

   pivotsdata.Settings.PivotTypeHour=NONE;
   pivotsdata.Settings.PivotTypeFourHour=NONE;
   pivotsdata.Settings.PivotTypeDay=PIVOT_TRADITIONAL;
   pivotsdata.Settings.PivotTypeWeek=NONE;
   pivotsdata.Settings.PivotTypeMonth=NONE;
   pivotsdata.Settings.PivotTypeYear=NONE;
   
   return(0);
}


void OnDeinit(const int reason) {
   //IndicatorRelease(bbtHandle);
   //IndicatorRelease(MaHandle);
   IndicatorRelease(CSHandle);
   //IndicatorRelease(CSHandle2);
}


void checkParameter(double inpValue, double &parameter) {
   if ( inpValue < 0.0 ) {
      if ( InpReversal == PIPS ) {
         parameter = 1000;
      } else {
         parameter = 1.0;
      }
      printf("The parameter is specified incorrectly: %f. the: %f. value will be used",
         inpValue, parameter);
   } else {
      parameter = inpValue;
   }
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


void checkForClose() {
   //return;
   //double profit=PositionGetDouble(POSITION_PROFIT);
   //if(profit>=10)
   //{
   //   CTrade trade;
   //   trade.PositionClose(_Symbol);
   //}
   //return;
   
   datetime curTime = getCurrentTime();
   static datetime prevTime;
   if ( curTime == prevTime ) {
      return;
   }

   //MqlDateTime dt;
   //TimeToStruct(curTime,dt);
   //if(dt.hour>19)
   //{
   //   CTrade trade;
   //   int ord_total=OrdersTotal();
   //   if(ord_total > 0)
   //   {
   //      for(int i=ord_total-1;i>=0;i--)
   //      {
   //         ulong ticket=OrderGetTicket(i);
   //         if(OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL)==Symbol())
   //            trade.OrderDelete(ticket);
   //      }
   //   }
   //}

   //prevTime = curTime;
   //return;



   double highs[], lows[], MaValues[];
   if(CopyHigh(_Symbol,_Period,1,3,highs)==-1)
      return;
   if(CopyLow(_Symbol,_Period,1,3,lows)==-1)
      return;
   //if(CopyBuffer(MaHandle,0,0,10,MaValues)<10)
   //   return;

   double highrange=highs[ArrayMaximum(highs)];
   double lowrange=lows[ArrayMinimum(lows)];

   long posType = PositionGetInteger(POSITION_TYPE);

   double sl = PositionGetDouble(POSITION_SL);

   double profit = PositionGetDouble(POSITION_PROFIT);

   //lowrange=MaValues[1];
   //highrange=MaValues[1];

   //double profit=PositionGetDouble(POSITION_PROFIT);
   //if(profit>=10)
   //   sl=PositionGetDouble(POSITION_PRICE_OPEN);

   CTrade trade;
   if(posType==POSITION_TYPE_BUY)
   {
      sl = MathMax(sl,lowrange);
      trade.PositionModify(_Symbol,sl,PositionGetDouble(POSITION_TP));
   }
   if(posType==POSITION_TYPE_SELL)
   {
      sl = MathMin(sl,highrange);
      trade.PositionModify(_Symbol,sl,PositionGetDouble(POSITION_TP));
   }
   
   //if(posType==POSITION_TYPE_SELL)
   //{
   //   CTrade trade;
   //   ResetLastError();
   //   if ( !trade.PositionClose(_Symbol) ) {
   //      Print("Failed to close position. Error #", GetLastError());
   //      return;
   //   }
   //}
   prevTime = curTime;
}


void checkForOpen() {

   MqlDateTime dt;
   datetime curTime = getCurrentTime();
   static datetime prevTime;
   
   //if ( curTime == prevTime ) {
   //   return;
   //}

   TimeToStruct(curTime,dt);
   //if(dt.hour!=12)
   //if(dt.hour!=18&&dt.hour!=12&&dt.hour!=14)
   //if(dt.hour!=houropen)
   //if(dt.hour!=14&&dt.hour!=15&&dt.hour!=16)
      //return;

   
   //if(false){
   double CSValues[20], CSValues2[20];
   if(CopyBuffer(CSHandle,52,0,20,CSValues)<20)
   {
      Print("CopyBuffer<20");
      return;
   }
   //if(CopyBuffer(CSHandle2,52,0,20,CSValues2)<20)
   //{
   //   Print("CopyBuffer<20");
   //   return;
   //}

   int s1=20-S1;
   //int s2=20-S2;
   //if(CSValues[s1]!=0&&CSValues[s2]==CSValues[s1])
   //if(CSValues[s1]!=0&&CSValues2[s2]==CSValues[s1])
   s1=19;
   //if(CSValues[s1]!=0&&CSValues[2]==CSValues[s1]&&CSValues[3]==CSValues[s1])
   //if(CSValues[s1]!=0&&CSValues[2]==CSValues[s1])
   //if(CSValues[s1]!=0)
   //if(CSValues[s1]!=0&&CSValues2[s1]!=0&&CSValues2[s1]!=CSValues[s1])
   //if(CSValues[s1]!=0&&CSValues2[s1]==CSValues[s1])
   //if(CSValues[s1]!=0&&CSValues[18]==CSValues[s1])
   if(CSValues[s1]!=0)
   {
      ENUM_ORDER_TYPE type=ORDER_TYPE_BUY;
      double price=0, sl=0, tp=0, volume=0;
      double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      CTrade trade;

      if(CSValues[s1]==1)
      {
         type = ORDER_TYPE_BUY;
         price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         sl = price-calculateDistance(price, InpStopLoss);
         tp = price+calculateDistance(price, InpTakeProfit);
      }

      if(CSValues[s1]==-1)
      {
         type = ORDER_TYPE_SELL;
         price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         sl = price+calculateDistance(price, InpStopLoss);
         tp = price-calculateDistance(price, InpTakeProfit);
      }

      volume = 1;
      if ( !trade.PositionOpen(_Symbol, type, volume, price, sl, tp) )
      {
         Print("Failed to open the order. Error #", GetLastError());
         return;
      }
   
   }
   //}





   prevTime = curTime;
   return;


   if(lastpivotset==pivotsdata.PivotsDay.P)
      return;

   ENUM_ORDER_TYPE type=ORDER_TYPE_SELL_LIMIT;
   double price=0, sl=0, tp=0, volume=0.1;
   CTrade trade;
   
   sl=pivotsdata.PivotsDay.R1+(Point()*InpPivotOverShot)+(Point()*InpStopLoss);
   tp=pivotsdata.PivotsDay.R1+(Point()*InpPivotOverShot)-(Point()*InpTakeProfit);
   trade.SellLimit(volume,pivotsdata.PivotsDay.R1+(Point()*InpPivotOverShot),NULL,sl,tp);


   lastpivotset=pivotsdata.PivotsDay.P;
   Print(lastpivotset);
   prevTime = curTime;
   return;


   TimeToStruct(curTime,dt);
   if(dt.hour<9||dt.hour>9)
      return;

   dt.hour=5;
   dt.min=0;
   dt.sec=0;
   datetime starttime = StructToTime(dt);
   datetime endtime = starttime+14399;

   double highs[], lows[], MaValues[];
   MqlRates current[];
   if(CopyHigh(_Symbol,_Period,starttime,endtime,highs)==-1)
      return;
   if(CopyLow(_Symbol,_Period,starttime,endtime,lows)==-1)
      return;
   if(CopyRates(_Symbol,_Period,0,1,current)==-1)
      return;
   //if(CopyBuffer(MaHandle,0,0,10,MaValues)<10)
   //   return;

   double highrange=highs[ArrayMaximum(highs)];
   double lowrange=lows[ArrayMinimum(lows)];

   int margin=BOMargin;
   bool upbreakout=current[0].high-(_Point*margin)>highrange;
   bool downbreakout=current[0].low+(_Point*margin)<lowrange;


   bool abovepivot=PivotsIsAbovePivot(current[0].close,pivotsdata.PivotsDay,"P");
   if(upbreakout&&!PivotsIsAbovePivot(current[0].close,pivotsdata.PivotsDay,"P"))
      return;
   if(downbreakout&&PivotsIsAbovePivot(current[0].close,pivotsdata.PivotsDay,"P"))
      return;

   //if((upbreakout&&lastupday==dt.day) || (downbreakout&&lastdownday==dt.day))
   //   return;
   //if(downbreakout&&lastdownday==dt.day)
   //   return;
   if(lastupday==dt.day || lastdownday==dt.day)
      return;

   if(upbreakout||downbreakout)
   {
      ENUM_ORDER_TYPE type=ORDER_TYPE_BUY;
      double price=0, sl=0, tp=0, volume=0;
      double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      CTrade trade;

      if(upbreakout)
      {
         type = ORDER_TYPE_BUY;
         price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         sl = lowrange;
         //sl = price-calculateDistance(price, 200);
         //tp = price+calculateDistance(price, 15000);
         tp = price+((price-lowrange)*TPFactor);
         //tp = price+calculateDistance(price, 300);
      }
   
      if(downbreakout)
      {
         Print("Short Breakout");
         type = ORDER_TYPE_SELL;
         price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         sl = highrange;
         //sl = price+calculateDistance(price, 200);
         //tp = price-calculateDistance(price, 15000);
         tp = price-((highrange-price)*TPFactor);
         //tp = price-calculateDistance(price, 300);
      }

      volume = 0.1;
      if ( !trade.PositionOpen(_Symbol, type, volume, price, sl, tp) )
      {
         Print("Failed to open the order. Error #", GetLastError());
         return;
      }
      if(upbreakout)
         lastupday=dt.day;
      if(downbreakout)
         lastdownday=dt.day;
   }
   else
      return;

   //int reverse = checkTrendChange();
   //if ( reverse == NO_CHANGE ) {
   //   prevTime = curTime;
   //   return;
   //}
   //if ( negatives == 0 || (negatives > 0 && isNegativeSeries()) ) {
   //   ENUM_ORDER_TYPE type;
   //   double price, sl, tp, volume;
   //   double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   //   CTrade trade;
   //   if ( reverse == TO_UP ) {
   //      type = ORDER_TYPE_BUY;
   //      price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   //      sl = MathMin(price-calculateDistance(price, stopLoss), SymbolInfoDouble(_Symbol, SYMBOL_BID)-stopLevel);
   //      tp = MathMax(price+calculateDistance(price, takeProfit), price+stopLevel);
   //   } else {
   //      type = ORDER_TYPE_SELL;
   //      price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   //      sl = MathMax(price+calculateDistance(price, stopLoss), SymbolInfoDouble(_Symbol, SYMBOL_ASK)+stopLevel);
   //      tp = MathMin(price-calculateDistance(price, takeProfit), price-stopLevel);
   //   }
   //   volume = checkVolumeValue(InpLot);
   //   if ( !trade.PositionOpen(_Symbol, type, volume, price, sl, tp) ) {
   //      Print("Failed to open the order. Error #", GetLastError());
   //      return;
   //   }
   //}
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
      pivotsdata.Calculate(New_Time[0]);
   }

   if ( PositionSelect(_Symbol) ) {
      checkForClose();
   } else {
      checkForOpen();
   }
}
