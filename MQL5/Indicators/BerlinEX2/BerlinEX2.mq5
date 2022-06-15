//+------------------------------------------------------------------+
//|                                                           BB.mq5 |
//|                   Copyright 2009-2020, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009-2020, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "BerlinEX 2"
//---
// #property indicator_separate_window
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  C'52, 146, 235'
#property indicator_label1  "EMA"
#property tester_indicator "BerlinEX2.ex5"


#include <BerlinEX2/Others.mqh>

input ENUM_TIMEFRAMES         input_heiken_ashi_ema_time_frame             = PERIOD_H1;         // Heikin Ashi EMA Time Frame
input int                     input_heiken_ashi_ema_time_frame_shift       = 0;                 // Heikin Ashi EMA Time Frame Shift
input int                     input_heiken_ashi_ema_period                 = 1;                 // Heikin Ashi EMA Period
input color                   input_heiken_ashi_ema_line_color             = C'52, 146, 235';   // Heikin Ashi EMA Line Color
input string                  input_heiken_ashi_ema_line_name              = "B.O.S_EMA";       // Heikin Ashi EMA Line Name

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
   Calculate();
}

void OnDeinit(const int reason)
{
  ObjectsDeleteAll(ChartID(), input_heiken_ashi_ema_line_name);
}
  
int  OnCalculate(
   const int        rates_total,       // price[] array size
   const int        prev_calculated,   // number of handled bars at the previous call
   const int        begin,             // index number in the price[] array meaningful data starts from
   const double&    price[]            // array of values for calculation
   )
{
   if (IsNewCandle())
   {
      Calculate();
   }
   return(rates_total);
}

void GetHeikanAshiClose(ENUM_TIMEFRAMES timeframe, int count, int shift, double &ha_close[])
{
   // shift += 1;
   double highs[];
   CopyHigh(_Symbol, timeframe, shift, count, highs);
   double lows[];
   CopyLow(_Symbol, timeframe, shift, count, lows);
   double opens[];
   CopyOpen(_Symbol, timeframe, shift, count, opens);
   double closes[];
   CopyClose(_Symbol, timeframe, shift, count, closes);
   datetime times[];
   CopyTime(_Symbol, timeframe, shift, count, times);
   ArrayReverse(times, 0, WHOLE_ARRAY);
   
   ArrayResize(ha_close, count);
   
   
   for(int i=0; i < ArraySize(highs); i++)
   {
      ha_close[i] = (opens[i]+highs[i]+lows[i]+closes[i]) / 4;
      /*
      PrintFormat("[%s] Heikan Ashi Close: %s",
        TimeToString(times[i]),
         DoubleToString(ha_close[i], _Digits)
      );
      */
   }
   
   
   ArrayReverse(ha_close, 0, WHOLE_ARRAY);
}

void CalculateEMA(double &close[], int period, int limit, double &ema_close[]) 
{
   ArrayResize(ema_close, limit);
   
   double e_close;
   for(int a=limit-1; a >= 0; a--)
   {
      e_close = 0;
      
      for(int b=0; b < period; b++){
         e_close += close[a+b];
      }//loop b
      ema_close[a]= e_close / period;
   }//loop a
}

void Calculate()
{
   double ha_close[];
   GetHeikanAshiClose(input_heiken_ashi_ema_time_frame, 100, input_heiken_ashi_ema_time_frame_shift, ha_close);
   
   double ema_close[];
   CalculateEMA(ha_close, input_heiken_ashi_ema_period, 1, ema_close);

   for(int i=0; i<ArraySize(ema_close); i++)
   {
      datetime start_time = TimeCurrent();
      datetime end_time = TimeCurrent();
      
      if(i==0)
      {
         start_time  = TimeCurrent();
         end_time    = iTime(Symbol(), input_heiken_ashi_ema_time_frame, i);
      }
      else
      {
         start_time  = iTime(Symbol(), input_heiken_ashi_ema_time_frame, i-1);
         end_time    = iTime(Symbol(), input_heiken_ashi_ema_time_frame, i);
      }
      
      string trend_name = input_heiken_ashi_ema_line_name + "_" + TimeToString(start_time);
      TrendCreate(ChartID(), trend_name + IntegerToString(i), start_time, ema_close[i], end_time, ema_close[i], input_heiken_ashi_ema_line_color, 3);
      /*
      PrintFormat("[%s <-> %s] EMA: %s",
         TimeToString(start_time),
         TimeToString(end_time),
         DoubleToString(ema_close[i], _Digits)
      );*/
   }
   ChartRedraw();
}

