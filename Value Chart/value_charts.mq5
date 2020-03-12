//+------------------------------------------------------------------+
//|                                                 Value Charts.mq5 |
//|                                          Copyright 2011, FxGeek. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2011, FxGeek."
#property link      "http://www.mql5.com"
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  C'251,0,138',C'0,172,230',clrBlack
#property indicator_width1  1
#property indicator_label1  "Open;High;Low;Close"
//--- indicator levels
#property indicator_level1 8
#property indicator_level2 6
#property indicator_level3 -6
#property indicator_level4 -8
#property indicator_levelcolor clrDarkGray
//--- indicator include
#include <MovingAverages.mqh>
//--- indicator input parameters
input int   Periode     = 5;
input bool  Show_Arrow  = true;
input int   Arrow_Width = 0;
input color Arrow_Up    = C'0,172,230';
input color Arrow_Down  = C'251,0,138';
input bool Alert  = true;
//--- indicator buffers
double ExtOBuffer[];
double ExtHBuffer[];
double ExtLBuffer[];
double ExtCBuffer[];
double ExtColorBuffer[];
double RangeAverage[];
double MiddleAverage[];

#define DATA_LIMIT Periode 
double _AValue;
double _BValue;
int lastalert = 0;
datetime lastflag = 0;
datetime lastmark = 0;
string appnamespace = "ValueChart-";
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
//--- indicator buffers mapping 
   SetIndexBuffer(0,ExtOBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtHBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtCBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,RangeAverage,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,MiddleAverage,INDICATOR_CALCULATIONS);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   IndicatorSetString(INDICATOR_SHORTNAME,"Value Chart "+IntegerToString(Periode));

   lastmark=TimeCurrent();
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ClearMyObjects();
   //Print("Deinit Value Chart, reason = "+IntegerToString(reason));
   ResetColorFlag(true);
  }
//+------------------------------------------------------------------+
//| Value Chart                                                      | 
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
   int i,limit;
//--- check for bars count
   if(rates_total<DATA_LIMIT)
      return(0);// not enough bars for calculation

//--- set first bar from what calculation will start
   if(prev_calculated<DATA_LIMIT)
      limit=DATA_LIMIT;
   else
      limit=prev_calculated-1;
//--- the main loop of calculations
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      RangeAverage[i]=High[i]-Low[i];
      _AValue=0.2*SimpleMA(i,Periode,RangeAverage);
      if(_AValue==0) _AValue=1;
      MiddleAverage[i]=(High[i]+Low[i])/2.0;
      _BValue=SimpleMA(i,Periode,MiddleAverage);

      ExtOBuffer[i]=((Open[i] - _BValue) / _AValue);
      ExtHBuffer[i]=((High[i] - _BValue) / _AValue);
      ExtLBuffer[i]=((Low[i]  - _BValue) / _AValue);
      ExtCBuffer[i]=((Close[i]- _BValue) / _AValue);

      //--- set color for candle

      //--- check for bear candle
      if(ExtCBuffer[i]<ExtOBuffer[i])
         ExtColorBuffer[i]=0.0;

      //--- check for bull candle
      if(ExtCBuffer[i]>ExtOBuffer[i])
         ExtColorBuffer[i]=1.0;


      int alertsecondsbefore=60;
      if(PeriodSeconds()==60)
         alertsecondsbefore=40;
      if(Alert && rates_total == prev_calculated && lastalert != rates_total)
      {
         if(PeriodSeconds()-(TimeCurrent()-Time[i])<=alertsecondsbefore)
         {
            if(ExtLBuffer[i-1]<=-8 && Close[i] > Open[i])
            {
               Print(_Symbol + " Oversold");
               PlaySound("\\Sounds\\cartoon014.wav");
               SetColorFlag();
               lastalert = rates_total;
            }
            if(ExtHBuffer[i-1]>=8 && Close[i] < Open[i])
            {
               Print(_Symbol + " Overbought");
               PlaySound("\\Sounds\\cartoon014.wav");
               SetColorFlag();
               lastalert = rates_total;
            }
         }
      }



      //--- check for lower extreme bar   
      if(ExtLBuffer[i]<=-8)
        {
         ExtColorBuffer[i]=2.0;
         if(Show_Arrow)Trace("Value Chart"+IntegerToString(i),1,Low[i],Time[i],Arrow_Up);

         //if(Alert && rates_total == prev_calculated && lastalert != rates_total)
         //{
         //   //Alert(_Symbol + " Oversold");
         //   Print(_Symbol + " Oversold");
         //   PlaySound("\\Sounds\\cartoon014.wav");
         //   SetColorFlag();
         //   lastalert = rates_total;
         //}

        }

      //--- check for high extreme bar   
      if(ExtHBuffer[i]>=8)
        {
         ExtColorBuffer[i]=2.0;
         if(Show_Arrow)Trace("Value Chart"+IntegerToString(i),-1,High[i],Time[i],Arrow_Down);

         //if(Alert && rates_total == prev_calculated && lastalert != rates_total)
         //{
         //   //Alert(_Symbol + " Overbought");
         //   Print(_Symbol + " Overbought");
         //   PlaySound("\\Sounds\\cartoon014.wav");
         //   SetColorFlag();
         //   lastalert = rates_total;
         //}

        }

     }
     ResetColorFlag();
     UpdateMark();
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  Trace Arrow Function                                            |
//+------------------------------------------------------------------+
void Trace(string name,int sens,double price,datetime time,color couleur)
  {
   ObjectCreate(0,appnamespace+name,OBJ_ARROW,0,time,price);
   if(sens==1)
      ObjectSetInteger(0,appnamespace+name,OBJPROP_ARROWCODE,233);
   if(sens==-1)
      ObjectSetInteger(0,appnamespace+name,OBJPROP_ARROWCODE,234);
   ObjectSetInteger(0,appnamespace+name,OBJPROP_COLOR,couleur);
   ObjectSetInteger(0,appnamespace+name,OBJPROP_WIDTH,Arrow_Width);
  }
//+------------------------------------------------------------------+
//|   Delete Arrow Function                                          |
//+------------------------------------------------------------------+  
void ClearMyObjects()
{
   ObjectsDeleteAll(0,appnamespace);
}
//+------------------------------------------------------------------+


void ResetColorFlag(bool init=false)
{
   string on = appnamespace + "Flag";
   if(ObjectFind(0,on)==0)
   {
      int timediff=(int)TimeCurrent()-(int)lastflag;
      int newwidth=200-(timediff/4);
      if(newwidth<20)
         newwidth=20;
      ObjectSetInteger(0,on,OBJPROP_XSIZE,newwidth);
      if(timediff > 1000 || init)
         ObjectDelete(0,on);
   }
}


void SetColorFlag()
{
   string on = appnamespace + "Flag";
   ObjectCreate(0,on,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,on,OBJPROP_XDISTANCE,0);
   ObjectSetInteger(0,on,OBJPROP_YDISTANCE,15);
   ObjectSetInteger(0,on,OBJPROP_XSIZE,200);
   ObjectSetInteger(0,on,OBJPROP_YSIZE,20);
   ObjectSetInteger(0,on,OBJPROP_BGCOLOR,Black);
   ObjectSetInteger(0,on,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,on,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,on,OBJPROP_WIDTH,0);
   ObjectSetInteger(0,on,OBJPROP_SELECTED,false);
   lastflag=TimeCurrent();
}


static bool ctrl_pressed = false;
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id==CHARTEVENT_KEYDOWN)
   {
      if (ctrl_pressed == false && lparam == 17)
      {
         ctrl_pressed = true;
      }
      else if (ctrl_pressed == true)
      {
         if (lparam == 49)
         {
            SetMark();
            ctrl_pressed = false;
         }
      }
   }
   return;
}


void SetMark()
{
   string on = "Mark";
   if(ObjectFind(0,on)==0)
   {
      ObjectDelete(0,on);
   }
   else
   {
      ObjectCreate(0,on,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0,on,OBJPROP_XDISTANCE,0);
      ObjectSetInteger(0,on,OBJPROP_YDISTANCE,35);
      ObjectSetInteger(0,on,OBJPROP_XSIZE,200);
      ObjectSetInteger(0,on,OBJPROP_YSIZE,20);
      ObjectSetInteger(0,on,OBJPROP_BGCOLOR,DeepPink);
      ObjectSetInteger(0,on,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,on,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,on,OBJPROP_WIDTH,0);
      ObjectSetInteger(0,on,OBJPROP_SELECTED,false);
      lastmark=TimeCurrent();
   }
}


void UpdateMark()
{
   string on = "Mark";
   if(ObjectFind(0,on)==0)
   {
      int timediff=(int)TimeCurrent()-(int)lastmark;
      int newwidth=200-(timediff/4);
      if(newwidth<20)
         newwidth=20;
      ObjectSetInteger(0,on,OBJPROP_XSIZE,newwidth);
   }
}