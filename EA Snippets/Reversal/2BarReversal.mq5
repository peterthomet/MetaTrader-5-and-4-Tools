
//| ---------------------------------------
//| 2BarReversal.mq5
//| Copyright 2018, getYourNet.ch
//| ---------------------------------------

#property version   "1.00"

//#include <MultiPivots.mqh>
#include <Trade\Trade.mqh>

input int            MagicNumber = 5555;     // Magic Number
input int            BOMargin = 10;          // Breakout Margin
input int            MinAccumulationSize = 0; // Accumulation Min Size
input int            RangeMinSize = 0;       // Range Min Size
input int            RangeMaxSize = 0;     // Range Max Size
input int            OpenHour = 9;           // Open Hour
input double         RiskPerTrade = 2;       // Risk per Trade
input int            HedgeCycles = 1;        // Hedge Cycles
input double         VolumeMultiply = 2;     // Volume Multiply
input double         TPRangeSize = 95;      // Take Profit Range Size %
input bool           PinBarOppositeBody = false;     // Pin Bar Opposite Body
input bool           ReverseEntry = false;     // Reverse Entry
input double         MaxSpreadRiskPercent = 5;      // Max Spread to Risk %
input bool           TradeEURUSD = false;     // EURUSD
input bool           TradeGBPJPY = true;     // GBPJPY
input bool           TradeGBPUSD = false;     // GBPUSD
input bool           TradeGBPCAD = false;    // GBPCAD
input bool           TradeGBPNZD = false;    // GBPNZD
input bool           TradeGBPAUD = false;    // GBPAUD
input bool           TradeGBPCHF = false;    // GBPCHF

struct TypeTradeInfo
{
   double initprice;
   double hedgeprice;
   bool initup;
   int tplevel;
   double initvolume;
   int hedgelevel;
   long lasttradecandletime;
};

struct TypePairInfo
{
   string symbol;
   TypeTradeInfo TradeInfo;
   int dayinuse;
   double point;
   int breakoutmargin;
   bool tradeit;
};

TypePairInfo PairInfo[];

string pairs[]={"EURUSD","GBPJPY","GBPUSD","GBPCAD","GBPNZD","GBPAUD","GBPCHF"};
//string pairs[]={"EURUSD","GBPJPY","GBPUSD","GBPCAD","GBPNZD"};
//string pairs[]={"EURUSD","GBPJPY","GBPUSD"};
//string pairs[]={"GBPJPY","GBPUSD"};
//string pairs[]={"EURUSD"};
//string pairs[]={"GBPJPY"};
//string pairs[]={"GBPUSD"};

int pairscount;

string appnamespace="London Open EA";


int OnInit()
{
   string ExtraChars=StringSubstr(_Symbol, 6);

   datetime curTime = TimeTradeServer();
   MqlDateTime dt;
   TimeToStruct(curTime,dt);

   pairscount=ArraySize(pairs);
   ArrayResize(PairInfo,pairscount);
   for(int i=0; i<pairscount; i++)
   {
      PairInfo[i].symbol=pairs[i]+ExtraChars;
      if(dt.hour>=OpenHour)
         PairInfo[i].dayinuse=dt.day;
      PairInfo[i].point=SymbolInfoDouble(PairInfo[i].symbol,SYMBOL_POINT);
      PairInfo[i].breakoutmargin=BOMargin;

      if(pairs[i]=="EURUSD")
      {
         //PairInfo[i].breakoutmargin=95;
         //PairInfo[i].breakoutmargin=45;
         PairInfo[i].tradeit=TradeEURUSD;
      }
      if(pairs[i]=="GBPJPY")
      {
         //PairInfo[i].breakoutmargin=15;
         //PairInfo[i].breakoutmargin=35;
         PairInfo[i].tradeit=TradeGBPJPY;
      }
      if(pairs[i]=="GBPUSD")
      {
         //PairInfo[i].breakoutmargin=40;
         //PairInfo[i].breakoutmargin=55;
         PairInfo[i].tradeit=TradeGBPUSD;
      }
      if(pairs[i]=="GBPCAD")
      {
         PairInfo[i].tradeit=TradeGBPCAD;
      }
      if(pairs[i]=="GBPNZD")
      {
         PairInfo[i].tradeit=TradeGBPNZD;
      }
      if(pairs[i]=="GBPAUD")
      {
         PairInfo[i].tradeit=TradeGBPAUD;
      }
      if(pairs[i]=="GBPCHF")
      {
         PairInfo[i].tradeit=TradeGBPCHF;
      }
   }

   return(0);
}


void OnDeinit(const int reason)
{
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
      //if(poscomment==(appnamespace+" "+pi.symbol))
      if(posmagic==MagicNumber&&symbol==pi.symbol)
      {
         _IsTradeOpen=true;
         i=0;
      }
      i--;
   }
   return _IsTradeOpen;
}


void CheckForClose(TypePairInfo& pi)
{
}


void CheckForOpen(TypePairInfo& pi)
{
   datetime curTime=GetCurrentCandleTime(pi);
   static datetime prevTime;

   if(pi.TradeInfo.lasttradecandletime==curTime)
      return;

   
   //if ( curTime == prevTime ) {
   //   return;
   //}

   MqlDateTime dt;
   TimeToStruct(curTime,dt);

   //if(!(dt.min>=45&&dt.min<59))
   //   return;

   //if(dt.hour!=17&&dt.hour!=18&&dt.hour!=19)
      //return;


   //if(dt.hour<OpenHour||dt.hour>(OpenHour+2)||pi.dayinuse==dt.day)
   //   return;

   //if(dt.day_of_week!=2&&dt.day_of_week!=1)
   //if(dt.day_of_week!=2)
   //   return;

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
   if(CopyHigh(pi.symbol,_Period,0,7,highs)==-1)
      return;
   if(CopyLow(pi.symbol,_Period,0,7,lows)==-1)
      return;
   if(CopyRates(pi.symbol,_Period,0,7,current)==-1)
      return;
   //if(CopyBuffer(MaHandle,0,0,10,MaValues)<10)
      //return;

   int highest=ArrayMaximum(highs);
   int lowest=ArrayMinimum(lows);

   int margin=pi.breakoutmargin;
   double highrange=highs[ArrayMaximum(highs)]+(pi.point*margin);
   double lowrange=lows[ArrayMinimum(lows)]-(pi.point*margin);
   //double highrange=highs[ArrayMaximum(highs)];
   //double lowrange=lows[ArrayMinimum(lows)];


   //bool upbreakout=current[0].close>=highrange+(pi.point*margin);
   //bool downbreakout=current[0].close<=lowrange-(pi.point*margin);
   //bool upbreakout=current[0].close>=highrange;
   //bool downbreakout=current[0].close<=lowrange;


   bool upbreakout=false;
   bool downbreakout=false;


   double rangepoints=0;
   double accumulationpoints=0;
   if(highest==5)
   {
      if(PinBarOppositeBody)
         downbreakout=current[4].open<current[4].close&&current[5].open>current[5].close&&current[5].low>current[4].low&&current[6].low<current[4].low;
      else
         downbreakout=current[4].open<current[4].close&&current[5].low>current[4].low&&current[6].low<current[4].low;
      
      rangepoints=(current[5].open-current[4].low)/pi.point;
      accumulationpoints=(current[4].high-current[0].low)/pi.point;
   }

   if(lowest==5)
   {
      if(PinBarOppositeBody)
         upbreakout=current[4].open>current[4].close&&current[5].open<current[5].close&&current[5].high<current[4].high&&current[6].high>current[4].high;
      else
         upbreakout=current[4].open>current[4].close&&current[5].high<current[4].high&&current[6].high>current[4].high;
      
      rangepoints=(current[4].low-current[5].open)/pi.point;
      accumulationpoints=(current[0].high-current[4].low)/pi.point;
   }
   //if(downbreakout)
   //   return;

   if(RangeMinSize>0&&rangepoints<RangeMinSize)
      return;
   if(RangeMaxSize>0&&rangepoints>RangeMaxSize)
      return;

   if(MinAccumulationSize>0&&accumulationpoints<MinAccumulationSize)
      return;




   //if(upbreakout)
   //   return;

   //int hedgerange=300;
   if(upbreakout||downbreakout)
   {
      pi.TradeInfo.tplevel=1;
      pi.TradeInfo.hedgelevel=0;
      
      pi.TradeInfo.lasttradecandletime=curTime;
   
      ENUM_ORDER_TYPE type=ORDER_TYPE_BUY;
      double price=0, priceask=0, pricebid=0, sl=0, tp=0, volume=0, riskrange=0;
      double stopLevel = SymbolInfoInteger(pi.symbol, SYMBOL_TRADE_STOPS_LEVEL) * pi.point;
      CTrade trade;
      trade.SetExpertMagicNumber(MagicNumber);

      if(upbreakout)
      {
         type = ORDER_TYPE_BUY;
         pricebid = SymbolInfoDouble(pi.symbol, SYMBOL_BID);
         priceask = SymbolInfoDouble(pi.symbol, SYMBOL_ASK);
         price=priceask;
         pi.TradeInfo.initup=true;
         //pi.TradeInfo.initprice=price;
         pi.TradeInfo.initprice=highrange;
         //pi.TradeInfo.hedgeprice=price-(hedgerange*pi.point);
         pi.TradeInfo.hedgeprice=lowrange;
         sl = MathMin(current[5].open,current[5].close);
         riskrange=price-sl;
         //sl = price-calculateDistance(price, 200);
         //tp = price+calculateDistance(price, 15000);
         //tp = price+((price-lowrange)*3);
         tp = current[4].high+((current[4].high-current[5].open)*1);
         //tp = current[4].high+(50*pi.point);
         //tp = price+calculateDistance(price, 300);
      }
   
      if(downbreakout)
      {
         type = ORDER_TYPE_SELL;
         pricebid = SymbolInfoDouble(pi.symbol, SYMBOL_BID);
         priceask = SymbolInfoDouble(pi.symbol, SYMBOL_ASK);
         price=pricebid;
         pi.TradeInfo.initup=false;
         //pi.TradeInfo.initprice=price;
         pi.TradeInfo.initprice=lowrange;
         //pi.TradeInfo.hedgeprice=price+(hedgerange*pi.point);
         pi.TradeInfo.hedgeprice=highrange;
         sl = MathMax(current[5].open,current[5].close);
         riskrange=sl-price;
         //sl = price+calculateDistance(price, 200);
         //tp = price-calculateDistance(price, 15000);
         //tp = price-((highrange-price)*3);
         tp = current[4].low-((current[5].open-current[4].low)*1);
         //tp = current[4].low-(50*pi.point);
         //tp = price-calculateDistance(price, 300);
      }


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
      double TickSize=SymbolInfoDouble(pi.symbol,SYMBOL_TRADE_TICK_SIZE);  //tick size in points
      double PointValue=TickValue/(TickSize/pi.point);                     //1 point in deposit ccy

      double riskpoints=MathAbs(NormalizeDouble(riskrange,(int)SymbolInfoInteger(pi.symbol,SYMBOL_DIGITS))/pi.point);
      double amounttorisk=(AccountInfoDouble(ACCOUNT_BALANCE)/100)*RiskPerTrade;
      //volume=NormalizeDouble(amounttorisk/(riskpoints*PointValue),2);
      volume=NormalizeDouble(amounttorisk/(riskpoints*PointValue),2);


      double spreadpoints=MathAbs(NormalizeDouble(priceask-pricebid,(int)SymbolInfoInteger(pi.symbol,SYMBOL_DIGITS))/pi.point);

      if(spreadpoints>0)
      {
         if((spreadpoints/(riskpoints/100))>MaxSpreadRiskPercent)
            return;
      }


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

      if(ReverseEntry)
      {
         if(type==ORDER_TYPE_SELL)
         {
            type=ORDER_TYPE_BUY;
            price=priceask;
         }
         else
         {
            type=ORDER_TYPE_SELL;
            price=pricebid;
         }
         double tempsl=sl;
         sl=tp;
         tp=tempsl;
      }


      trade.PositionOpen(pi.symbol, type, volume, price, sl, tp, appnamespace+" "+pi.symbol);
      //trade.PositionOpen(pi.symbol, type, volume, price, sl, tp);
      //trade.PositionOpen(pi.symbol, type, volume, price, NULL, NULL);
      
   }

   prevTime = curTime;
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
}
