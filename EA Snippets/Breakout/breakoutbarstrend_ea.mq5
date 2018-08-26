//+------------------------------------------------------------------+
//|                                         BreakoutBarsTrend_EA.mq5 |
//|                                            Copyright 2012, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "The Expert Advisor using the BreakoutBarsTrend_v2 indicator. Depending on the settings, the entry in market "
#property description "is performed in the trend reversal ore after missing the specified number of "
#property description "negative signals.\n"
#property description "Important! If the reversal is specified in percentage, then the Delta, SL and TP also should be specified in percentage."
#property description "If the reversal in pips - the Delta, SL and TP also are specified in pips."
//+------------------------------------------------------------------+
//| includes                                                         |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
//| enums                                                            |
//+------------------------------------------------------------------+
enum REVERSAL_MODE {
   PIPS,       // In pips
   PERCENT     // In percentage
};
//---
enum REVERSAL {
   TO_DOWN = -1,
   NO_CHANGE = 0,
   TO_UP = 1
};
//+------------------------------------------------------------------+
//| input parameters                                                 |
//+------------------------------------------------------------------+
input REVERSAL_MODE  InpReversal = PERCENT;  // Reversal
input double         InpDelta = 1.0;         // Delta
input int            InpNegatives = 1;       // Number of negative signals
input double         InpStopLoss = 1.0;      // Stop Loss
input double         InpTakeProfit = 4.0;    // Take Profit
input double         InpLot = 1.0;           // Lot
//+------------------------------------------------------------------+
//| global variables                                                 |
//+------------------------------------------------------------------+
double               delta;
double               stopLoss;
double               takeProfit;
int                  bbtHandle;
int                  negatives;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   if ( negatives < 0 ) {
      negatives = 0;
      printf("The \"InpNegatives\" parameter is specified incorrectly: %d. the: %d. value will be used",
         InpNegatives, negatives);
   } else {
      negatives = InpNegatives;
   }
//---
   checkParameter(InpDelta, delta);
   checkParameter(InpStopLoss, stopLoss);
   checkParameter(InpTakeProfit, takeProfit);
//---
   bbtHandle = iCustom(_Symbol, _Period, "Development\\Breakout\\BreakoutBarsTrend_v2", InpReversal, delta, false, false, 0);
   if ( bbtHandle == INVALID_HANDLE ) {
      Print("Failed to create the BreakoutBarsTrend_v2 indicator. Error code: ", GetLastError());
      return(-1);
   }  
//---
   return(0);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   IndicatorRelease(bbtHandle);
//---   
}
//+------------------------------------------------------------------+
//| Check parameter function                                         |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
//| Check volume value function                                      |
//+------------------------------------------------------------------+
double checkVolumeValue(double volume) {
//---
   double minVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
//---
   if ( volume < minVolume ) {
      volume = minVolume;
   } else if ( volume > maxVolume ) {
      volume = maxVolume;
   }
//---
   int digits = (int)MathCeil(MathLog10(1/volumeStep));
//---
   return(NormalizeDouble(volume, digits));
}
//+------------------------------------------------------------------+
//| Get current time function                                        |
//+------------------------------------------------------------------+
datetime getCurrentTime() {
//---
   datetime time[1];
   CopyTime(_Symbol, _Period, 0, 1, time);
//---
   return(time[0]);
}
//+------------------------------------------------------------------+
//| Calculate and normalize SL/TP distance function                  |
//+------------------------------------------------------------------+
double calculateDistance(double price, double distance) {
//---
   if ( InpReversal == PIPS ) {
      return(NormalizeDouble(distance*_Point, _Digits));
   }
   return(NormalizeDouble((price/100)*distance, _Digits));
//---
}
//+------------------------------------------------------------------+
//| Check if trend direction changed fucntion                        |
//+------------------------------------------------------------------+
int checkTrendChange() {
//---
   double values[3];
   
   ResetLastError();
   if ( CopyBuffer(bbtHandle, 0, 0, 3, values) != 3 ) {
      Print("Indicator data copy error. Error #", GetLastError());
      return(NO_CHANGE);
   }
//---
   if ( values[0] * values[1] < 0 ) {
      if ( values[1] > 0 ) {
         return(TO_UP);
      } else {
         return(TO_DOWN);
      }
   }
//---
   return(NO_CHANGE);
}
//+------------------------------------------------------------------+
//| Check for close condition function                               |
//+------------------------------------------------------------------+
void checkForClose() {
//---
   datetime curTime = getCurrentTime();
   static datetime prevTime;
//---
   if ( curTime == prevTime ) {
      return;
   }
//---
   long posType = PositionGetInteger(POSITION_TYPE);
   int reverse = checkTrendChange();
   if ( (posType == POSITION_TYPE_BUY && reverse == TO_DOWN) || 
      (posType == POSITION_TYPE_SELL && reverse == TO_UP) ) 
   {
      CTrade trade;
      
      ResetLastError();
      if ( !trade.PositionClose(_Symbol) ) {
         Print("Failed to close position. Error #", GetLastError());
         return;
      }
   }
//---
   prevTime = curTime;
//---
}
//+------------------------------------------------------------------+
//| Check if previous trends were negatives function                 |
//+------------------------------------------------------------------+
bool isNegativeSeries() {
//---
   int size = negatives * 100;
   double close[], bbtValues[];
   
   ResetLastError();
   if ( CopyClose(_Symbol, _Period, 0, size, close) != size ) {
      Print("Failed to copy a history data. Error #", GetLastError());
      return(false);
   }
   if ( CopyBuffer(bbtHandle, 0, 0, size, bbtValues) != size ) {
      Print("Indicator data copy error. Error #", GetLastError());
      return(false);
   }
//---
   double firstPrice, result;
   double lastPrice = close[size-2];
   bool up = (bbtValues[size-2] > 0) ? false : true;
   int counter = 0;
   
   for ( int bar = size - 3; bar > 0; bar-- ) {
      if ( bbtValues[bar] * bbtValues[bar-1] < 0 ) {
         firstPrice = close[bar];
         result = (up) ? (lastPrice - firstPrice) : (firstPrice - lastPrice);
         if ( result > 0.0 ) {
            return(false);
         }
         counter += 1;
         if ( counter >= negatives ) {
            return(true);
         }
         up = !up;
         lastPrice = firstPrice;
      }
   }
//---
   return(false);
}
//+------------------------------------------------------------------+
//| Check for open condition function                                |
//+------------------------------------------------------------------+
void checkForOpen() {
//---
   datetime curTime = getCurrentTime();
   static datetime prevTime;
   
   //MqlDateTime dt;
   //TimeToStruct(curTime,dt);
   //if(dt.day_of_week!=5)
   //   return;

   
//---
   if ( curTime == prevTime ) {
      return;
   }
//---
   int reverse = checkTrendChange();
   
   if ( reverse == NO_CHANGE ) {
      prevTime = curTime;
      return;
   }
//---
   if ( negatives == 0 || (negatives > 0 && isNegativeSeries()) ) {
      ENUM_ORDER_TYPE type;
      double price, sl, tp, volume;
      double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      CTrade trade;
      //---
      if ( reverse == TO_UP ) {
         type = ORDER_TYPE_BUY;
         price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         sl = MathMin(price-calculateDistance(price, stopLoss), SymbolInfoDouble(_Symbol, SYMBOL_BID)-stopLevel);
         tp = MathMax(price+calculateDistance(price, takeProfit), price+stopLevel);
      } else {
         type = ORDER_TYPE_SELL;
         price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         sl = MathMax(price+calculateDistance(price, stopLoss), SymbolInfoDouble(_Symbol, SYMBOL_ASK)+stopLevel);
         tp = MathMin(price-calculateDistance(price, takeProfit), price-stopLevel);
      }
      //---
      volume = checkVolumeValue(InpLot);
      if ( !trade.PositionOpen(_Symbol, type, volume, price, sl, tp) ) {
         Print("Failed to open the order. Error #", GetLastError());
         return;
      }
   }
//---
   prevTime = curTime;
//---
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   if ( PositionSelect(_Symbol) ) {
      checkForClose();
   } else {
      checkForOpen();
   }
//---
}
//+------------------------------------------------------------------+
