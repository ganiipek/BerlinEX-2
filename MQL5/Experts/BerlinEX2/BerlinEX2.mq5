#include <Trade/Trade.mqh>
#include <BerlinEX2/BoxManager.mqh>
#include <BerlinEX2/StepManager.mqh>
#include <BerlinEX2/PositionManager.mqh>

#define VERSION "1.0"
#property copyright "© Copyright 2022"
#property link      "https://www.24capitalmanagement.com"
#property version   VERSION
#property description "Automated Trade by Makinaaaa Gani"
#property strict

#include <BerlinEX2/Dictionary.mqh>

CDictionary *dict_step = new CDictionary();
int step_list[];

CDictionary *dict_hedge_step = new CDictionary();
int step_hedge_list[];

CDictionary *dict_stop_step = new CDictionary();
int step_stop_list[];
// #resource "\\Indicators\\BerlinEX2\\BerlinEX2.ex5"

enum ENUM_PROGRAM_BREAKOUT_TYPE
{
   PROGRAM_BREAKOUT_TRADE_WAITING,        // TRADE WATING
   PROGRAM_BREAKOUT_LIMIT_BOARDING,       // LIMIT BOARDING
   PROGRAM_BREAKOUT_OPEN_BUY,             // TRADE BUY
   PROGRAM_BREAKOUT_OPEN_SELL,            // TRADE SELL
   PROGRAM_BREAKOUT_TRADE_HEDGING,        // TRADE HEDGING
   PROGRAM_BREAKOUT_TRADE_HEDGED,         // TRADE HEDGED
   PROGRAM_BREAKOUT_TRADE_HEDGED_EXIT,    // TRADE HEDGED EXIT
   PROGRAM_BREAKOUT_TRADE_CLOSING         // TRADE CLOSING
};

enum ENUM_TRADE_HOUR_STRATEGY
{
   TRADE_HOUR_STRATEGY_NONE,                                   // None
   TRADE_HOUR_STRATEGY_HEDGED_AND_WAIT_SIGNAL,                 // Hedged and wait signal
   TRADE_HOUR_STRATEGY_HEDGED_AND_OPEN_BOX_CURRENT_PRICE,      // Hedged and open box current price
   TRADE_HOUR_STRATEGY_HEDGED_AND_OPEN_BOX_BY_TRADE_LAST_BOX   // Hedged and open box by last trade box
};

enum ENUM_HEDGE_MODE
{
   HEDGE_MODE_HALF,                                         // Half
   HEDGE_MODE_FULL                                          // Full
};


input string                     input_non_trade_days_directory_name          = "date_value.rtf";  // Non Trade Days Directory Name

input group                         "[STRATEGY SETTINGS]"
input ENUM_TIMEFRAMES         input_heiken_ashi_ema_time_frame             = PERIOD_H1;      // Heikin Ashi EMA Time Frame
input int                     input_heiken_ashi_ema_time_frame_shift       = 0;              // Heikin Ashi EMA Time Frame Shift
input int                     input_heiken_ashi_ema_period                 = 1;              // Heikin Ashi EMA Period
input color                   input_heiken_ashi_ema_line_color             = C'52, 146, 235';// Heikin Ashi EMA Line Color

input ENUM_TIMEFRAMES         input_heiken_ashi_slow_ema_time_frame        = PERIOD_H1;      // Heikin Ashi Slow EMA Time Frame
input int                     input_heiken_ashi_slow_ema_time_frame_shift  = 0;              // Heikin Ashi Slow EMA Time Frame Shift
input int                     input_heiken_ashi_slow_ema_period            = 30;             // Heikin Ashi Slow EMA Period
input color                   input_heiken_ashi_slow_ema_line_color        = C'245, 164, 66';// Heikin Ashi Slow EMA Line Color

input group                         "[TRAILING STOP LOSS]"
input string     category_settings2          = "";       // <----- TRAILING STOP LOSS ------->
input bool       input_tsl_active            = true;     // TSL Active
input double     input_tsl_activation_profit = 5;        // TSL Activation Profit
input double     input_tsl_follow_profit     = 1;        // TSL Follow Profit
input bool       input_tsl_increment         = true;     // TSL Increment by Lot 
input bool       input_stop_loss_active      = false;    // Stop Loss Active
input double     input_stop_loss_value       = 1000;     // Stop Loss Value

input group   "[CUSTOM BOX SETTINGS]"
input color   box_normal_line_color = C'245, 141, 66'; // Custom Box Line Color
input color   box_normal_box_color = C'255, 202, 163'; // Custom Box Box Color
input color   box_normal_text_color = C'247, 107, 5'; // Custom Box Text Color

double   tick_sma[2];
double   tick_ema[2];

double   tsl_last_profit   = 0;
bool     tsl               = false;

int      count_more_than_one_step       = 0;
bool     last_step_was_more_than_one    = false;

datetime today_date = NULL;
bool non_trade_day = false;
// string non_trade_days_string = "2014/01/08|2014/01/09|2014/01/10|2014/01/21|2014/01/29|2014/02/06|2014/02/07|2014/02/18|2014/02/19|2014/03/06|2014/03/07|2014/03/18|2014/03/19|2014/04/03|2014/04/04|2014/04/09|2014/04/15|2014/04/30|2014/05/02|2014/05/08|2014/05/13|2014/05/21|2014/06/05|2014/06/06|2014/06/17|2014/06/18|2014/07/03|2014/07/09|2014/07/15|2014/07/30|2014/08/01|2014/08/07|2014/08/12|2014/08/20|2014/09/04|2014/09/05|2014/09/16|2014/09/17|2014/10/02|2014/10/03|2014/10/08|2014/10/14|2014/10/29|2014/11/06|2014/11/07|2014/11/18|2014/11/19|2014/12/04|2014/12/05|2014/12/16|2014/12/17|2015/01/07|2015/01/09|2015/01/20|2015/01/22|2015/01/28|2015/02/06|2015/02/17|2015/02/18|2015/03/05|2015/03/06|2015/03/17|2015/03/18|2015/04/03|2015/04/08|2015/04/15|2015/04/21|2015/04/29|2015/05/08|2015/05/19|2015/05/20|2015/06/03|2015/06/05|2015/06/16|2015/06/17|2015/07/02|2015/07/08|2015/07/14|2015/07/16|2015/07/29|2015/08/07|2015/08/11|2015/08/19|2015/09/03|2015/09/04|2015/09/15|2015/09/17|2015/10/02|2015/10/08|2015/10/13|2015/10/22|2015/10/28|2015/11/06|2015/11/17|2015/11/18|2015/12/03|2015/12/04|2015/12/15|2015/12/16|2016/01/06|2016/01/08|2016/01/19|2016/01/21|2016/01/27|2016/02/05|2016/02/16|2016/02/17|2016/03/04|2016/03/10|2016/03/16|2016/03/22|2016/04/01|2016/04/06|2016/04/19|2016/04/21|2016/04/27|2016/05/06|2016/05/18|2016/05/24|2016/06/02|2016/06/03|2016/06/15|2016/06/21|2016/07/06|2016/07/08|2016/07/19|2016/07/21|2016/07/27|2016/08/05|2016/08/16|2016/08/17|2016/09/02|2016/09/08|2016/09/13|2016/09/21|2016/10/07|2016/10/11|2016/10/12|2016/10/20|2016/11/02|2016/11/04|2016/11/15|2016/11/23|2016/12/02|2016/12/08|2016/12/13|2016/12/14|2017/01/04|2017/01/06|2017/01/17|2017/01/19|2017/02/01|2017/02/03|2017/02/14|2017/02/22|2017/03/09|2017/03/10|2017/03/14|2017/03/15|2017/04/05|2017/04/07|2017/04/11|2017/04/27|2017/05/03|2017/05/05|2017/05/16|2017/05/24|2017/06/02|2017/06/08|2017/06/13|2017/06/14|2017/07/05|2017/07/07|2017/07/18|2017/07/20|2017/07/26|2017/08/04|2017/08/16|2017/08/22|2017/09/01|2017/09/07|2017/09/19|2017/09/20|2017/10/06|2017/10/11|2017/10/17|2017/10/26|2017/11/01|2017/11/03|2017/11/14|2017/11/22|2017/12/08|2017/12/12|2017/12/13|2017/12/14|2018/01/03|2018/01/05|2018/01/23|2018/01/25|2018/01/31|2018/02/02|2018/02/20|2018/02/21|2018/03/08|2018/03/09|2018/03/20|2018/03/21|2018/04/06|2018/04/11|2018/04/17|2018/04/26|2018/05/02|2018/05/04|2018/05/15|2018/05/23|2018/06/01|2018/06/12|2018/06/13|2018/06/14|2018/07/05|2018/07/06|2018/07/10|2018/07/26|2018/08/01|2018/08/03|2018/08/14|2018/08/22|2018/09/07|2018/09/11|2018/09/13|2018/09/26|2018/10/05|2018/10/16|2018/10/17|2018/10/25|2018/11/02|2018/11/08|2018/11/13|2018/11/29|2018/12/07|2018/12/11|2018/12/13|2018/12/19|2019/01/04|2019/01/09|2019/01/22|2019/01/24|2019/01/30|2019/02/01|2019/02/19|2019/02/20|2019/03/07|2019/03/08|2019/03/19|2019/03/20|2019/04/05|2019/04/10|2019/04/16|2019/05/01|2019/05/03|2019/05/14|2019/05/22|2019/06/06|2019/06/07|2019/06/18|2019/06/19|2019/07/05|2019/07/10|2019/07/16|2019/07/25|2019/07/31|2019/08/02|2019/08/13|2019/08/21|2019/09/06|2019/09/12|2019/09/17|2019/09/18|2019/10/04|2019/10/09|2019/10/15|2019/10/24|2019/10/30|2019/11/01|2019/11/12|2019/11/20|2019/12/06|2019/12/10|2019/12/11|2019/12/12|2020/01/03|2020/01/10|2020/01/21|2020/01/23|2020/01/29|2020/02/07|2020/02/18|2020/02/19|2020/03/03|2020/03/06|2020/03/12|2020/03/15|2020/03/17|2020/04/03|2020/04/08|2020/04/21|2020/04/29|2020/04/30|2020/05/08|2020/05/19|2020/05/20|2020/06/04|2020/06/05|2020/06/10|2020/06/16|2020/07/01|2020/07/02|2020/07/14|2020/07/16|2020/07/29|2020/08/07|2020/08/11|2020/08/19|2020/09/04|2020/09/10|2020/09/15|2020/09/16|2020/10/02|2020/10/07|2020/10/13|2020/10/29|2020/11/05|2020/11/06|2020/11/10|2020/11/25|2020/12/04|2020/12/08|2020/12/10|2020/12/16|2021/01/06|2021/01/08|2021/01/19|2021/01/21|2021/01/27|2021/02/05|2021/02/16|2021/02/17|2021/03/05|2021/03/11|2021/03/16|2021/03/17|2021/04/02|2021/04/07|2021/04/13|2021/04/22|2021/09/13|2021/09/15";
string non_trade_days_string ="";
datetime non_trade_days_list[];


class BreakoutManager
{
   ENUM_PROGRAM_BREAKOUT_TYPE program_breakout_type;
   int                        current_step;
   double                     historical_profit;

   public:
      BreakoutManager()
      {
         program_breakout_type   = PROGRAM_BREAKOUT_TRADE_WAITING;
         current_step            = 0;
         historical_profit       = 0;
      }

      ENUM_PROGRAM_BREAKOUT_TYPE getProgramBreakoutType()
      {
         return program_breakout_type;
      }

      int getCurrentStep()
      {
         return current_step;
      }

      double getHistoricalProfit()
      {
         return historical_profit;
      }

      void setProgramBreakoutType(ENUM_PROGRAM_BREAKOUT_TYPE _program_breakout_type)
      {
         program_breakout_type = _program_breakout_type;
         updateGraphicBreakoutType();
      }

      void setCurrentStep(int _current_step)
      {
         current_step = _current_step;
         updateGraphicCurrentStep();

         if(input_debug)
         {
            PrintFormat("[%s-%s] breakoutManager (setCurrentStep) --> %s",
               _Symbol,
               IntegerToString(input_magic_number),
               IntegerToString(_current_step)
            );
         }
      }

      void setHistoricalProfit(double _profit)
      {
         historical_profit = _profit;
         updateGraphicHistoricalProfit();
      }

      void closeAll()
      {
         program_breakout_type = PROGRAM_BREAKOUT_TRADE_CLOSING;
         positionManager.closeAll();
         box_normal.deleteBox();

         if(input_debug)
         {
            PrintFormat("[%s-%s] breakoutManager (closeAll)",
               _Symbol,
               IntegerToString(input_magic_number)
            );
         }
      }

      void updateGraphicBreakoutType()
      {
         if(input_show_interface) LabelTextChange(ChartID(), "Berlinex2_breakout_type", "Breakout: " + EnumToString(program_breakout_type));
      }

      void updateGraphicCurrentStep()
      {
         if(input_show_interface) LabelTextChange(ChartID(), "Berlinex2_current_step", "Step: " + IntegerToString(current_step));
      }

      void updateGraphicHistoricalProfit()
      {
         if(input_show_interface) LabelTextChange(ChartID(), "Berlinex2_historical_profit", "Historical Profit: " + DoubleToString(historical_profit, 2) + " $");
      }

      void updateGraphicProfit(double profit)
      {
         if(input_show_interface) LabelTextChange(ChartID(), "Berlinex2_profit", "Profit: " + DoubleToString(profit, 2) + " $");
      }

      void OnInit()
      {
         if(input_show_interface)
         {
            LabelCreate(ChartID(), "Berlinex2_breakout_type",        4,  48, "Breakout: ", 9, C'248, 248, 248');
            LabelCreate(ChartID(), "Berlinex2_current_step",         4,  35, "Step: 0", 9, C'248, 248, 248');
            LabelCreate(ChartID(), "Berlinex2_historical_profit",    4,  22, "Historical Profit: 0 $", 9, C'248, 248, 248');
            LabelCreate(ChartID(), "Berlinex2_profit",               4,  9,  "Profit: 0 $", 9, C'248, 248, 248');
         }
      }

      void OnDeinit()
      {
         ObjectDelete(ChartID(), "Berlinex2_breakout_type");
         ObjectDelete(ChartID(), "Berlinex2_current_step");
         ObjectDelete(ChartID(), "Berlinex2_historical_profit");
         ObjectDelete(ChartID(), "Berlinex2_profit");
      }

      void OnTick()
      {
         updateGraphicProfit(positionManager.getProfit() + historical_profit);
         
         if(program_breakout_type == PROGRAM_BREAKOUT_TRADE_CLOSING)
         {
            if(positionManager.getPositionCount() == 0)
            {
               saveStep(dict_step, step_list, current_step);
               if(last_step_was_more_than_one && current_step > 1)
               {
                  count_more_than_one_step += 1;
               }
               
               last_step_was_more_than_one = current_step > 1 ? true : false;

               tsl_last_profit         = 0;
               setHistoricalProfit(0);
               setCurrentStep(0);
               tsl                     = false;
               program_breakout_type   = PROGRAM_BREAKOUT_TRADE_WAITING;
            }
         }
      }
};


CBox              box_normal;
StepManager       stepManager;
PositionManager   positionManager(input_debug, input_magic_number);
BreakoutManager   breakoutManager;


void UpdateArray(double &array[], double value)
{
   double cache_value = array[0];
   array[0] = value;
   array[1] = cache_value;
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
   
   
   for(int i=0; i < count; i++)
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
   
   double ha2_close[];
   GetHeikanAshiClose(input_heiken_ashi_slow_ema_time_frame, 100, input_heiken_ashi_slow_ema_time_frame_shift, ha2_close);
   
   double sma_close[];
   CalculateEMA(ha2_close, input_heiken_ashi_slow_ema_period, 1, sma_close);
   
   // ArrayPrint(ha2_close);
   // ArrayPrint(sma_close);
   
   // Print("ema_close[0] ", ema_close[0], " -- sma_close[0] ", sma_close[0]);
   UpdateArray(tick_ema, ema_close[0]);
   UpdateArray(tick_sma, sma_close[0]);
   
   if(input_debug)
   {
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
         
         string trend_name = "EMA_" + TimeToString(TimeCurrent());
         TrendCreate(ChartID(), trend_name + IntegerToString(i), start_time, ema_close[i], start_time, ema_close[i], input_heiken_ashi_ema_line_color, 5);
         /*
         PrintFormat("[%s <-> %s] EMA: %s",
            TimeToString(start_time),
            TimeToString(end_time),
            DoubleToString(ema_close[i], _Digits)
         );*/
      }
      
      for(int i=0; i<ArraySize(sma_close); i++)
      {
         datetime start_time = TimeCurrent();
         datetime end_time = TimeCurrent();
         
         if(i==0)
         {
            start_time  = TimeCurrent();
            end_time    = iTime(Symbol(), input_heiken_ashi_slow_ema_time_frame, i);
         }
         else
         {
            start_time  = iTime(Symbol(), input_heiken_ashi_slow_ema_time_frame, i-1);
            end_time    = iTime(Symbol(), input_heiken_ashi_slow_ema_time_frame, i);
         }
         
         string trend_name = "SMA_" + TimeToString(TimeCurrent());
         TrendCreate(ChartID(), trend_name + IntegerToString(i), start_time, sma_close[i], start_time, sma_close[i], input_heiken_ashi_slow_ema_line_color, 5);
         /*
         PrintFormat("[%s <-> %s] SMA: %s",
            TimeToString(start_time),
            TimeToString(end_time),
            DoubleToString(sma_close[i], _Digits)
         );*/
      }
      
      ChartRedraw();
   }
}
  
  
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if (!MQLInfoInteger(MQL_TESTER))
   {
      Print("This script is intended for use only Strategy Testing.");
      return(INIT_FAILED);
   }
   else
   {
      breakoutManager.OnInit();

      box_normal.name         = "BerlinEX2_boxNormal";
      box_normal.active       = false;
      box_normal.moveable     = false;
      box_normal.line_color   = box_normal_line_color;
      box_normal.box_color    = box_normal_box_color;
      box_normal.text_color   = box_normal_text_color;
      box_normal.box_size     = 30;
      box_normal.deleteBox();

      calculateNonTradeDays();

      Calculate();
      return(INIT_SUCCEEDED);
   }
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   printSteps();
   breakoutManager.OnDeinit();
}

void OnTimer()
{

}

void OnTick()
{
   MqlTick new_tick;
   if(SymbolInfoTick(_Symbol,new_tick))
   {
      if(today_date == NULL || TimeToString(today_date, TIME_DATE) != TimeToString(new_tick.time, TIME_DATE))
      {
         today_date = new_tick.time;

         bool isset = false;
         for(int i=0; i<ArraySize(non_trade_days_list); i++)
         {
            if(TimeToString(today_date, TIME_DATE) == TimeToString(non_trade_days_list[i], TIME_DATE))
            {
               isset = true;
               break;
            }
         }

         if(isset)
         {
            Print("Today is non-trade day: ", TimeToString(today_date, TIME_DATE));
            non_trade_day = true;
            return;
         }
         else
         {
            non_trade_day = false;
         }
         
      }

      if(!non_trade_day)
      {
      double price  = (new_tick.ask + new_tick.bid) / 2;
      double profit = positionManager.getProfit() + breakoutManager.getHistoricalProfit();

      positionManager.OnTick();
      breakoutManager.OnTick();
      
      datetime trade_start_time  = StringToTime(TimeToString(new_tick.time, TIME_DATE) + " " + TimeToString(input_trade_hour_start_time, TIME_SECONDS));
      datetime trade_end_time    = StringToTime(TimeToString(new_tick.time, TIME_DATE) + " " + TimeToString(input_trade_hour_stop_time, TIME_SECONDS));

      if(new_tick.time >= trade_start_time && new_tick.time <= trade_end_time)
      {
         if(breakoutManager.getProgramBreakoutType() == PROGRAM_BREAKOUT_OPEN_BUY || breakoutManager.getProgramBreakoutType() == PROGRAM_BREAKOUT_OPEN_SELL)
         {
            double target_profit       = input_tsl_activation_profit;
            double tsl_follow_profit   = input_tsl_follow_profit;
            if(input_tsl_increment)
            {
               target_profit        = input_tsl_activation_profit * stepManager.getStepNetLot(breakoutManager.getCurrentStep());
               tsl_follow_profit    = input_tsl_follow_profit * stepManager.getStepNetLot(breakoutManager.getCurrentStep());
            }

            if(input_tsl_active)
            {
               if(!tsl)
               {
                  if(profit > target_profit)
                  {
                     tsl = true;
                     tsl_last_profit = profit;
                  }
               }
               else
               {
                  if(profit > tsl_last_profit + input_tsl_follow_profit)
                  {
                     tsl_last_profit = profit;
                  }
                  else if(profit < tsl_last_profit)
                  {
                     if(input_debug)
                     {
                        Print("--------------");
                        PrintFormat("!!! Trailing Stop Loss --> TSL: %s, Profit: %s)",
                           DoubleToString(tsl_last_profit, 2),
                           DoubleToString(profit, 2)
                        );
                        Print("--------------");
                     }

                     breakoutManager.closeAll();
                  }
               }
            }
            else
            {
               if(profit >= target_profit)
               {
                  if(input_debug)
                  {
                     Print("--------------");
                     PrintFormat("!!! Close All -->  Profit: %s)",
                        DoubleToString(profit, 2)
                     );
                     Print("--------------");
                  }

                  breakoutManager.closeAll();
               }
            }

            if(input_stop_loss_active && profit < -1*input_stop_loss_value)
            {
               if(input_debug)
               {
                  Print("--------------");
                  PrintFormat("!!! Stop Loss --> Profit: %s)",
                     DoubleToString(profit, 2)
                  );
                  Print("--------------");
               }

               breakoutManager.closeAll();
            }

            if(breakoutManager.getProgramBreakoutType() == PROGRAM_BREAKOUT_OPEN_BUY)
            {
               if(price <= box_normal.down_price)
               {
                  if(positionManager.send(price, ORDER_TYPE_SELL, stepManager.getStepNetLot(breakoutManager.getCurrentStep() + 1), breakoutManager.getCurrentStep() + 1))
                  {
                     breakoutManager.setHistoricalProfit(breakoutManager.getHistoricalProfit() + positionManager.getProfit());
                     breakoutManager.setProgramBreakoutType(PROGRAM_BREAKOUT_OPEN_SELL);
                     positionManager.closeAll(breakoutManager.getCurrentStep());
                     breakoutManager.setCurrentStep(breakoutManager.getCurrentStep() + 1);
                  }
               }
            }
            else if(breakoutManager.getProgramBreakoutType() == PROGRAM_BREAKOUT_OPEN_SELL)
            {
               if(price >= box_normal.up_price)
               {
                  if(positionManager.send(price, ORDER_TYPE_BUY, stepManager.getStepNetLot(breakoutManager.getCurrentStep() + 1), breakoutManager.getCurrentStep() + 1))
                  {
                     breakoutManager.setHistoricalProfit(breakoutManager.getHistoricalProfit() + positionManager.getProfit());
                     breakoutManager.setProgramBreakoutType(PROGRAM_BREAKOUT_OPEN_BUY);

                     positionManager.closeAll(breakoutManager.getCurrentStep());
                     breakoutManager.setCurrentStep(breakoutManager.getCurrentStep() + 1);
                  }
               }
            }
         }
         
         if (IsNewCandle())
         {
            Calculate();
            if (box_normal.active)
            {
               box_normal.moveBox();
            }
            
            if(breakoutManager.getProgramBreakoutType() == PROGRAM_BREAKOUT_TRADE_WAITING)
            {
               bool     isTradeOpen    = false;
               double   up_price       = 0;
               double   down_price     = 0;

               if(CrossOver(tick_ema, tick_sma))
               {
                  stepManager.stepCalculate(input_box_size, input_volume, 2.05, 50);

                  up_price    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                  down_price  = up_price - input_box_size;

                  if(positionManager.send(up_price, ORDER_TYPE_BUY, stepManager.getStepNetLot(breakoutManager.getCurrentStep() + 1), 1))
                  {
                     isTradeOpen = true;
                     breakoutManager.setProgramBreakoutType(PROGRAM_BREAKOUT_OPEN_BUY);
                  }
               }
               else if(CrossUnder(tick_ema, tick_sma))
               {
                  stepManager.stepCalculate(input_box_size, input_volume, 2.05, 50);

                  down_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                  up_price   = down_price + input_box_size;

                  if(positionManager.send(down_price, ORDER_TYPE_SELL, stepManager.getStepNetLot(breakoutManager.getCurrentStep() + 1), 1))
                  {
                     isTradeOpen = true;
                     breakoutManager.setProgramBreakoutType(PROGRAM_BREAKOUT_OPEN_SELL);
                  }
               }

               if(isTradeOpen)
               {
                  breakoutManager.setCurrentStep(1);

                  box_normal.up_price     = up_price;
                  box_normal.down_price   = down_price;
                  box_normal.start_time   = TimeCurrent();
                  box_normal.createBox();
               }
            }
            else if(breakoutManager.getProgramBreakoutType() == PROGRAM_BREAKOUT_TRADE_HEDGED)
            {
               switch(input_trade_hour_strategy)
               {
                  case TRADE_HOUR_STRATEGY_HEDGED_AND_WAIT_SIGNAL:
                  {
                     bool     isTradeOpen    = false;
                     double   up_price       = 0;
                     double   down_price     = 0;
                     int      step           = breakoutManager.getCurrentStep();

                     if(input_hedge_mode == HEDGE_MODE_FULL)
                     {
                        step += 1;
                     }

                     if(CrossOver(tick_ema, tick_sma))
                     {
                        stepManager.stepCalculate(input_box_size, input_volume, 2.05, 50);

                        up_price    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                        down_price  = up_price - input_box_size;

                        if(positionManager.send(up_price, ORDER_TYPE_BUY, stepManager.getStepNetLot(step), step, POSITION_BREAKOUT_TYPE_HEDGE_OUT))
                        {
                           isTradeOpen    = true;
                           breakoutManager.setHistoricalProfit(breakoutManager.getHistoricalProfit() + positionManager.getProfit());
                           breakoutManager.setProgramBreakoutType(PROGRAM_BREAKOUT_OPEN_BUY);
                           positionManager.closeAllHedge(step);
                        }
                     }
                     else if(CrossUnder(tick_ema, tick_sma))
                     {
                        stepManager.stepCalculate(input_box_size, input_volume, 2.05, 50);

                        down_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                        up_price   = down_price + input_box_size;

                        if(positionManager.send(down_price, ORDER_TYPE_SELL, stepManager.getStepNetLot(step), step, POSITION_BREAKOUT_TYPE_HEDGE_OUT))
                        {
                           isTradeOpen    = true;
                           breakoutManager.setHistoricalProfit(breakoutManager.getHistoricalProfit() + positionManager.getProfit());
                           breakoutManager.setProgramBreakoutType(PROGRAM_BREAKOUT_OPEN_SELL);
                           positionManager.closeAllHedge(step);
                        }
                     }

                     if(isTradeOpen)
                     {
                        box_normal.up_price     = up_price;
                        box_normal.down_price   = down_price;
                        box_normal.start_time   = TimeCurrent();
                        box_normal.createBox();
                     }

                     break;
                  }
                  case TRADE_HOUR_STRATEGY_HEDGED_AND_OPEN_BOX_CURRENT_PRICE:
                  {
                     break;
                  }
                  case TRADE_HOUR_STRATEGY_HEDGED_AND_OPEN_BOX_BY_TRADE_LAST_BOX:
                  {
                     break;
                  }
               }
            }
         }
      }
      else
      {
         if (IsNewCandle())
         {
            Calculate();
         }
         
         if(breakoutManager.getProgramBreakoutType() == PROGRAM_BREAKOUT_OPEN_BUY || breakoutManager.getProgramBreakoutType() == PROGRAM_BREAKOUT_OPEN_SELL)
         {
            if(profit >= 0)
            {
               if(input_debug)
               {
               Print("--------------");
               PrintFormat("!!! Outside in trade hours. Close All -->  Profit: %s)",
                  DoubleToString(profit, 2)
                  );
               Print("--------------");
               }

               breakoutManager.closeAll();
            }
            else
            {
               if(input_trade_hour_strategy != TRADE_HOUR_STRATEGY_NONE && breakoutManager.getProgramBreakoutType() != PROGRAM_BREAKOUT_TRADE_HEDGED)
               {
                  if(input_debug)
                  {
                        Print("--------------");
                        PrintFormat("!!! Outside in trade hours. Hedging -->  Profit: %s)",
                           DoubleToString(profit, 2)
                           );
                        Print("--------------");
                  }

                  if(positionManager.hedging())
                  {
                     breakoutManager.setProgramBreakoutType(PROGRAM_BREAKOUT_TRADE_HEDGED);
                     box_normal.deleteBox();
                  }
               }
            }
         }
      }
   }
   }
}

void calculateNonTradeDays()
{
   string non_trade_days_list_string[];
   commentSep(non_trade_days_string, non_trade_days_list_string, "|");

   for(int i=0; i<ArraySize(non_trade_days_list_string); i++)
   {
      datetime date = StringToTime(non_trade_days_list_string[i]);
      int size = ArraySize(non_trade_days_list);
      ArrayResize(non_trade_days_list, size + 1);
      non_trade_days_list[size] = date;
   }
   ArrayPrint(non_trade_days_list);
}


void saveStep(CDictionary &dictionary, int &list[], int step)
{
    bool isExist = false;
   for(int i=0; i<ArraySize(list); i++)
    {
      if(list[i] == step)
        {
        isExist = true;
        break;
        }
    }

    if(!isExist)
    {
      int size = ArraySize(list);
      ArrayResize(list, size + 1);
      list[size] = step;
    }

   if(dictionary.Get<int>(IntegerToString(step)) == NULL)
    {
      dictionary.Set<int>(IntegerToString(step), 1);
    }
    else
    {
      int count = dictionary.Get<int>(IntegerToString(step));
      dictionary.Set<int>(IntegerToString(step), count + 1);
    }
}

void printSteps()
{
    int total_step = 0;

    for(int i=0; i<ArraySize(step_list); i++)
    {
        string  diff    = IntegerToString(step_list[i]);
        int     count   = dict_step.Get<int>(diff);
        
        total_step += count;
    }

    for(int i=0; i<ArraySize(step_list); i++)
    {
        string  diff    = IntegerToString(step_list[i]);
        int     count   = dict_step.Get<int>(diff);

        PrintFormat("Step: %s ---> %s (%%%s)",
            IntegerToString(step_list[i]),
            IntegerToString(count),
            DoubleToString((double)count / (double)total_step * 100, 2)
        );
    }

    Print("Total Step: " + IntegerToString(total_step));
    PrintFormat("Count more than first step: %s (%%%s)",
        IntegerToString(count_more_than_one_step),
        DoubleToString((double)count_more_than_one_step / (double)total_step * 100, 2)
        );
   Print("<---------------------------------------------------->");
   Print("Hedging Step:");

   int total_hedge_count = 0;
   for(int i=0; i<ArraySize(step_hedge_list); i++)
   {
      string  diff    = IntegerToString(step_hedge_list[i]);
      int     count   = dict_hedge_step.Get<int>(diff);
      total_hedge_count += count;
   }

   for(int i=0; i<ArraySize(step_hedge_list); i++)
   {
      string  diff    = IntegerToString(step_hedge_list[i]);
      int     count   = dict_hedge_step.Get<int>(diff);
      PrintFormat("Step: %s ---> %s (%%%s)",
         IntegerToString(step_hedge_list[i]),
         IntegerToString(count),
         DoubleToString((double)count / (double)total_hedge_count * 100, 2)
      );
   }

   Print("Total Hedge In: " + IntegerToString(total_hedge_count));
   
}