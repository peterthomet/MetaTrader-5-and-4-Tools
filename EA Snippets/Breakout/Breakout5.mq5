
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

input REVERSAL_MODE  InpReversal = PERCENT;  // Reversal
input double         InpDelta = 1.0;         // Delta
input int            InpNegatives = 1;       // Number of negative signals
input double         InpStopLoss = 1.0;      // Stop Loss
input double         InpTakeProfit = 4.0;    // Take Profit
input double         InpLot = 1.0;           // Lot
input int            BOMargin = 0;           // Breakout Margin
input double         TPFactor = 1;           // TP/SL Factor
input int            HedgeRange = 30;       // Hedge Range
input double         volumestart = 0.02;      // Volume Start
input double         volumefactor = 1.45;     // Volume Factor

double               delta;
double               stopLoss;
double               takeProfit;
//int                  bbtHandle;
//int                  MaHandle;
int                  negatives;
int lastupday;
int lastdownday;
double peakwin;

struct TypeTradesinfo
{
   double initprice;
   double hedgeprice;
   bool initup;
   double lastvolume;
};
TypeTradesinfo Tradesinfo;

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
   //bbtHandle = iCustom(_Symbol, _Period, "Development\\Breakout\\BreakoutBarsTrend_v2", InpReversal, delta, false, false, 0);
   //if ( bbtHandle == INVALID_HANDLE ) {
   //   Print("Failed to create the BreakoutBarsTrend_v2 indicator. Error code: ", GetLastError());
   //   return(-1);
   //}
   
   //MaHandle = iMA(NULL,0,50,0,MODE_SMA,PRICE_CLOSE);

   pivotsdata.Settings.PivotTypeHour=PIVOT_TRADITIONAL;
   pivotsdata.Settings.PivotTypeFourHour=NONE;
   pivotsdata.Settings.PivotTypeDay=NONE;
   pivotsdata.Settings.PivotTypeWeek=NONE;
   pivotsdata.Settings.PivotTypeMonth=NONE;
   pivotsdata.Settings.PivotTypeYear=NONE;
   
   return(0);
}


void OnDeinit(const int reason) {
   //IndicatorRelease(bbtHandle);
   //IndicatorRelease(MaHandle);
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
   static datetime prevTime;


   int postotal=PositionsTotal();
   double priceopen=PositionGetDouble(POSITION_PRICE_OPEN);
   double profits=GetProfits();

   //if(profits<=0)
   //   peakwin=0;
   //else
      peakwin=MathMax(peakwin,profits);


   //double p1=current[0].close+(_Point*5);
   //double p2=current[0].close-(_Point*5);
   //bool isatpivot=PivotsIsPivotRange(p1,p2,PD.PivotsDay,"R1")||PivotsIsPivotRange(p1,p2,PD.PivotsDay,"S1");
   //if(isatpivot&&profits>=0)
   //   CloseAll();


   //if(peakwin>=20&&profits<=(peakwin-20))
   //   CloseAll();

   //if(peakwin>=15&&profits<(peakwin*0.9))
   if(peakwin>=5&&profits<=(peakwin*0.7))
      CloseAll();

   //if(postotal==1&&peakwin>=45&&profits<(peakwin*0.7))
   //   CloseAll();
   //if(postotal==2&&peakwin>=20&&profits<(peakwin*0.7))
   //   CloseAll();
   //if(postotal==3&&peakwin>=15&&profits<(peakwin*0.7))
   //   CloseAll();

   //if(postotal==3 && profits>=0)
   //   CloseAll();

   //if(profits<=-100)
      //CloseAll();

   if ( curTime == prevTime ) {
      return;
   }


   MqlDateTime dt;
   TimeToStruct(curTime,dt);
   //if(dt.hour==22 && profits>=0)
   //   CloseAll();

   //if(dt.hour>=13 && profits>=0 && postotal==1)
   //   CloseAll();

   bool hedgedown, hedgeup;

   if(postotal>0)
   {
      //if(peakwin>=20)
      //{
      //   if(Tradesinfo.initup)
      //      Tradesinfo.hedgeprice=Tradesinfo.initprice-(HedgeRange*_Point)+((peakwin*10)*_Point);
      //   if(!Tradesinfo.initup)
      //      Tradesinfo.hedgeprice=Tradesinfo.initprice+(HedgeRange*_Point)-((peakwin*10)*_Point);
      //}
   
      hedgeup=Tradesinfo.initup&&current[0].close<=Tradesinfo.hedgeprice;
      hedgedown=!Tradesinfo.initup&&current[0].close>=Tradesinfo.hedgeprice;
      //if(profits<=-30)
      if(hedgeup||hedgedown)
      {
         //if(profits>=0)
         //{
         //   CloseAll();
         //   return;
         //}
      
         peakwin=0;
      
         ENUM_ORDER_TYPE type=ORDER_TYPE_BUY;
         double price=0, volume=0;
         CTrade trade;
      
         if(hedgedown)
         {
            type=ORDER_TYPE_SELL;
            price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            Tradesinfo.hedgeprice=price+(HedgeRange*_Point);
         }
         if(hedgeup)
         {
            type=ORDER_TYPE_BUY;
            price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            Tradesinfo.hedgeprice=SymbolInfoDouble(_Symbol, SYMBOL_BID)-(HedgeRange*_Point);
         }
         volume = MathRound((Tradesinfo.lastvolume*100)*volumefactor)/100;
         Tradesinfo.lastvolume=volume;
         trade.PositionOpen(_Symbol, type, volume, price, NULL, NULL);
      }
   }

   prevTime = curTime;

   return;


   double highs[], lows[], MaValues[];
   if(CopyHigh(_Symbol,_Period,1,3,highs)==-1)
      return;
   if(CopyLow(_Symbol,_Period,1,3,lows)==-1)
      return;
   //if(CopyBuffer(MaHandle,0,0,10,MaValues)<10)
   //   return;

   double highrange=highs[ArrayMaximum(highs)];
   double lowrange=lows[ArrayMinimum(lows)];


   double sl = PositionGetDouble(POSITION_SL);

   //lowrange=MaValues[1];
   //highrange=MaValues[1];

   //double profit=PositionGetDouble(POSITION_PROFIT);
   //if(profit>=10)
   //   sl=PositionGetDouble(POSITION_PRICE_OPEN);

   //CTrade trade;
   //if(posType==POSITION_TYPE_BUY)
   //{
   //   sl = MathMax(sl,lowrange);
   //   trade.PositionModify(_Symbol,sl,PositionGetDouble(POSITION_TP));
   //}
   //if(posType==POSITION_TYPE_SELL)
   //{
   //   sl = MathMin(sl,highrange);
   //   trade.PositionModify(_Symbol,sl,PositionGetDouble(POSITION_TP));
   //}
   
   //if(posType==POSITION_TYPE_SELL)
   //{
   //   CTrade trade;
   //   ResetLastError();
   //   if ( !trade.PositionClose(_Symbol) ) {
   //      Print("Failed to close position. Error #", GetLastError());
   //      return;
   //   }
   //}
}


void checkForOpen() {
   datetime curTime = getCurrentTime();
   static datetime prevTime;
   
   if ( curTime == prevTime ) {
      return;
   }

   MqlDateTime dt;
   TimeToStruct(curTime,dt);
   if(dt.min!=0)
      return;

   dt.hour=8;
   dt.min=0;
   dt.sec=0;
   datetime endtime = StructToTime(dt);
   datetime starttime = endtime-28800;
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
   bool upbreakout=current[0].close>highrange-((highrange-lowrange)/2);
   bool downbreakout=current[0].close<lowrange+((highrange-lowrange)/2);
   //bool upbreakout=current[0].high-(_Point*margin)>highrange;
   //bool downbreakout=current[0].low+(_Point*margin)<lowrange;


   bool abovepivot=PivotsIsAbovePivot(current[0].close,pivotsdata.PivotsHour,"P");
   upbreakout=!abovepivot;
   downbreakout=!upbreakout;


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
   
   //if(lastupday==dt.day || lastdownday==dt.day)
   //   return;


   int hedgerange=HedgeRange;
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
         Tradesinfo.initup=true;
         Tradesinfo.initprice=price;
         Tradesinfo.hedgeprice=SymbolInfoDouble(_Symbol, SYMBOL_BID)-(hedgerange*_Point);
         sl = lowrange;
         //sl = price-calculateDistance(price, 200);
         //tp = price+calculateDistance(price, 15000);
         //tp = price+((price-lowrange)*TPFactor);
         tp = price+calculateDistance(price, 50);
      }
   
      if(downbreakout)
      {
         type = ORDER_TYPE_SELL;
         price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         Tradesinfo.initup=false;
         Tradesinfo.initprice=price;
         Tradesinfo.hedgeprice=price+(hedgerange*_Point);
         sl = highrange;
         //sl = price+calculateDistance(price, 200);
         //tp = price-calculateDistance(price, 15000);
         //tp = price-((highrange-price)*TPFactor);
         tp = price-calculateDistance(price, 50);
      }

      volume = volumestart;
      Tradesinfo.lastvolume=volume;
      if ( !trade.PositionOpen(_Symbol, type, volume, price, NULL, NULL) )
      {
         Print("Failed to open the order. Error #", GetLastError());
         return;
      }
      if(upbreakout)
         lastupday=dt.day;
      if(downbreakout)
         lastdownday=dt.day;
         
      peakwin=0;
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
