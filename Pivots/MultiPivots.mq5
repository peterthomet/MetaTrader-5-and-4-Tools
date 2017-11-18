//
// MultiPivots.mq5
// Copyright 2016, getYourNet IT Services
// http://www.getyournet.ch |
//

#property copyright "Copyright 2017, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1
#property script_show_inputs

#include <MultiPivots.mqh>

input color colorPivot=PaleGoldenrod;    // Color Pivot
input color colorS1=LightPink;    // Color S1
input color colorR1=LightPink;    // Color R1
input color colorS2=LightBlue;    // Color S2
input color colorR2=LightBlue;    // Color R2
input color colorS3=LightGray;    // Color S3
input color colorR3=LightGray;    // Color R3
input color colorS4=LightGray;    // Color S4
input color colorR4=LightGray;    // Color R4
input color colorS5=LightGray;    // Color S5
input color colorR5=LightGray;    // Color R5
input color colormidpoints=WhiteSmoke;    // Color Mid-Points

input TypePivotsType PivotTypeHour=PIVOT_TRADITIONAL;    // Pivot Type Hour
input TypePivotsType PivotTypeFourHour=PIVOT_TRADITIONAL;    // Pivot Type Four Hour
input TypePivotsType PivotTypeDay=PIVOT_TRADITIONAL;    // Pivot Type Day
input TypePivotsType PivotTypeWeek=PIVOT_TRADITIONAL;    // Pivot Type Week
input bool PivotTypeHourMidPoints=true;    // Pivot Hour Show Mid-Points
input bool PivotTypeFourHourMidPoints=true;    // Pivot Four Hour Show Mid-Points
input bool PivotTypeDayMidPoints=true;    // Pivot Day Show Mid-Points
input bool PivotTypeWeekMidPoints=true;    // Pivot Week Show Mid-Points

input ENUM_LINE_STYLE LineStyleHour=STYLE_SOLID;    // Line Style Hour
input ENUM_LINE_STYLE LineStyleFourHour=STYLE_SOLID;    // Line Style Four Hour
input ENUM_LINE_STYLE LineStyleDay=STYLE_SOLID;    // Line Style Day
input ENUM_LINE_STYLE LineStyleWeek=STYLE_SOLID;    // Line Style Week

string short_name="MultiPivots";
bool newbar=false;
long firstbar=0;
long lastfirstbar=-1;
bool istesting;


void OnInit()
{
   PD.Settings.draw=PlotIndexGetInteger(0,PLOT_SHOW_DATA);
   PD.Settings.objectnamespace=short_name;
   PD.Settings.colorPivot=colorPivot;
   PD.Settings.colorS1=colorS1;
   PD.Settings.colorR1=colorR1;
   PD.Settings.colorS2=colorS2;
   PD.Settings.colorR2=colorR2;
   PD.Settings.colorS3=colorS3;
   PD.Settings.colorR3=colorR3;
   PD.Settings.colorS4=colorS4;
   PD.Settings.colorR4=colorR4;
   PD.Settings.colorS5=colorS5;
   PD.Settings.colorR5=colorR5;
   PD.Settings.colormidpoints=colormidpoints;
   PD.Settings.PivotTypeHour=PivotTypeHour;
   PD.Settings.PivotTypeFourHour=PivotTypeFourHour;
   PD.Settings.PivotTypeDay=PivotTypeDay;
   PD.Settings.PivotTypeWeek=PivotTypeWeek;
   PD.Settings.PivotTypeHourMidPoints=PivotTypeHourMidPoints;
   PD.Settings.PivotTypeFourHourMidPoints=PivotTypeFourHourMidPoints;
   PD.Settings.PivotTypeDayMidPoints=PivotTypeDayMidPoints;
   PD.Settings.PivotTypeWeekMidPoints=PivotTypeWeekMidPoints;
   PD.Settings.LineStyleHour=LineStyleHour;
   PD.Settings.LineStyleFourHour=LineStyleFourHour;
   PD.Settings.LineStyleDay=LineStyleDay;
   PD.Settings.LineStyleDay=LineStyleWeek;
   
   istesting=MQLInfoInteger(MQL_TESTER);
   EventSetTimer(1);
}


void OnDeinit(const int reason)
{
   EventKillTimer();
   PivotsDeleteObjects();
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
         
      if(!PD.Calculate(arr1[0]))
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
            if(!PlotIndexGetInteger(0,PLOT_SHOW_DATA))
            {
               PlotIndexSetInteger(0,PLOT_SHOW_DATA,true);
               PD.Settings.draw=true;
               PD.Settings.Init();
               newbar=true;
            }
            else
            {
               PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
               PD.Settings.draw=false;
               PD.Settings.Init();
               newbar=true;
            }
            ctrl_pressed = false;
         }
      }
   }
}

