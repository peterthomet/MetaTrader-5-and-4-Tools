//
// Set All Charts.mq4/mq5
// getYourNet.ch
//

#property copyright "Copyright 2019, getYourNet.ch"

enum TypeChartsApplyTemplate
{
   AllChartsWithoutSubwindow, // All Charts without Subwindow
   AllCharts // All Charts
};

input TypeChartsApplyTemplate ChartsApplyTemplate = AllChartsWithoutSubwindow; // Charts Apply Template

string appnamespace="SetAllCharts";

enum Command
{
   Clean,
   PivotsY1,
   PivotsMN,
   PivotsW1,
   PivotsD1,
   PivotsH4,
   PivotsH1,
   ChandelierExit,
   PivotChart,
   Murrey,
   ZigZag,
   Engulfing,
   HeikenAshi,
   Line,
   Candles,
   ZoomIn,
   ZoomOut,
   ChartShift,
   NoChartShift,
   M1,
   M2,
   M3,
   M4,
   M5,
   M6,
   M10,
   M12,
   M15,
   M20,
   M30,
   H1,
   H2,
   H3,
   H4,
   H6,
   H8,
   H12,
   D1,
   W1,
   MN
};
string CommandText[MN+1]={"Clean","PivotsY1","PivotsMN","PivotsW1","PivotsD1","PivotsH4","PivotsH1","Chandelier Exit","Pivot Chart","Murrey","ZigZag","Engulfing","Heiken Ashi","Line","Candles","+","-","<",">","M1","M2","M3","M4","M5","M6","M10","M12","M15","M20","M30","H1","H2","H3","H4","H6","H8","H12","D1","W1","MN"};
string CommandToolTip[MN+1]={"Empty Small.tpl","Forex PivotsY1.tpl","Forex PivotsMN.tpl","Forex PivotsW1.tpl","Forex PivotsD1.tpl","Forex PivotsH4.tpl","Forex PivotsH1.tpl","Forex Chandelier Exit.tpl","Forex Pivot Chart.tpl","Forex Murrey Math Small.tpl","Forex ZigZag Small.tpl","Engulfing.tpl","HeikenAshi.tpl","","","","","","","","","","","","","","","","","","","","","","","","","","",""};
int CommandPeriod[MN+1]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1};


void OnInit()
{
   ChartSetInteger(0,CHART_SHOW,false);

   CreateButton(7,5,M1);
   CreateButton(7,25,M2);
   CreateButton(7,45,M3);
   CreateButton(7,65,M4);
   CreateButton(35,5,M5);
   CreateButton(35,25,M6);
   CreateButton(35,45,M10);
   CreateButton(35,65,M12);
   CreateButton(63,5,M15);
   CreateButton(63,25,M20);
   CreateButton(100,5,M30);
   CreateButton(138,5,H1);
   CreateButton(138,25,H2);
   CreateButton(138,45,H3);
   CreateButton(163,5,H4);
   CreateButton(163,25,H6);
   CreateButton(163,45,H8);
   CreateButton(163,65,H12);
   CreateButton(190,5,D1);
   CreateButton(217,5,W1);
   CreateButton(247,5,MN);
   CreateButton(305,5,ZoomIn);
   CreateButton(327,5,ZoomOut);
   CreateButton(350,5,ChartShift);
   CreateButton(370,5,NoChartShift);
   CreateButton(305,25,Line);
   CreateButton(345,25,Candles);
   CreateButton(305,45,Clean);
   CreateButton(355,45,Murrey);
   CreateButton(415,45,ZigZag);
   CreateButton(305,65,Engulfing);
   CreateButton(380,65,HeikenAshi);

   CreateButton(305,85,PivotsY1);
   CreateButton(380,85,PivotsMN);
   CreateButton(455,85,PivotsW1);
   CreateButton(305,105,PivotsD1);
   CreateButton(380,105,PivotsH4);
   CreateButton(455,105,PivotsH1);

   CreateButton(305,125,ChandelierExit);

   CreateButton(305,145,PivotChart);
   
   ChartRedraw();
}


void CreateButton(int xPos, int yPos, int command)
{
   string text=CommandText[command];
   string tooltip=CommandToolTip[command];
   string objname=appnamespace+"Command"+IntegerToString(command);
   ObjectCreate(0,objname,OBJ_LABEL,0,0,0,0,0);
   ObjectSetInteger(0,objname,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,objname,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,objname,OBJPROP_XDISTANCE,xPos);
   ObjectSetInteger(0,objname,OBJPROP_YDISTANCE,yPos);
   ObjectSetInteger(0,objname,OBJPROP_COLOR,C'100,100,100');
   ObjectSetInteger(0,objname,OBJPROP_FONTSIZE,11);
   ObjectSetString(0,objname,OBJPROP_FONT,"Arial");
   ObjectSetString(0,objname,OBJPROP_TEXT," "+text+" ");
   ObjectSetString(0,objname,OBJPROP_TOOLTIP,tooltip);
}


void OnDeinit(const int reason)
{
   DeleteAllObjects();
   ChartSetInteger(0,CHART_SHOW,true);
}


void DeleteAllObjects()
{
   ObjectsDeleteAll(0,appnamespace);
}


void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      int pos=StringFind(sparam,"Command");
      if(pos>-1)
         ExecuteCommand((int)StringToInteger(StringSubstr(sparam,pos+7)));
   }
}


void ExecuteCommand(int command)
{
   long chartid=ChartFirst();
   while(chartid>-1)
   {
      if(chartid!=ChartID())
      {
         bool hassubwindows=(ChartGetInteger(chartid,CHART_WINDOWS_TOTAL)>1);
         bool apply=!hassubwindows||ChartsApplyTemplate==AllCharts;
         
         if(apply)
         {
            if(command==Clean)
               ChartApplyTemplate(chartid,"Empty Small.tpl");
            if(command==PivotsY1)
               ChartApplyTemplate(chartid,"Forex PivotsY1.tpl");
            if(command==PivotsMN)
               ChartApplyTemplate(chartid,"Forex PivotsMN.tpl");
            if(command==PivotsW1)
               ChartApplyTemplate(chartid,"Forex PivotsW1.tpl");
            if(command==PivotsD1)
               ChartApplyTemplate(chartid,"Forex PivotsD1.tpl");
            if(command==PivotsH4)
               ChartApplyTemplate(chartid,"Forex PivotsH4.tpl");
            if(command==PivotsH1)
               ChartApplyTemplate(chartid,"Forex PivotsH1.tpl");
            if(command==ChandelierExit)
               ChartApplyTemplate(chartid,"Forex Chandelier Exit.tpl");
            if(command==PivotChart)
               ChartApplyTemplate(chartid,"Forex Pivot Chart.tpl");
            if(command==Murrey)
               ChartApplyTemplate(chartid,"Forex Murrey Math Small.tpl");
            if(command==ZigZag)
               ChartApplyTemplate(chartid,"Forex ZigZag Small.tpl");
            if(command==Engulfing)
               ChartApplyTemplate(chartid,"Engulfing.tpl");
            if(command==HeikenAshi)
               ChartApplyTemplate(chartid,"HeikenAshi.tpl");
            if(command==Line)
               ChartSetInteger(chartid,CHART_MODE,CHART_LINE);
            if(command==Candles)
               ChartSetInteger(chartid,CHART_MODE,CHART_CANDLES);
            if(command==ZoomIn)
               Zoom(chartid,1);
            if(command==ZoomOut)
               Zoom(chartid,-1);
            if(command==ChartShift)
            {
               ChartSetDouble(chartid,CHART_SHIFT_SIZE,20);
               ChartSetInteger(chartid,CHART_SHIFT,true);
            }
            if(command==NoChartShift)
               ChartSetInteger(chartid,CHART_SHIFT,false);
         }

         if(command>NoChartShift)
            ChartSetSymbolPeriod(chartid,ChartSymbol(chartid),(ENUM_TIMEFRAMES)CommandPeriod[command]);

         ChartRedraw(chartid);
      }
      chartid=ChartNext(chartid);
   }
}


void Zoom(long chartid, int value)
{
   long zoom=ChartGetInteger(chartid,CHART_SCALE);
   zoom+=value;
   if(zoom>5) zoom=5;
   if(zoom<0) zoom=0;
   ChartSetInteger(chartid,CHART_SCALE,zoom);
   ChartNavigate(chartid,CHART_END);
}

