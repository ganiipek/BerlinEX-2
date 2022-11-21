//+------------------------------------------------------------------+
//|                                                           BB.mq5 |
//|                   Copyright 2009-2020, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009-2020, 24 Capital Management"
#property link        "https://24capitalmanagement.com/"
#property description "Heiken Ashi EMA"
//---
// #property indicator_separate_window
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_label1  "Heiken Ashi EMA"

input int                     input_heiken_ashi_ema_time_frame_shift       = 1;                 // Heikin Ashi EMA Time Frame Shift
input int                     input_heiken_ashi_ema_period                 = 30;                 // Heikin Ashi EMA Period
input color                   input_heiken_ashi_ema_line_color             = C'52, 146, 235';   // Heikin Ashi EMA Line Color

double buffer_ha_close[];
double buffer_ema[];

double reverse_open[];
double reverse_high[];
double reverse_low[];
double reverse_close[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
   ArraySetAsSeries(buffer_ha_close, true);
   ArraySetAsSeries(buffer_ema, true);
   
   ArraySetAsSeries(reverse_open, true);
   ArraySetAsSeries(reverse_high, true);
   ArraySetAsSeries(reverse_low, true);
   ArraySetAsSeries(reverse_close, true);
   
   //--- indicator buffers mapping
   SetIndexBuffer(0,buffer_ema,INDICATOR_DATA);
   SetIndexBuffer(1,buffer_ha_close,INDICATOR_DATA);
   
   //--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,input_heiken_ashi_ema_period + input_heiken_ashi_ema_time_frame_shift);
   
   PlotIndexSetInteger(0, PLOT_COLOR_INDEXES, 1);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, input_heiken_ashi_ema_line_color);
}

void OnDeinit(const int reason)
{

}
  
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   //--- check for insufficient data
   if(rates_total < input_heiken_ashi_ema_period +  1)
   {
      Print("Error: not enough bars in history!");
      return(0);
   }

   int to_copy = rates_total - prev_calculated;
   
   ArrayCopy(reverse_open, Open);
   ArrayCopy(reverse_high, High);
   ArrayCopy(reverse_low, Low);
   ArrayCopy(reverse_close, Close);
   
   GetHeikanAshiClose(reverse_open, reverse_high, reverse_low, reverse_close, to_copy);
   CalculateEMA(input_heiken_ashi_ema_period, to_copy, input_heiken_ashi_ema_time_frame_shift);

   return(rates_total);
}

void GetHeikanAshiClose(const double &opens[], const double &highs[], const double &lows[], const double &closes[], int count)
{  
   for(int i=0; i < count; i++)
   {
      buffer_ha_close[i] = (opens[i]+highs[i]+lows[i]+closes[i]) / 4;
   }
}

void CalculateEMA(int period, int count, int shift) 
{
   double e_close;
   for(int a=0; a < count; a++)
   {
      e_close = 0;
      for(int b=0; b < period; b++)
      {
         if(a+b+shift < ArraySize(buffer_ha_close))
         {
            e_close += buffer_ha_close[a+b+shift];
         }
      }//loop b
      buffer_ema[a]= e_close / period;
   }//loop a
}