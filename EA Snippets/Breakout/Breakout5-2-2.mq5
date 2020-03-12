
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

input bool           StartAtFullHourOnly = true;   // Start at Full Hour only
input bool           ReverseEntry = false;   // Reverse Entry
input int            StepRange = 30;       // Step Range
input double         volumestart = 0.02;      // Volume Start
input double         volumestartbyequitypercent = 0;      // Volume Start by Equity Percent
input double         volumefactor = 1.45;     // Volume Factor
input double         takeprofitamountperstartvolume = 250;     // Take Profit Amount per Start Volume
input int            hedgeatlevel = 0;     // Hedge at Level
input double         hedgevolumefactor = 1.5;     // Hedge Volume Factor
input bool           continueafterhedge = false;     // Continue after Hedge
input double         commissonperlot = 0;     // Commission per Lot

double               delta;
double               stopLoss;
double               takeProfit;
//int                  bbtHandle;
//int                  MaHandle;
int                  negatives;
int lastupday;
int lastdownday;
double peakwin;
long magicnumber;

struct TypeTradesinfo
{
   double initprice;
   double stepprice;
   double lastaddprice;
   double zonepricelower;
   double zonepriceupper;
   int zonesequence;
   bool initup;
   double lastvolume;
   double totalvolume;
};
TypeTradesinfo Tradesinfo;

TypePivotsData pivotsdata;


int OnInit() {

   //bbtHandle = iCustom(_Symbol, _Period, "Development\\Breakout\\BreakoutBarsTrend_v2", InpReversal, delta, false, false, 0);
   //if ( bbtHandle == INVALID_HANDLE ) {
   //   Print("Failed to create the BreakoutBarsTrend_v2 indicator. Error code: ", GetLastError());
   //   return(-1);
   //}
   
   //MaHandle = iMA(NULL,0,50,0,MODE_SMA,PRICE_CLOSE);
   
   magicnumber=(long)TimeCurrent();

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
      long posmagic=PositionGetInteger(POSITION_MAGIC);
      if(posmagic==magicnumber)
      {
         profits+=PositionGetDouble(POSITION_PROFIT);
         if(commissonperlot>0)
            profits-=(PositionGetDouble(POSITION_VOLUME)*commissonperlot);
      }
      i--;
   }
   return profits;
}


double GetStartVolume()
{
   double startvolume=volumestart;
   if(volumestartbyequitypercent>0)
   {
      //startvolume=(volumestartbyequitypercent/1000)*(100000/AccountInfoDouble(ACCOUNT_EQUITY));
      startvolume=((AccountInfoDouble(ACCOUNT_EQUITY)/100)*volumestartbyequitypercent)/1000;
   }
   return NormalizeDouble(startvolume,2);
}


bool IsTRadeOpen()
{
   bool _IsTradeOpen=false;
   int i=PositionsTotal()-1;
   while(i>=0)
   {
      PositionGetSymbol(i);
      long posmagic=PositionGetInteger(POSITION_MAGIC);
      if(posmagic==magicnumber)
         _IsTradeOpen=true;
      i--;
   }
   return _IsTradeOpen;
}


int PosTotal()
{
   int _PosTotal=0;
   int i=PositionsTotal()-1;
   while(i>=0)
   {
      PositionGetSymbol(i);
      long posmagic=PositionGetInteger(POSITION_MAGIC);
      if(posmagic==magicnumber)
         _PosTotal++;
      i--;
   }
   return _PosTotal;
}


void CloseAll(bool all=true)
{
   CTrade trade;
   trade.SetExpertMagicNumber(magicnumber);
   int i=PositionsTotal()-1;
   while(i>=0)
   {
      PositionGetSymbol(i);
      long posmagic=PositionGetInteger(POSITION_MAGIC);
      if(posmagic==magicnumber||all)
      {
         trade.PositionClose(PositionGetSymbol(i));
      }
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
   MqlDateTime dt;
   TimeToStruct(curTime,dt);


   int postotal=PosTotal();
   double priceopen=PositionGetDouble(POSITION_PRICE_OPEN);
   double profits=GetProfits();

   //if(profits<=0)
   //   peakwin=0;
   //else
      peakwin=MathMax(peakwin,profits);


   //if(dt.min>=55 && profits>=0)
   //if(postotal>4 && profits>=0)
   //   CloseAll();


   //double p1=current[0].close+(_Point*5);
   //double p2=current[0].close-(_Point*5);
   //bool isatpivot=PivotsIsPivotRange(p1,p2,PD.PivotsDay,"R1")||PivotsIsPivotRange(p1,p2,PD.PivotsDay,"S1");
   //if(isatpivot&&profits>=0)
   //   CloseAll();



   double expectation=takeprofitamountperstartvolume*GetStartVolume();
   //if(postotal>5)
   //   expectation=0.01;

   //if(postotal>8)
   //   expectation=-10;

   //expectation=7-(postotal*2);

      
   //if(profits>=expectation)
   //   CloseAll();


   if(peakwin>=expectation&&profits<=(peakwin*0.7))
      CloseAll();



   //if(peakwin>=20&&profits<=(peakwin-20))
   //   CloseAll();

   //if(peakwin>=15&&profits<(peakwin*0.9))
   
   //if(peakwin>=(Tradesinfo.lastvolume*20)&&profits<=(peakwin*0.9))

   //if(postotal==1&&peakwin>=45&&profits<(peakwin*0.7))
   //   CloseAll();
   //if(postotal==2&&peakwin>=20&&profits<(peakwin*0.7))
   //   CloseAll();
   //if(postotal==3&&peakwin>=15&&profits<(peakwin*0.7))
   //   CloseAll();


   //if(profits<=-38)
   //   CloseAll();

   if ( curTime == prevTime ) {
      return;
   }


   //if(dt.hour==22 && profits>=0)
   //   CloseAll();

   //if(dt.hour>=13 && profits>=0 && postotal==1)
   //   CloseAll();

   bool adddown, addup;

   if(hedgeatlevel==0 || postotal<hedgeatlevel)
   {
      //if(peakwin>=20)
      //{
      //   if(Tradesinfo.initup)
      //      Tradesinfo.stepprice=Tradesinfo.initprice-(StepRange*_Point)+((peakwin*10)*_Point);
      //   if(!Tradesinfo.initup)
      //      Tradesinfo.stepprice=Tradesinfo.initprice+(StepRange*_Point)-((peakwin*10)*_Point);
      //}
   
      addup=Tradesinfo.initup&&current[0].close<=Tradesinfo.stepprice;
      adddown=!Tradesinfo.initup&&current[0].close>=Tradesinfo.stepprice;

      //if(profits<=-30)
      if(addup||adddown)
      {
         //if(postotal>10)
         //{
         //   CloseAll();
         //   return;
         //}
      
         bool hedge=false;
         if(hedgeatlevel>0 && postotal==hedgeatlevel-1)
         {
            hedge=true;
         }

      
         peakwin=0;
      
         ENUM_ORDER_TYPE type=ORDER_TYPE_BUY;
         double price=0, volume=0;
         CTrade trade;
         trade.SetExpertMagicNumber(magicnumber);
      
         if(adddown)
         {
            type=ORDER_TYPE_SELL;
            if(hedge)
               type=ORDER_TYPE_BUY;
            if(type==ORDER_TYPE_SELL)
               price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            else
               price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            Tradesinfo.stepprice=SymbolInfoDouble(_Symbol, SYMBOL_BID)+(StepRange*_Point);
            //Tradesinfo.stepprice=price+(StepRange*_Point);
         }
         if(addup)
         {
            type=ORDER_TYPE_BUY;
            if(hedge)
               type=ORDER_TYPE_SELL;
            if(type==ORDER_TYPE_SELL)
               price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            else
               price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            Tradesinfo.stepprice=SymbolInfoDouble(_Symbol, SYMBOL_BID)-(StepRange*_Point);
            //Tradesinfo.stepprice=price-(StepRange*_Point);
         }
         if(hedge)
         {
            volume = NormalizeDouble(Tradesinfo.totalvolume*hedgevolumefactor,2);
            if(type==ORDER_TYPE_SELL)
            {
               Tradesinfo.zonepricelower=price;
               //Tradesinfo.zonepriceupper=Tradesinfo.initprice-((Tradesinfo.initprice-Tradesinfo.zonepricelower)/2);
               Tradesinfo.zonepriceupper=Tradesinfo.initprice;
               Tradesinfo.zonesequence=-1;
            }
            else
            {
               Tradesinfo.zonepriceupper=price;
               //Tradesinfo.zonepricelower=Tradesinfo.initprice+((Tradesinfo.zonepriceupper-Tradesinfo.initprice)/2);
               Tradesinfo.zonepricelower=Tradesinfo.initprice;
               Tradesinfo.zonesequence=1;
            }
            Tradesinfo.lastvolume=volume;
         }
         else
         {
            volume = NormalizeDouble(Tradesinfo.lastvolume*volumefactor,2);
            if(volume<0.02)
               volume=0.02;
            Tradesinfo.lastvolume=volume;
            Tradesinfo.totalvolume+=volume;
            Tradesinfo.lastaddprice=price;
         }
         trade.PositionOpen(_Symbol, type, volume, price, NULL, NULL);
         if(hedge && continueafterhedge)
            magicnumber=(long)TimeCurrent();
      }
   }
   else if(Tradesinfo.zonesequence!=0)
   {
      addup=Tradesinfo.zonesequence==-1&&current[0].close>Tradesinfo.zonepriceupper;
      adddown=Tradesinfo.zonesequence==1&&current[0].close<Tradesinfo.zonepricelower;

      if(addup||adddown)
      {
         ENUM_ORDER_TYPE type=ORDER_TYPE_BUY;
         double price=0, volume=0;
         CTrade trade;
         trade.SetExpertMagicNumber(magicnumber);

         if(adddown)
         {
            type=ORDER_TYPE_SELL;
            price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         }
         if(addup)
         {
            type=ORDER_TYPE_BUY;
            price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         }
         //double basevolume=Tradesinfo.lastvolume/hedgevolumefactor;
         //volume = NormalizeDouble((Tradesinfo.lastvolume*hedgevolumefactor)-basevolume,2);
         volume = NormalizeDouble(Tradesinfo.lastvolume*hedgevolumefactor,2);
         Tradesinfo.lastvolume=volume;
         trade.PositionOpen(_Symbol, type, volume, price, NULL, NULL);
         if(adddown)
         {
            Tradesinfo.zonesequence=-1;
         }
         if(addup)
         {
            Tradesinfo.zonesequence=1;
         }
      }
   }

   prevTime = curTime;
}


void checkForOpen(int startmanual=0)
{
   datetime curTime = getCurrentTime();
   static datetime prevTime;
   
   if(curTime==prevTime&&startmanual==0)
   {
      return;
   }

   MqlDateTime dt;
   TimeToStruct(curTime,dt);
   if(StartAtFullHourOnly&&dt.min!=0&&startmanual==0)
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

   bool upbreakout, downbreakout;
   bool abovepivot=PivotsIsAbovePivot(current[0].close,pivotsdata.PivotsHour,"P");
   upbreakout=!abovepivot;
   //upbreakout=abovepivot;
   if(ReverseEntry)
      upbreakout=!upbreakout;
   downbreakout=!upbreakout;

   if(startmanual!=0)
   {
      upbreakout=false;
      downbreakout=false;
      if(startmanual==1)
         upbreakout=true;
      if(startmanual==-1)
         downbreakout=true;
   }

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


   int steprange=StepRange;
   if(upbreakout||downbreakout)
   {
      Tradesinfo.lastaddprice=0;
      Tradesinfo.zonepricelower=0;
      Tradesinfo.zonepriceupper=0;
      Tradesinfo.zonesequence=0;
   
      ENUM_ORDER_TYPE type=ORDER_TYPE_BUY;
      double price=0, sl=0, tp=0, volume=0;
      double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      CTrade trade;
      trade.SetExpertMagicNumber(magicnumber);

      if(upbreakout)
      {
         type = ORDER_TYPE_BUY;
         price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         Tradesinfo.initup=true;
         Tradesinfo.initprice=price;
         Tradesinfo.stepprice=SymbolInfoDouble(_Symbol, SYMBOL_BID)-(steprange*_Point);
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
         Tradesinfo.stepprice=price+(steprange*_Point);
         //sl = price+calculateDistance(price, 200);
         //tp = price-calculateDistance(price, 15000);
         //tp = price-((highrange-price)*TPFactor);
         tp = price-calculateDistance(price, 50);
      }

      volume = GetStartVolume();
      Tradesinfo.lastvolume=volume;
      Tradesinfo.totalvolume=volume;
      if ( !trade.PositionOpen(_Symbol, type, volume, price, NULL, NULL) )
      {
         Print("Failed to open the order. Error #", GetLastError());
         return;
      }
      if(upbreakout)
      {
         type = ORDER_TYPE_SELL;
         price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         lastupday=dt.day;
      }
      if(downbreakout)
      {
         type = ORDER_TYPE_BUY;
         price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         lastdownday=dt.day;
      }
      //trade.PositionOpen(_Symbol, type, volume*2, price, NULL, NULL);
         
      peakwin=0;
   }
   else
      return;


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

   if(IsTRadeOpen())
   {
      checkForClose();
   }
   else
   {
      checkForOpen();
   }
}


static bool ctrl_pressed = false;
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_KEYDOWN)
   {
      if (ctrl_pressed == false && lparam == 17)
      {
         ctrl_pressed = true;
      }
      else if (ctrl_pressed == true)
      {
         if (lparam == 49 && !IsTRadeOpen())
         {
            if(MessageBox("Start BUY?",NULL,MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2)==IDYES)
               checkForOpen(1);
            ctrl_pressed = false;
         }
         if (lparam == 50 && !IsTRadeOpen())
         {
            if(MessageBox("Start SELL?",NULL,MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2)==IDYES)
               checkForOpen(-1);
            ctrl_pressed = false;
         }
      }
   }
}

