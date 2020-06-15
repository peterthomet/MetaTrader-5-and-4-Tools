//+------------------------------------------------------------------+
//|                                                   candleTime.mq5 |
//|                   Francesco Danti Copyright 2011, OracolTech.com |
//|                                       http://blog.oracoltech.com |
//|                                      email:     fdanti@gmail.com |
//|                               Optimizations by www.getyournet.ch |
//+------------------------------------------------------------------+
#property copyright "Francesco Danti Copyright 2011, OracolTech.com"
#property link      "http://blog.oracoltech.com"
#property version   "1.00"

#property indicator_chart_window

#property indicator_buffers 1
#property indicator_plots   1

string idxLabel="lblNextCandle";

input color lblColor=DarkGray; // Color of the label
input int fontSize=7; // Size of the label font
input ENUM_ANCHOR_POINT pAnchor = ANCHOR_LEFT_LOWER; // Anchor of the label a sort of align
input bool nextToPrice = false; // Position near the price close (else to anchor)
input ENUM_BASE_CORNER pCorner = CORNER_LEFT_LOWER; // Corner position of the label
input string fontFamily = "Arial"; // Font family of the label
input bool clocktime = true; // Show clock time
input int window = 0; // Window

datetime time0 = NULL;
double close0 = NULL;
int lastseconds = 0;


void OnInit()
{
   if(nextToPrice)
   {
      ObjectCreate(0,idxLabel,OBJ_TEXT,0,0,0);
      ObjectSetInteger(0,idxLabel,OBJPROP_ANCHOR,pAnchor);
   }
   else
   {
      ObjectCreate(0,idxLabel,OBJ_LABEL,window,0,0);
      ObjectSetInteger(0,idxLabel,OBJPROP_ANCHOR,pAnchor);
      ObjectSetInteger(0,idxLabel,OBJPROP_CORNER,pCorner);
      ObjectSetInteger(0,idxLabel,OBJPROP_XDISTANCE,3);
   }
   ObjectSetInteger(0,idxLabel,OBJPROP_COLOR,lblColor);
   ObjectSetInteger(0,idxLabel,OBJPROP_FONTSIZE,fontSize);
   ObjectSetString(0,idxLabel,OBJPROP_FONT,fontFamily);
   ObjectSetString(0,idxLabel,OBJPROP_TEXT," ");
   EventSetMillisecondTimer(100);
}


void OnDeinit(const int r)
{
   EventKillTimer();
   Comment("");
   ObjectDelete(0,idxLabel);
}


void OnTimer()
{
   if(time0!=NULL && close0!=NULL)
      Calculate();
}


int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(close,true);

   time0 = time[0];
   close0 = close[0];

   MoveLabel();

   return(rates_total);
}


void Calculate()
{
   int tS,iS,iM,iH;
   string sS,sM,sH;

   tS=(int) time0+PeriodSeconds() -(int) TimeCurrent();

   if(lastseconds==tS)
      return;

   lastseconds = tS;

   iS=tS%60;

   iM=(tS-iS);
   if(iM!=0) iM/=60;
   iM-=(iM-iM%60);

   iH=(tS-iS-iM*60);
   if(iH != 0) iH /= 60;
   if(iH != 0) iH /= 60;

   sS = IntegerToString(iS,1,'0');
   sM = IntegerToString(iM,1,'0');
   sH = IntegerToString(iH,1,'0');

   string cmt;
   cmt=sH+"h "+sM+"m "+sS+"s";
   if(iH==0)
   {
      cmt=sM+"m "+sS+"s";
      if(iM==0)
         cmt=sS+"s";
   }
   
   if(clocktime)
      cmt += " - " + TimeToString(time0+PeriodSeconds(),TIME_MINUTES);

   ObjectSetString(0,idxLabel,OBJPROP_TEXT,cmt);
   ChartRedraw();
}


void MoveLabel()
{
   if(nextToPrice)
   {
      ObjectSetInteger(0,idxLabel,OBJPROP_TIME,time0+PeriodSeconds()*2);
      ObjectSetDouble(0,idxLabel,OBJPROP_PRICE,close0);
   }
}