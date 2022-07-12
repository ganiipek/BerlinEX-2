#include <BerlinEX2-v2/Others.mqh>

class GUIManager
{
   public:
      void OnInit()
      {
         LabelCreate(ChartID(), "BerlinEX_UNBEATEN_trade_type",               4,  74,  "Trade Type: ", 9, C'248, 248, 248');
         LabelCreate(ChartID(), "BerlinEX_UNBEATEN_current_step",             4,  61,  "Step: ", 9, C'248, 248, 248');
         LabelCreate(ChartID(), "BerlinEX_UNBEATEN_profit",                   4,  48,  "Profit: ", 9, C'248, 248, 248');
         LabelCreate(ChartID(), "BerlinEX_UNBEATEN_historical_profit",        4,  35,  "His. Profit: 0", 9, C'248, 248, 248');
         LabelCreate(ChartID(), "BerlinEX_UNBEATEN_tsl_price",                4,  22,  "TSL Price: 0", 9, C'248, 248, 248');
         LabelCreate(ChartID(), "BerlinEX_UNBEATEN_sl_price",                 4,  9,   "SL Price: 0", 9, C'248, 248, 248');
      }

      void OnDeinit()
      {
         ObjectDelete(ChartID(), "BerlinEX_UNBEATEN_trade_type");
         ObjectDelete(ChartID(), "BerlinEX_UNBEATEN_current_step");
         ObjectDelete(ChartID(), "BerlinEX_UNBEATEN_profit");
         ObjectDelete(ChartID(), "BerlinEX_UNBEATEN_historical_profit");
         ObjectDelete(ChartID(), "BerlinEX_UNBEATEN_tsl_price");
         ObjectDelete(ChartID(), "BerlinEX_UNBEATEN_sl_price");
      }

      void updateTradeType(string trade_type)
      {
         LabelTextChange(ChartID(), "BerlinEX_UNBEATEN_trade_type", "Trade Type: " + trade_type);
      }

      void updateProfit(double profit)
      {
         LabelTextChange(ChartID(), "BerlinEX_UNBEATEN_profit", "Profit: " + DoubleToString(profit, 2));
      }

      void updateHistoricalProfit(double profit)
      {
         LabelTextChange(ChartID(), "BerlinEX_UNBEATEN_historical_profit", "His. Profit: " + DoubleToString(profit, 2));
      }

      void updateTSLPrice(double tsl_price)
      {
         LabelTextChange(ChartID(), "BerlinEX_UNBEATEN_tsl_price", "TSL Price: " + DoubleToString(tsl_price, 2));
      }

      void updateSLPrice(double sl_price)
      {
         LabelTextChange(ChartID(), "BerlinEX_UNBEATEN_sl_price", "SL Price: " + DoubleToString(sl_price, 2));
      }

      void updateCurrentStep(int step)
      {
         LabelTextChange(ChartID(), "BerlinEX_UNBEATEN_current_step", "Step: " + IntegerToString(step));
      }
};
