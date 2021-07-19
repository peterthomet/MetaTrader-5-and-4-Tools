//
// MultiPivots.mq5/mq4
// Copyright 2020, getYourNet IT Services
// http://www.getyournet.ch |
//

#property copyright "Copyright 2020, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "2.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1
#property script_show_inputs

#include <MultiPivots.mqh>

input string AppNamespace="MultiPivots1";    // Application Namespace
input color colorPivot=C'250,250,250';    // Color Pivot
input color colorPivotRange=C'250,250,250';    // Color Pivot Range
input color colorPivotTrendLine=Gainsboro;    // Color Pivot Trend Line
input color colorS1=MistyRose;    // Color S1
input color colorR1=MistyRose;    // Color R1
input color colorS2=C'220,233,255';    // Color S2
input color colorR2=C'220,233,255';    // Color R2
input color colorS3=clrNONE;    // Color S3
input color colorR3=clrNONE;    // Color R3
input color colorS4=clrNONE;    // Color S4
input color colorR4=clrNONE;    // Color R4
input color colorS5=clrNONE;    // Color S5
input color colorR5=clrNONE;    // Color R5
input color colormidpoints=WhiteSmoke;    // Color Mid-Points

input TypePivotsType PivotTypeHour=NONE;    // Pivot Type Hour
input TypePivotsType PivotTypeFourHour=NONE;    // Pivot Type Four Hour
input TypePivotsType PivotTypeDay=NONE;    // Pivot Type Day
input TypePivotsType PivotTypeWeek=NONE;    // Pivot Type Week
input TypePivotsType PivotTypeMonth=NONE;    // Pivot Type Month
input TypePivotsType PivotTypeYear=NONE;    // Pivot Type Year
input bool PivotTypeHourMidPoints=false;    // Pivot Hour Show Mid-Points
input bool PivotTypeFourHourMidPoints=false;    // Pivot Four Hour Show Mid-Points
input bool PivotTypeDayMidPoints=false;    // Pivot Day Show Mid-Points
input bool PivotTypeWeekMidPoints=false;    // Pivot Week Show Mid-Points
input bool PivotTypeMonthMidPoints=false;    // Pivot Month Show Mid-Points
input bool PivotTypeYearMidPoints=false;    // Pivot Year Show Mid-Points

input ENUM_LINE_STYLE LineStyleHour=STYLE_SOLID;    // Line Style Hour
input ENUM_LINE_STYLE LineStyleFourHour=STYLE_SOLID;    // Line Style Four Hour
input ENUM_LINE_STYLE LineStyleDay=STYLE_SOLID;    // Line Style Day
input ENUM_LINE_STYLE LineStyleWeek=STYLE_SOLID;    // Line Style Week
input ENUM_LINE_STYLE LineStyleMonth=STYLE_SOLID;    // Line Style Month
input ENUM_LINE_STYLE LineStyleYear=STYLE_SOLID;    // Line Style Year

input bool weekstartuseservertime=false;    // Week Start use Monday 0:00 Servertime

bool newbar=false;
long firstbar=0;
long lastfirstbar=-1;
bool istesting;
TypePivotsData pivotsdata;


void OnInit()
{
   pivotsdata.Settings.draw=((int)GlobalVariableGet(AppNamespace+IntegerToString(ChartID())+"_Draw")>=0);
   pivotsdata.Settings.objectnamespace=AppNamespace+"-1";
   pivotsdata.Settings.colorPivot=colorPivot;
   pivotsdata.Settings.colorS1=colorS1;
   pivotsdata.Settings.colorR1=colorR1;
   pivotsdata.Settings.colorS2=colorS2;
   pivotsdata.Settings.colorR2=colorR2;
   pivotsdata.Settings.colorS3=colorS3;
   pivotsdata.Settings.colorR3=colorR3;
   pivotsdata.Settings.colorS4=colorS4;
   pivotsdata.Settings.colorR4=colorR4;
   pivotsdata.Settings.colorS5=colorS5;
   pivotsdata.Settings.colorR5=colorR5;
   pivotsdata.Settings.colormidpoints=colormidpoints;
   pivotsdata.Settings.PivotTypeHour=PivotTypeHour;
   pivotsdata.Settings.PivotTypeFourHour=PivotTypeFourHour;
   pivotsdata.Settings.PivotTypeDay=PivotTypeDay;
   pivotsdata.Settings.PivotTypeWeek=PivotTypeWeek;
   pivotsdata.Settings.PivotTypeMonth=PivotTypeMonth;
   pivotsdata.Settings.PivotTypeYear=PivotTypeYear;
   pivotsdata.Settings.PivotTypeHourMidPoints=PivotTypeHourMidPoints;
   pivotsdata.Settings.PivotTypeFourHourMidPoints=PivotTypeFourHourMidPoints;
   pivotsdata.Settings.PivotTypeDayMidPoints=PivotTypeDayMidPoints;
   pivotsdata.Settings.PivotTypeWeekMidPoints=PivotTypeWeekMidPoints;
   pivotsdata.Settings.PivotTypeMonthMidPoints=PivotTypeMonthMidPoints;
   pivotsdata.Settings.PivotTypeYearMidPoints=PivotTypeYearMidPoints;
   pivotsdata.Settings.LineStyleHour=LineStyleHour;
   pivotsdata.Settings.LineStyleFourHour=LineStyleFourHour;
   pivotsdata.Settings.LineStyleDay=LineStyleDay;
   pivotsdata.Settings.LineStyleWeek=LineStyleWeek;
   pivotsdata.Settings.LineStyleMonth=LineStyleMonth;
   pivotsdata.Settings.LineStyleYear=LineStyleYear;
   pivotsdata.Settings.pivotrangecolor=colorPivotRange;
   pivotsdata.Settings.pivottrendlinescolor=colorPivotTrendLine;
   pivotsdata.Settings.weekstartuseservertime=weekstartuseservertime;
   
   istesting=MQLInfoInteger(MQL_TESTER);
   EventSetTimer(1);
}


void OnDeinit(const int reason)
{
   EventKillTimer();
   PivotsDeleteObjects(pivotsdata);

   int draw=1;
   if(!pivotsdata.Settings.draw)
      draw=-1;
   GlobalVariableSet(AppNamespace+IntegerToString(ChartID())+"_Draw",draw);
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
                const int &spread[]
                )
{
   if(rates_total>prev_calculated)
   {
      newbar=true;
      if(istesting)
         OnTimer();
   }
   return(rates_total);
}


void OnTimer()
{
   if(newbar || lastfirstbar!=firstbar)
   {
      datetime arr1[1];
      if(CopyTime(_Symbol,_Period,(int)firstbar,1,arr1)<1)
         return;
         
      if(!pivotsdata.Calculate(arr1[0]))
         return;
         
      lastfirstbar=firstbar;
      newbar=false;
   }
}


static bool ctrl_pressed = false;
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_CHART_CHANGE)
   {
      long firstvisible=ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR);
      long visiblebars=ChartGetInteger(0,CHART_VISIBLE_BARS);
      if(firstvisible>visiblebars-1)
         firstbar=firstvisible-visiblebars+1;
      else
         firstbar=0;
   }
   if(id==CHARTEVENT_KEYDOWN)
   {
      if (ctrl_pressed == false && lparam == 17)
      {
         ctrl_pressed = true;
      }
      else if (ctrl_pressed == true)
      {
         if (lparam == 52)
         {
            pivotsdata.Settings.draw=!pivotsdata.Settings.draw;
            pivotsdata.Settings.Init();
            newbar=true;
            ctrl_pressed = false;
         }
      }
   }
}

