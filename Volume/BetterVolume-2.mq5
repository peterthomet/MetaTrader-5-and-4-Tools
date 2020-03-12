//+------------------------------------------------------------------+
//|                                                 BetterVolume.mq5 |
//|                                  Copyright © 2011, EarnForex.com |
//|                                         http://www.earnforex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, www.EarnForex.com"
#property link      "http://www.earnforex.com/"
#property version   "1.00"

#property description "Volume anomalies histogram"

#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   2
#property indicator_color1  clrCrimson, clrGainsboro, clrGold, clrLightSeaGreen, clrBlack, clrOrchid
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_width1  5
#property indicator_color2  clrLightSlateGray
#property indicator_label2  "Average"
#property indicator_type2   DRAW_LINE
#property indicator_width2  1
#property indicator_style2  STYLE_DOT

input int     NumberOfBars = 1000;
input string  Note = "0 means Display all bars";
input int     MAPeriod = 100;
input int     LookBack = 20;

double Histogram[];
double HistogramColor[];
double Average[];

input bool    AlertClimaxBuyOn = false;
input bool    AlertClimaxSellOn = false;
input bool    AlertDemandClimaxBuyOn = false;
input bool    AlertSupplyClimaxSellOn = false;


double glOffset;
datetime LastAlertTime;
int LastCounted = 0;


//from SDRW indicator
// Buffers
//double D[], S[];

//   double spd1, spd2;
//   long v1, v2;
//   int limit;


// SetIndexBuffer(1, D, INDICATOR_DATA);
//	SetIndexBuffer(2, S, INDICATOR_DATA);

//   PlotIndexSetString(1, PLOT_LABEL, "Up");
//   PlotIndexSetString(2, PLOT_LABEL, "Down");

//   {
//      limit = rates_total - NumberOfBars;
//      if (limit < 2) limit = 2;
//   }
//   else limit = LastCalculated - 2;
      
//   for (int i = limit; i < rates_total; i++)   
//   {
//      spd1 = High[i - 1] - Low[i - 1];
//      spd2 = High[i - 2] - Low[i - 2];
      
//      R[i]=0; D[i]=0; S[i]=0; W[i]=0;
      
//      v1 = Tickvolume[i - 1];
//      v2 = Tickvolume[i - 2];

// if (spd1 > spd2)
//         else if (v1 > v2)
//         {
//            if (High[i - 1] - Close[i - 1] < Close[i - 1] - Low[i - 1])
//            {
//               D[i - 1] = Low[i - 1] - glOffset;
//               R[i - 1] = 0;

//               if ((AlertDemandOn) && (i == rates_total - 1) && (LastAlertTime != Time[rates_total - 1])) Alert("CDRW Demand");
//            }
//            else if (High[i - 1] - Close[i - 1] > Close[i - 1] - Low[i - 1])
//            {
//               S[i - 1] = High[i - 1] + glOffset;
//               R[i - 1] = 0;
               
//               if ((AlertSupplyOn) && (i == rates_total - 1) && (LastAlertTime != Time[rates_total - 1])) Alert("CDRW Supply");
//            }



//   PlotIndexSetInteger(1, PLOT_ARROW, 233);
//   PlotIndexSetInteger(2, PLOT_ARROW, 234);



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
	IndicatorSetString(INDICATOR_SHORTNAME, "BV(" + IntegerToString(MAPeriod) + ", " + IntegerToString(LookBack) + ")");
	
	SetIndexBuffer(0, Histogram, INDICATOR_DATA);
	SetIndexBuffer(1, HistogramColor, INDICATOR_COLOR_INDEX);
	SetIndexBuffer(2, Average, INDICATOR_DATA);
}

//+------------------------------------------------------------------+
//| CDRW                                                             |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tickvolume[],
                const long &TickvolumeX[],
                const int &spread[])
{
   double VolLowest, Range, Value2, Value3, HiValue2, HiValue3, LoValue3, tempv2, tempv3, tempv;
   int limit, n ,i;

   int minbars = MathMax(20, MathMax(MAPeriod, LookBack));

   limit = LastCounted - 1;
   if (NumberOfBars > 0) 
      if (rates_total - limit > NumberOfBars) limit = rates_total - NumberOfBars;

   if (limit < minbars) limit = minbars;
      
   for (i = rates_total - 1; i >= limit; i--)   
   {
      Histogram[i] = Tickvolume[i];
      HistogramColor[i] = 1;
      
      Value2 = 0; Value3 = 0; HiValue2 = 0; HiValue3 = 0; LoValue3 = DBL_MAX; tempv2 = 0; tempv3 = 0; tempv = 0;
      
      
      VolLowest = Tickvolume[ArrayMinimum(Tickvolume, i - 19, 20)];
      if (Tickvolume[i] == VolLowest)
         HistogramColor[i] = 2;
            
      Range = (High[i] - Low[i]);
      Value2 = Tickvolume[i] * Range;
      
      if (Range != 0) Value3 = Tickvolume[i] / Range;
         
      for (n = i; n > i - MAPeriod; n--)
      {
         tempv += Tickvolume[n];
      } 
      
      Average[i] = NormalizeDouble(tempv / MAPeriod, 0);
      
      for (n = i; n > i - LookBack; n--)
      {
         tempv2 = Tickvolume[n] * (High[n] - Low[n]); 
         if (tempv2 > HiValue2) HiValue2 = tempv2;
              
         if (Tickvolume[n] * (High[n] - Low[n]) != 0)
         {           
            tempv3 = Tickvolume[n] / (High[n] - Low[n]);
            if (tempv3 > HiValue3) HiValue3 = tempv3; 
            if (tempv3 < LoValue3) LoValue3 = tempv3;
         } 
      }
                                   
      if ((Value2 == HiValue2) && (Close[i] > (High[i] + Low[i]) / 2))
         HistogramColor[i] = 0;
        
      if (Value3 == HiValue3)
         HistogramColor[i] = 3;
      
      if ((Value2 == HiValue2) && (Value3 == HiValue3))
         HistogramColor[i] = 5;
      
      if ((Value2 == HiValue2)  && (Close[i] <= (High[i] + Low[i]) / 2))
         HistogramColor[i] = 4;
        
       //neeed to add this condition: condition for SDRW Demand and red bar from BV then to have alert:Alert("Demand Bar with Climax on ", Symbol(),"  ","M",Period() ); 
       //place arrow in volume indicator window
      if ((AlertDemandClimaxBuyOn) && (HistogramColor[i] ==0) && (i == rates_total - 1) && (LastAlertTime != Time[rates_total - 1])) Alert("Climaxbuy");
            
      //covers all other red bars:Alert("Buy Climax on ", Symbol(),"  ","M",Period() ); 
      //no need any symbol to mark this volume bars
      if ((AlertClimaxBuyOn) && (HistogramColor[i] ==0) && (i == rates_total - 1) && (LastAlertTime != Time[rates_total - 1])) Alert("Buy Climax on");
      
      //neeed to add this condition: condition for SDRW Demand and red bar from BV then to have alert:Alert("Demand Bar with Climax on ", Symbol(),"  ","M",Period() ); 
      //place arrow in volume indicator window
      if ((AlertSupplyClimaxSellOn) && (HistogramColor[i] == 3) && (i == rates_total - 1) && (LastAlertTime != Time[rates_total - 1])) Alert("Climaxsell");
      
      //covers all other white bars:Alert("Sell Climax on ", Symbol(),"  ","M",Period() ); 
      //no need any symbol to mark this volume bars
      if ((AlertClimaxSellOn) && (HistogramColor[i] ==0) && (i == rates_total - 1) && (LastAlertTime != Time[rates_total - 1])) Alert("Sell Climax on");
      
   }
      
   LastCounted = rates_total;
   return(rates_total);
}
//+------------------------------------------------------------------+
          