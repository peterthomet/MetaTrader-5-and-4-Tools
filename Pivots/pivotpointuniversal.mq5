//+------------------------------------------------------------------+
//|                                          PivotPointUniversal.mq5 |
//|                                               Copyright VDV Soft |
//|                                                 vdv_2001@mail.ru |
//+------------------------------------------------------------------+
#property copyright "VDV Soft"
#property link      "vdv_2001@mail.ru"
#property version   "1.00"
#property description         "Classical pivot levels."
#property indicator_chart_window
#define     count_buffers     9
#property indicator_buffers   count_buffers
#property indicator_plots     count_buffers
//--- plot buffer 1
#property indicator_label1    "Pivot"
#property indicator_type1     DRAW_ARROW
#property indicator_color1    PaleGoldenrod
#property indicator_style1    STYLE_DOT
#property indicator_width1    1
//--- plot buffer 2
#property indicator_label2    "S1"
#property indicator_type2     DRAW_ARROW
#property indicator_color2    LightPink
#property indicator_style2    STYLE_SOLID
#property indicator_width2    1
//--- plot buffer 3
#property indicator_label3    "R1"
#property indicator_type3     DRAW_ARROW
#property indicator_color3    LightPink
#property indicator_style3    STYLE_SOLID
#property indicator_width3    1
//--- plot buffer 4
#property indicator_label4    "S2"
#property indicator_type4     DRAW_ARROW
#property indicator_color4    LightSkyBlue
#property indicator_style4    STYLE_SOLID
#property indicator_width4    1
//--- plot buffer 5
#property indicator_label5    "R2"
#property indicator_type5     DRAW_ARROW
#property indicator_color5    LightSkyBlue
#property indicator_style5    STYLE_SOLID
#property indicator_width5    1
//--- plot buffer 6
#property indicator_label6    "S3"
#property indicator_type6     DRAW_ARROW
#property indicator_color6    LightGreen
#property indicator_style6    STYLE_SOLID
#property indicator_width6    1
//--- plot buffer 7
#property indicator_label7    "R3"
#property indicator_type7     DRAW_ARROW
#property indicator_color7    LightGreen
#property indicator_style7    STYLE_SOLID
#property indicator_width7    1
//--- plot buffer 8
#property indicator_label8    "S4"
#property indicator_type8     DRAW_ARROW
#property indicator_color8    LightGreen
#property indicator_style8    STYLE_SOLID
#property indicator_width8    1
//--- plot buffer 9
#property indicator_label9    "R4"
#property indicator_type9     DRAW_ARROW
#property indicator_color9    LightGreen
#property indicator_style9    STYLE_SOLID
#property indicator_width9    1
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum PivotType
  {
   PIVOT_CLASSIC=0,
   PIVOT_FIBONACCI=1,
   PIVOT_DEMARK=2,
   PIVOT_CAMARILLA=3,
   PIVOT_WOODIES=4
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum inptime
  {
   TIME_TRADE_SERVER,
   TIME_GMT
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum inpperiod
  {
   DAY,
   WEEKLY,
   MONTHLY
  };
input PivotType InpPivotType=PIVOT_CLASSIC; //Pivot type
input inpperiod InpPeriod=DAY;   // Period
input inptime InpTime=TIME_TRADE_SERVER;  //Time

//---- buffers
double   PBuffer[];
double   S1Buffer[];
double   R1Buffer[];
double   S2Buffer[];
double   R2Buffer[];
double   S3Buffer[];
double   R3Buffer[];
double   S4Buffer[];
double   R4Buffer[];
//    Global variable
int      ShiftTime;  // Displacement of the buffer for construction of levels in the future
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
// Displacement of the buffer for construction of levels in the future
   string period;
   string shiftGMT=" TRADE SERVER ";
   switch(InpPeriod)
     {
      case DAY:
         //--- Verify Time Period
         //if(PeriodSeconds(_Period)>=PeriodSeconds(PERIOD_H2))
         if(PeriodSeconds(_Period)>=PeriodSeconds(PERIOD_D1))
           {
            return(-1);
           }
         period="(DAY)";
         shiftGMT=(InpTime==TIME_GMT)?" GMT ":" TRADE SERVER ";
         ShiftTime=int((TimeTradeServer()-TimeGMT())/PeriodSeconds(_Period))+int(PeriodSeconds(PERIOD_D1)/PeriodSeconds(_Period));
         for(int i=0;i<count_buffers;i++)
            PlotIndexSetInteger(i,PLOT_ARROW,159);
         PlotIndexSetInteger(0,PLOT_ARROW,110);
         break;
      case WEEKLY:
         //--- Verify Time Period
         //if(PeriodSeconds(_Period)>=PeriodSeconds(PERIOD_D1))
         if(PeriodSeconds(_Period)>=PeriodSeconds(PERIOD_W1))
           {
            return(-1);
           }
         period="(WEEKLY)";
         ShiftTime=int((TimeTradeServer()-TimeGMT())/PeriodSeconds(_Period))+int(PeriodSeconds(PERIOD_W1)/PeriodSeconds(_Period));
         for(int i=0;i<count_buffers;i++)
            PlotIndexSetInteger(i,PLOT_ARROW,115);
         //PlotIndexSetInteger(0,PLOT_ARROW,110);
         break;
      case MONTHLY:
         //--- Verify Time Period
         if(PeriodSeconds(_Period)>=PeriodSeconds(PERIOD_MN1))
           {
            return(-1);
           }
         period="(MONTHLY)";
         ShiftTime=int((TimeTradeServer()-TimeGMT())/PeriodSeconds(_Period))+int(PeriodSeconds(PERIOD_MN1)/PeriodSeconds(_Period));
         for(int i=0;i<count_buffers;i++)
            PlotIndexSetInteger(i,PLOT_ARROW,250);
         //PlotIndexSetInteger(0,PLOT_ARROW,110);
         break;
     }
   IndicatorSetString(INDICATOR_SHORTNAME,"PivotPoint"+period+shiftGMT+"time");
//--- indicator buffers mapping
   SetIndexBuffer(0,PBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,S1Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,R1Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,S2Buffer,INDICATOR_DATA);
   SetIndexBuffer(4,R2Buffer,INDICATOR_DATA);
   SetIndexBuffer(5,S3Buffer,INDICATOR_DATA);
   SetIndexBuffer(6,R3Buffer,INDICATOR_DATA);
   SetIndexBuffer(7,S4Buffer,INDICATOR_DATA);
   SetIndexBuffer(8,R4Buffer,INDICATOR_DATA);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   for(int i=0;i<count_buffers;i++)
     {
      PlotIndexSetInteger(i,PLOT_SHIFT,ShiftTime);
      PlotIndexSetDouble(i,PLOT_EMPTY_VALUE,EMPTY_VALUE);
      //PlotIndexSetInteger(i,PLOT_ARROW,159);
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
//--- auxiliary variables
   int  i=1;
   MqlDateTime time1,time2;
//--- set position for beginning
   if(prev_calculated==0)
     {
      i=ShiftTime+1;
      ArrayInitialize(PBuffer,EMPTY_VALUE);
      ArrayInitialize(S1Buffer,EMPTY_VALUE);
      ArrayInitialize(R1Buffer,EMPTY_VALUE);
      ArrayInitialize(S2Buffer,EMPTY_VALUE);
      ArrayInitialize(R2Buffer,EMPTY_VALUE);
      ArrayInitialize(S3Buffer,EMPTY_VALUE);
      ArrayInitialize(R3Buffer,EMPTY_VALUE);
     }
   else
      i=prev_calculated-1;
//--- start calculations
   while(i<rates_total)
     {
      TimeToStruct(time[i-1],time1);
      TimeToStruct(time[i],time2);
      switch(InpPeriod)
        {
         case DAY:
            if(time1.day!=time2.day)
              {
              int weekendshift = 0;
              if(time2.day_of_week==1)
              {
                  weekendshift = PeriodSeconds(PERIOD_D1)*2;
              }
               time1.hour=0;
               time1.min=0;
               time1.sec=0;
               time2.hour=0;
               time2.min=0;
               time2.sec=0;
               DrawPivotLevel(StructToTime(time1)-weekendshift,StructToTime(time2)-weekendshift,i);
              }
            break;
         case WEEKLY:
            if(time1.day_of_week!=time2.day_of_week && time2.day_of_week==1)
              {
               time2.hour=0;
               time2.min=0;
               time2.sec=0;
               datetime work=StructToTime(time2);
               DrawPivotLevel(work-PeriodSeconds(PERIOD_W1),work,i);
              }
            break;
         case MONTHLY:
            if(time1.mon!=time2.mon)
              {
               time1.day=time2.day=1;
               time1.hour=time2.hour=0;
               time1.min=time2.min=0;
               time1.sec=time2.sec=0;
               DrawPivotLevel(StructToTime(time1),StructToTime(time2),i);
              }
            break;
        }
      i++;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|   Calculation an filling the Pivot buffers                       |
//+------------------------------------------------------------------+
void DrawPivotLevel(datetime Previous,datetime Current,int Index)
  {
   int rates_total,shift,shift_end=0;
   double range=0,pivot=0,support1=0,support2=0,support3=0,support4=0,resistance1=0,resistance2=0,resistance3=0,resistance4=0;
   double iHigh[],iLow[],iClose[],iOpen[],HighDay,LowDay,CloseDay,OpenDay;
   datetime shiftGMT=0;
   switch(InpPeriod)
     {
      case DAY:
         shift_end=int(PeriodSeconds(PERIOD_D1)/PeriodSeconds(_Period));
         if(InpTime==TIME_GMT) shiftGMT=(TimeTradeServer()-TimeGMT());
         break;
      case WEEKLY:
         shift_end=int(PeriodSeconds(PERIOD_W1)/PeriodSeconds(_Period));
         break;
      case MONTHLY:
         shift_end=int(PeriodSeconds(PERIOD_MN1)/PeriodSeconds(_Period));
         break;
     }
   datetime _start=Previous+shiftGMT;
   datetime _end=Current+shiftGMT-1;

   rates_total=CopyHigh(NULL,_Period,_start,_end,iHigh);
   if(rates_total<=0)
      return;
   else
      HighDay=iHigh[ArrayMaximum(iHigh,0,rates_total)];
   rates_total=CopyLow(NULL,_Period,_start,_end,iLow);
   if(rates_total<=0)
      return;
   else
      LowDay=iLow[ArrayMinimum(iLow,0,rates_total)];
   rates_total=CopyClose(NULL,_Period,_end,1,iClose);
   if(rates_total<=0)
      return;
   else
      CloseDay=iClose[0];
   rates_total=CopyOpen(NULL,_Period,_end+1,1,iOpen);
   if(rates_total<=0)
      return;
   else
      OpenDay=iOpen[0];
   switch(InpPivotType)
     {
      case PIVOT_CLASSIC:
         pivot=(CloseDay+HighDay+LowDay)/3;
         support1=(2*pivot)-HighDay;
         support2=pivot-(HighDay - LowDay);
         support3=(2*pivot)-((2* HighDay)-LowDay);
         support4=EMPTY_VALUE;
         resistance1=(2*pivot)-LowDay;
         resistance2=pivot+(HighDay - LowDay);
         resistance3=(2*pivot)+(HighDay-(2*LowDay));
         resistance4=EMPTY_VALUE;
         break;
      case PIVOT_FIBONACCI:
         range=HighDay-LowDay;
         pivot=(CloseDay+HighDay+LowDay)/3;
         support1=pivot-0.382*range;
         support2=pivot-0.618*range;
         support3=pivot-range;
         support4=EMPTY_VALUE;
         resistance1=pivot+0.382*range;
         resistance2=pivot+0.618*range;
         resistance3=pivot+range;
         resistance4=EMPTY_VALUE;
         break;
      case PIVOT_DEMARK:
         if(CloseDay<OpenDay) pivot=HighDay+2*LowDay+CloseDay;
         if(CloseDay>OpenDay) pivot=2*HighDay+LowDay+CloseDay;
         if(CloseDay==OpenDay) pivot=HighDay+LowDay+2*CloseDay;
         support1=pivot/2-HighDay;
         resistance1=pivot/2-LowDay;
         pivot=EMPTY_VALUE;
         support2=EMPTY_VALUE;
         support3=EMPTY_VALUE;
         support4=EMPTY_VALUE;
         resistance2=EMPTY_VALUE;
         resistance3=EMPTY_VALUE;
         resistance4=EMPTY_VALUE;
         break;
      case PIVOT_CAMARILLA:
         range=HighDay-LowDay;
         pivot=EMPTY_VALUE;
         support1=CloseDay-range*1.1/12;
         support2=CloseDay-range*1.1/6;
         support3=CloseDay-range*1.1/4;
         support4=CloseDay-range*1.1/2;
         resistance1=range*1.1/12+CloseDay;
         resistance2=range*1.1/6+CloseDay;
         resistance3=range*1.1/4+CloseDay;
         resistance4=range*1.1/2+CloseDay;
         break;
      case PIVOT_WOODIES:
         range=HighDay-LowDay;
         pivot=(HighDay+LowDay+2*CloseDay)/4;
         support1=2*pivot-HighDay;
         support2=pivot-HighDay+LowDay;
         support3=EMPTY_VALUE;
         support4=EMPTY_VALUE;
         resistance1=2*pivot-LowDay;
         resistance2=pivot+HighDay-LowDay;
         resistance3=EMPTY_VALUE;
         resistance4=EMPTY_VALUE;
         break;
     }

   shift=Index-ShiftTime+int(shiftGMT/PeriodSeconds(_Period));
   for(int i=0;i<=shift_end;i++)
     {
      PBuffer[shift+i]=pivot;
      S1Buffer[shift+i]=support1;
      S2Buffer[shift+i]=support2;
      S3Buffer[shift+i]=support3;
      S4Buffer[shift+i]=support4;
      R1Buffer[shift+i]=resistance1;
      R2Buffer[shift+i]=resistance2;
      R3Buffer[shift+i]=resistance3;
      R4Buffer[shift+i]=resistance4;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LineY(int Index,double StartY,double EndY,int StartX,int EndX)
  {
   double LINH=StartY*(Index-EndX)/(StartX-EndX)+EndY*(Index-StartX)/(EndX-StartX);
   return(LINH);
  }
//+------------------------------------------------------------------+
