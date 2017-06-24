//+------------------------------------------------------------------+
//|                                               AutoTrendLines.mq5 |
//|                                            Copyright 2012, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Automatic trend lines.                                           |
//| Type 1. With two extremums.                                      |
//| 1) From the current bar "go" to the left and look for the first  |
//| (right) extremum point with the InpRightExmSide bars on both     |
//| sides.                                                           |
//| 2) From the first point again "go" to the left and look for the  |
//| second (left) extremum point with the InpLeftExmSide bars on     |
//| both sides.                                                      |
//| 3) Draw a trend lines.                                           |
//|                                                                  |
//| Type 2. With extremum and delta.                                 |
//| 1) From the current bar "go" to the left and look for the second |
//| (left) extremum point with the InpLeftExmSide bars on both sides.|
//| 2) Starting with the InpFromCurrent bar from the current bar and |
//| to the second extremum point find the bar with minimal delta.    |
//| 3) Draw a trend lines.                                           |
//|                                                                  |
//| NOTE:                                                            |
//| 1) The lines are recalculated only when a new bar appears        |
//| 2) The current unformed bar does not included in the calculations|
//| 3) The extremum means a bar, for which the left and right        |
//| N bars have minimums above and maximums                          |
//| below.                                                           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "Automatic trend lines"
//---
#property indicator_chart_window
//---
enum ENUM_LINE_TYPE {
   EXM_EXM,    // 1: By 2 extremums
   EXM_DELTA   // 2: Extremum and delta
};
//+------------------------------------------------------------------+
//| Class CPoint                                                     |
//+------------------------------------------------------------------+
class CPoint {
   private:
      double price;
      datetime time;
   public:
      CPoint();
      CPoint(const double p, const datetime t);
      ~CPoint() {};
      void setPoint(const double p, const datetime t);
      bool operator==(const CPoint &other) const;
      bool operator!=(const CPoint &other) const;
      void operator=(const CPoint &other);
      double getPrice() const;
      datetime getTime() const;
};
//---
CPoint::CPoint(void) {
   price = 0;
   time = 0;
}
//---
CPoint::CPoint(const double p, const datetime t) {
   price = p;
   time = t;
}
//---
void CPoint::setPoint(const double p, const datetime t) {
   price = p;
   time = t;
}
//---
bool CPoint::operator==(const CPoint &other) const {
   return price == other.price && time == other.time;
}
//---
bool CPoint::operator!=(const CPoint &other) const {
   return !operator==(other);
}
//---
void CPoint::operator=(const CPoint &other) {
   price = other.price;
   time = other.time;
}
//---
double CPoint::getPrice(void) const {
   return(price);
}
//---
datetime CPoint::getTime(void) const {
   return(time);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPoint curLeftSup, curRightSup, curLeftRes, curRightRes, nullPoint;
//+------------------------------------------------------------------+
//| input parameters                                                 |
//+------------------------------------------------------------------+
input ENUM_LINE_TYPE InpLineType = EXM_DELTA;// Line type
input int            InpLeftExmSide = 20;    // Left extremum side (Type 1, 2)
input int            InpRightExmSide = 3;    // Right extremum side (Type 1)
input int            InpFromCurrent = 3;     // Offset from the current barà (Type 2)
input bool           InpPrevExmBar = false;  // Account for the bar before the extremum (Type 2)
//---
input int            InpLinesWidth = 1;      // lines width
input color          InpSupColor = C'255,121,194';   // Support line color
input color          InpResColor = C'70,209,255';  // Resistance line color
input string         InstanceName = "AutoTrendLines1";  // Instance name
//--- global variables
int            minRequiredBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//---
   minRequiredBars = InpLeftExmSide * 2 + MathMax(InpRightExmSide, InpFromCurrent) * 2;
//--- indicator buffers mapping
   
//---
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   ObjectsDeleteAll(0, InstanceName);
//---
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
//---
   int leftIndex, rightIndex;
   double delta, tmpDelta;
   
//---
   if ( rates_total < minRequiredBars ) {
      Print("Not enough data to calculate");
      return(0);
   }
//---
   if ( prev_calculated != rates_total ) {
      switch ( InpLineType ) {
         case EXM_DELTA:
            //--- Support Left Point
            leftIndex = rates_total - InpLeftExmSide - 2;
            for ( ; !isLowestLow(leftIndex, InpLeftExmSide, low) && leftIndex > minRequiredBars; leftIndex-- );
            curLeftSup.setPoint(low[leftIndex], time[leftIndex]);
            //--- Support Right Point
            rightIndex = rates_total - InpFromCurrent - 2;
            delta = (low[rightIndex] - low[leftIndex]) / (rightIndex - leftIndex);
            if ( !InpPrevExmBar ) {
               leftIndex += 1;
            }
            for ( int tmpIndex = rightIndex - 1; tmpIndex > leftIndex; tmpIndex-- ) {
               tmpDelta = (low[tmpIndex] - curLeftSup.getPrice()) / (tmpIndex - leftIndex);
               if ( tmpDelta < delta ) {
                  delta = tmpDelta;
                  rightIndex = tmpIndex;
               }
            }
            curRightSup.setPoint(low[rightIndex], time[rightIndex]);

            //--- Resistance Left Point
            leftIndex = rates_total - InpLeftExmSide - 2;
            for ( ; !isHighestHigh(leftIndex, InpLeftExmSide, high) && leftIndex > minRequiredBars; leftIndex-- );
            curLeftRes.setPoint(high[leftIndex], time[leftIndex]);
            //--- Resistance Right Point
            rightIndex = rates_total - InpFromCurrent - 2;
            delta = (high[leftIndex] - high[rightIndex]) / (rightIndex - leftIndex);
            if ( !InpPrevExmBar ) {
               leftIndex += 1;
            }
            for ( int tmpIndex = rightIndex - 1; tmpIndex > leftIndex; tmpIndex-- ) {
               tmpDelta = (curLeftRes.getPrice() - high[tmpIndex]) / (tmpIndex - leftIndex);
               if ( tmpDelta < delta ) {
                  delta = tmpDelta;
                  rightIndex = tmpIndex;
               }
            }
            curRightRes.setPoint(high[rightIndex], time[rightIndex]);
            //---
            break;
            
         case EXM_EXM:
         default:
            //--- Support Right Point
            rightIndex = rates_total - InpRightExmSide - 2;
            for ( ; !isLowestLow(rightIndex, InpRightExmSide, low) && rightIndex > minRequiredBars; rightIndex-- );
            curRightSup.setPoint(low[rightIndex], time[rightIndex]);
            //--- Support Left Point
            leftIndex = rightIndex - InpRightExmSide;
            for ( ; !isLowestLow(leftIndex, InpLeftExmSide, low) && leftIndex > minRequiredBars; leftIndex-- );
            curLeftSup.setPoint(low[leftIndex], time[leftIndex]);

            //--- Resistance Right Point
            rightIndex = rates_total - InpRightExmSide - 2;
            for ( ; !isHighestHigh(rightIndex, InpRightExmSide, high) && rightIndex > minRequiredBars; rightIndex-- );
            curRightRes.setPoint(high[rightIndex], time[rightIndex]);
            //--- Resistance Left Point
            leftIndex = rightIndex - InpRightExmSide;
            for ( ; !isHighestHigh(leftIndex, InpLeftExmSide, high) && leftIndex > minRequiredBars; leftIndex-- );
            curLeftRes.setPoint(high[leftIndex], time[leftIndex]);
            //---
            break;
      }
      //--- Draw Support & Resistance
      if ( curLeftSup != nullPoint && curRightSup != nullPoint ) {
         drawLine("Current_Support", curRightSup, curLeftSup, InpSupColor);
      }
      if ( curLeftRes != nullPoint && curRightRes != nullPoint ) {
         drawLine("Current_Resistance", curRightRes, curLeftRes, InpResColor);
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}


//+------------------------------------------------------------------+
//| The Local Low search function                                    |
//+------------------------------------------------------------------+
bool isLowestLow(int bar, int side, const double &Low[]) {
//---
   for ( int i = 1; i <= side; i++ ) {
      if ( Low[bar] > Low[bar-i] || Low[bar] > Low[bar+i] ) {
         return(false);
      }
   }
//---
   return(true);
}
//+------------------------------------------------------------------+
//| The Local High search function                                   |
//+------------------------------------------------------------------+
bool isHighestHigh(int bar, int side, const double &High[]) {
//---
   for ( int i = 1; i <= side; i++ ) {
      if ( High[bar] < High[bar-i] || High[bar] < High[bar+i] ) {
         return(false);
      }
   }
//---
   return(true);
}
//+------------------------------------------------------------------+
//| Draw trend line function                                         |
//+------------------------------------------------------------------+
void drawLine(string name, CPoint &right, CPoint &left, color clr) {

   name = InstanceName + "-" + name;
   ObjectDelete(0, name);

   ObjectCreate(0, name, OBJ_TREND, 0, right.getTime(), right.getPrice(), left.getTime(), left.getPrice());
   ObjectSetInteger(0, name, OBJPROP_WIDTH, InpLinesWidth);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
//---
}
//+------------------------------------------------------------------+
