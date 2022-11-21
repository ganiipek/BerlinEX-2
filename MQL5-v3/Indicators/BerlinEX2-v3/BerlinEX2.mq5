//+------------------------------------------------------------------+
//|                                                           BB.mq5 |
//|                   Copyright 2009-2020, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009-2020, 24 Capital Management"
#property link        "https://24capitalmanagement.com/"
#property description "BerlinEX 2"
//---
#property indicator_separate_window

#property indicator_buffers 7
#property indicator_plots   1

#property indicator_label1  "BerlinEX2-Signal"
#property indicator_level1  1
#property indicator_type1   DRAW_COLOR_ARROW
#property indicator_style1  STYLE_DOT
#property indicator_width1  3

#resource "\\Indicators\\BerlinEX2-v3\\HeikanAshi EMA.ex5"

input ENUM_TIMEFRAMES         input_heiken_ashi_slow_ema_time_frame           = PERIOD_M1;         // Heikin Ashi Slow EMA Time Frame
input int                     input_heiken_ashi_slow_ema_time_frame_shift     = 0;                 // Heikin Ashi Slow EMA Time Frame Shift
input int                     input_heiken_ashi_slow_ema_period               = 30;                // Heikin Ashi Slow EMA Period

input ENUM_TIMEFRAMES         input_heiken_ashi_fast_ema_time_frame           = PERIOD_H1;         // Heikin Ashi Fast EMA Time Frame
input int                     input_heiken_ashi_fast_ema_time_frame_shift     = 0;                 // Heikin Ashi Fast EMA Time Frame Shift
input int                     input_heiken_ashi_fast_ema_period               = 1;                 // Heikin Ashi Fast EMA Period

input group                "[Color Settings]"
input color BarColorUp     = clrGreen; // 0 => long
input color BarColorDown   = clrRed;   // 1 => short
input color TextColor      = clrWhite; 

int            indicator_handle_slow_ema;
int            indicator_handle_fast_ema;

double         indicator_buffer_data_slow_ema[];
double         indicator_buffer_data_fast_ema[];

double         indicator_buffer_trade[];
double         indicator_buffer_color[];

datetime       reverse_time[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   ArraySetAsSeries(indicator_buffer_data_slow_ema, true);
   ArraySetAsSeries(indicator_buffer_data_fast_ema, true);
   
   ArraySetAsSeries(indicator_buffer_trade, true);
   ArraySetAsSeries(indicator_buffer_color, true);
   
   ArraySetAsSeries(reverse_time, true);
   
   indicator_handle_slow_ema = iCustom(_Symbol, input_heiken_ashi_slow_ema_time_frame, "\\Indicators\\BerlinEX2-v3\\HeikanAshi EMA.ex5", input_heiken_ashi_slow_ema_time_frame_shift, input_heiken_ashi_slow_ema_period);
   if(indicator_handle_slow_ema == INVALID_HANDLE)
   {
      PrintFormat("Failed to create handle of the Heikan Ashi Slow EMA indicator for the symbol %s/%s, error code %d",
         _Symbol,
         EnumToString(input_heiken_ashi_slow_ema_time_frame),
         GetLastError()
      );
      return INIT_FAILED;
   }
   
   indicator_handle_fast_ema = iCustom(_Symbol, input_heiken_ashi_fast_ema_time_frame, "\\Indicators\\BerlinEX2-v3\\HeikanAshi EMA.ex5", input_heiken_ashi_fast_ema_time_frame_shift, input_heiken_ashi_fast_ema_period);
   if(indicator_handle_fast_ema == INVALID_HANDLE)
   {
      PrintFormat("Failed to create handle of the Heikan Ashi Fast EMA indicator for the symbol %s/%s, error code %d",
         _Symbol,
         EnumToString(input_heiken_ashi_fast_ema_time_frame),
         GetLastError()
      );
      return INIT_FAILED;
   }
   
   SetIndexBuffer(0, indicator_buffer_trade,  INDICATOR_DATA);
   SetIndexBuffer(1, indicator_buffer_color,  INDICATOR_COLOR_INDEX);
   
   PlotIndexSetInteger(0, PLOT_COLOR_INDEXES, 2);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, BarColorUp);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, BarColorDown);
   
   return INIT_SUCCEEDED;
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
   int to_copy = rates_total - prev_calculated;
   
   if(rates_total > prev_calculated)
   {
      ArrayCopy(reverse_time, Time);
      if(!FillBuffer(reverse_time, to_copy)) return(0);
   }
   return(rates_total);
}

bool FillBuffer(datetime &time[], int amount)
{
   ResetLastError();
   
   int slow_ema_bars_count = BarsCalculated(indicator_handle_slow_ema);
   int fast_ema_bars_count = BarsCalculated(indicator_handle_fast_ema);
   
   for(int i=0; i<amount; i++)
   {
      if(i >= slow_ema_bars_count || i >= fast_ema_bars_count) break;
      
      double slow_ema[1];
      double fast_ema[1];      
      
      if(CopyBuffer(indicator_handle_slow_ema, 0, time[i], 1, slow_ema) < 0)
      {
         PrintFormat("Failed to copy data from the Slow Ema indicator, error code %d",GetLastError());
         return(false);
      }
      
      if(CopyBuffer(indicator_handle_fast_ema, 0, time[i], 1, fast_ema) < 0)
      {
         PrintFormat("Failed to copy data from the Fast Ema indicator, error code %d",GetLastError());
         return(false);
      }
      
      indicator_buffer_trade[i] = 2;
      indicator_buffer_color[i] = 1;
   
      if(fast_ema[0] > slow_ema[0]) indicator_buffer_color[i] = 0;
   }
   
   return(true);
}