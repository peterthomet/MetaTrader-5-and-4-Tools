//+------------------------------------------------------------------+
//|                                          Support and Resistance  |
//|                                  Copyright © 2004 Barry Stander  |
//|                           Arrows added by Lennoi Anderson, 2015  |
//| MQL4 to MQL5 Migration by Peter Thomet, www.getyournet.ch, 2017  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2004 Barry Stander; Arrow alerts by Lennoi Anderson, 2015; MQL4 to MQL5 Migration by Peter Thomet, www.getyournet.ch, 2017."
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots 4
#property indicator_type1 DRAW_ARROW
#property indicator_color1 Red
#property indicator_width1 1
#property indicator_type2 DRAW_ARROW
#property indicator_color2 Green
#property indicator_width2 1
#property indicator_type3 DRAW_ARROW
#property indicator_color3 Green
#property indicator_width3 1
#property indicator_type4 DRAW_ARROW
#property indicator_color4 Red
#property indicator_width4 1

input int RSIPeriod = 14; //RSI Period
input double RSIOverbought = 70; //RSI Overbought
input double RSIOversold = 30; //RSI Oversold
input int CCIPeriod = 14; //CCI Period
input double CCIBuyLevel = 50; //CCI Buy Level 
input double CCISellLevel = -50; //CCI Sell Level
input bool Alerts = true; //Alerts
input bool ApplyToClose = true; //Apply To Close

bool HighBreakout = false;
bool HighBreakPending = false;
bool LowBreakout = false;
bool LowBreakPending = false; 
double LastResistance = 0;
double LastSupport = 0;
double AlertBar;
int AlertCandle = 0;

double v1[];
double v2[];
double BreakUp[];
double BreakDown[];
double val1;
double val2;
int counter1;
int counter2;
int StartBars;
int FRA_Handle;
int CCI_Handle;
int RSI_Handle;


void OnInit()
{
   StartBars=6;

   if(ApplyToClose)
      AlertCandle = 1;
   // Override ApplyToClose, otherwise this doesn't works in MT5
   //AlertCandle = 0;

   FRA_Handle = iFractals(NULL, 0);
   CCI_Handle = iCCI(NULL, 0, CCIPeriod, PRICE_CLOSE);
   RSI_Handle = iRSI(NULL, 0, RSIPeriod, PRICE_CLOSE);

   SetIndexBuffer(0, v1, INDICATOR_DATA);
   PlotIndexSetInteger(0 ,PLOT_ARROW, 158);
   PlotIndexSetString(0, PLOT_LABEL, "Resistance");
   SetIndexBuffer(1, v2, INDICATOR_DATA);
   PlotIndexSetInteger(1, PLOT_ARROW, 158);
   PlotIndexSetString(1, PLOT_LABEL, "Support");
   SetIndexBuffer(2, BreakUp, INDICATOR_DATA);
   PlotIndexSetInteger(2, PLOT_ARROW, 233);
   SetIndexBuffer(3, BreakDown, INDICATOR_DATA);
   PlotIndexSetInteger(3, PLOT_ARROW, 234);
   ArraySetAsSeries(v1, true);
   ArraySetAsSeries(v2, true);
   ArraySetAsSeries(BreakUp, true);
   ArraySetAsSeries(BreakDown, true);
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
   int to_copy, limit,bar;
   double FRAUp[], FRALo[], CCI[], RSI[];

   if(rates_total < StartBars)
      return(0);
   if(BarsCalculated(FRA_Handle) < rates_total)
      return(0);
   if(BarsCalculated(CCI_Handle) < rates_total)
      return(0);
   if(BarsCalculated(RSI_Handle) < rates_total)
      return(0);

   if(prev_calculated > rates_total || prev_calculated <= 0)
   {
      to_copy = rates_total;
      limit = rates_total - StartBars - 1;
      ArrayInitialize(v1, EMPTY_VALUE);
      ArrayInitialize(v2, EMPTY_VALUE);
      ArrayInitialize(BreakUp, EMPTY_VALUE);
      ArrayInitialize(BreakDown, EMPTY_VALUE);
   }
   else
   {
      to_copy = rates_total - prev_calculated + 3;
      limit = rates_total - prev_calculated + 2;
   }

   ArraySetAsSeries(FRAUp,true);
   ArraySetAsSeries(FRALo,true);
   ArraySetAsSeries(CCI,true);
   ArraySetAsSeries(RSI,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

   if(CopyBuffer(FRA_Handle, 0, 0, to_copy, FRAUp) <= 0)
      return(0);
   if(CopyBuffer(FRA_Handle, 1, 0, to_copy, FRALo) <= 0)
      return(0);
   if(CopyBuffer(CCI_Handle, 0, 0, to_copy, CCI) <= 0)
      return(0);
   if(CopyBuffer(RSI_Handle, 0, 0, to_copy, RSI) <= 0)
      return(0);

   for(bar = limit; bar >= 0; bar--)
   {
      if(FRAUp[bar] != DBL_MAX)
         v1[bar] = high[bar];
      else
         v1[bar] = v1[bar+1];

      if(FRALo[bar] != DBL_MAX)
         v2[bar] = low[bar];
      else
         v2[bar] = v2[bar+1];

      if(v1[bar] != LastResistance)
      {
         HighBreakPending = true;
         LastResistance = v1[bar];
      }

      if(v2[bar] != LastSupport)
      {
         LowBreakPending = true;
         LastSupport = v2[bar];
      }

      if(HighBreakPending && close[bar] > v1[bar] && RSI[bar] < RSIOverbought && CCI[bar] > CCIBuyLevel)
         HighBreakout = true;
      if(LowBreakPending && close[bar] < v2[bar] && RSI[bar] > RSIOversold && CCI[bar] < CCISellLevel)
         LowBreakout = true;

      if (HighBreakout)
      {
         if (bar >= AlertCandle) BreakUp[bar] = low[bar] - (10 * _Point);
         if (Alerts && bar == AlertCandle && rates_total > AlertBar)
         {
            Alert(Symbol(), " M", Period(), " Resistance Breakout: BUY");
            AlertBar = rates_total;
         }
         HighBreakout = false;
         HighBreakPending = false;
       }
       else
       {
          if (LowBreakout)
          {
            if (bar >= AlertCandle) BreakDown[bar] = high[bar] + (10 * _Point);
            if (Alerts && bar == AlertCandle && rates_total > AlertBar)
            {
               Alert(Symbol(), " M", Period(), " Support Breakout: SELL");
               AlertBar = rates_total;
            }
            LowBreakout = false;
            LowBreakPending = false;
          }
       }

   }
   
   return(rates_total);
}
