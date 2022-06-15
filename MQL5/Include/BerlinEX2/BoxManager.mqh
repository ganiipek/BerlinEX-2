#include <BerlinEX2/Others.mqh>

struct SBox
{
  string name;
  bool active;
  bool moveable;

  double up_price;
  double down_price;
  double box_size;

  datetime start_time;
  datetime end_time;
  
  color line_color;
  color box_color;
  color text_color;
};


class CBox
{

  public:
    string name;
    bool active;
    bool moveable;

    double up_price;
    double down_price;
    double box_size;

    datetime start_time;
    datetime end_time;
    
    color line_color;
    color box_color;
    color text_color;

    void createBox()
    {
      active = true;
      end_time = TimeCurrent();

      createLine(name + "_Up", up_price);
      createLine(name + "_Down", down_price);
      createBoxRectAngle(name + "_Rect");

      if(moveable)
      {
        createMoveableLine(name + "_selectable");
      }
    }

    void moveBox()
    {
      end_time = TimeCurrent();
      ObjectMove(ChartID(), name + "_Up_Line", 0, start_time, up_price);
      ObjectMove(ChartID(), name + "_Up_Line", 1, end_time, up_price);
      ObjectMove(ChartID(), name + "_Down_Line", 0, start_time, down_price);
      ObjectMove(ChartID(), name + "_Down_Line", 1, end_time, down_price);
      ObjectMove(ChartID(), name + "_Rect", 0, start_time, up_price);
      ObjectMove(ChartID(), name + "_Rect", 1, end_time, down_price);

      ObjectMove(ChartID(), name + "_Up_Text", 0, end_time, up_price);
      ObjectMove(ChartID(), name + "_Down_Text", 0, end_time, down_price);

      ObjectSetString(ChartID(),  name + "_Up_Text", OBJPROP_TEXT, "   " + DoubleToString(up_price, Digits()));
      ObjectSetString(ChartID(),  name + "_Down_Text", OBJPROP_TEXT, "   " + DoubleToString(down_price, Digits()));
      
      if(moveable)
      {
        ObjectMove(ChartID(), name + "_selectable", 0, end_time, down_price);
        ObjectMove(ChartID(), name + "_selectable", 1, end_time, up_price);
      }
    }

    // bool boxSizeControl(double new_box_size)
    // {
    //   double symbol_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    //   double symbol_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    //   double spread = symbol_ask - symbol_bid;
    //   double ekstra_pip = 0.00002 * MathPow(10, countDigit((symbol_ask-symbol_bid)/2)); 

    //   if((spread + 2*ekstra_pip) > new_box_size)
    //   {
    //     return false;
    //   }
    //   return true;
    // }

    void createLine(string line_name, double price)
    {
      ObjectCreate(ChartID(),     line_name + "_Line", OBJ_TREND, 0, TimeCurrent() - 600, price, TimeCurrent(), price);
      ObjectSetInteger(ChartID(), line_name + "_Line", OBJPROP_BACK, true);
      ObjectSetInteger(ChartID(), line_name + "_Line", OBJPROP_ZORDER, 0);
      ObjectSetInteger(ChartID(), line_name + "_Line", OBJPROP_SELECTABLE, false);
      ObjectSetInteger(ChartID(), line_name + "_Line", OBJPROP_SELECTED, false);
      ObjectSetInteger(ChartID(), line_name + "_Line", OBJPROP_WIDTH, 2);
      ObjectSetInteger(ChartID(), line_name + "_Line", OBJPROP_COLOR, line_color);

      ObjectDelete(ChartID(),     line_name + "_Text");
      ObjectCreate(ChartID(),     line_name + "_Text", OBJ_TEXT, 0, TimeCurrent(), price);
      ObjectSetString(ChartID(),  line_name + "_Text", OBJPROP_TEXT, "   " + DoubleToString(price, Digits()));
      ObjectSetString(ChartID(),  line_name + "_Text", OBJPROP_FONT, "Consolas");
      ObjectSetInteger(ChartID(), line_name + "_Text", OBJPROP_FONTSIZE, 12);
      ObjectSetInteger(ChartID(), line_name + "_Text", OBJPROP_ANCHOR, ANCHOR_LEFT);
      ObjectSetInteger(ChartID(), line_name + "_Text", OBJPROP_COLOR, text_color);
      ObjectSetInteger(ChartID(), line_name + "_Text", OBJPROP_BACK, true);
      ObjectSetInteger(ChartID(), line_name + "_Text", OBJPROP_SELECTABLE, false);
      ObjectSetInteger(ChartID(), line_name + "_Text", OBJPROP_SELECTED, false);
      ObjectSetInteger(ChartID(), line_name + "_Text", OBJPROP_HIDDEN, false);
      ObjectSetInteger(ChartID(), line_name + "_Text", OBJPROP_ZORDER, 0);
    }

    void createMoveableLine(string line_name)
    {
      ObjectCreate(ChartID(),     line_name, OBJ_TREND, 0, end_time, down_price, end_time, up_price);
      ObjectSetInteger(ChartID(), line_name, OBJPROP_BACK, true);
      ObjectSetInteger(ChartID(), line_name, OBJPROP_ZORDER, 5);
      ObjectSetInteger(ChartID(), line_name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(ChartID(), line_name, OBJPROP_SELECTED, true);
      ObjectSetInteger(ChartID(), line_name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(ChartID(), line_name, OBJPROP_COLOR, line_color);
    }

    void createBoxRectAngle(string box_name)
    {
      ObjectCreate(ChartID(),     box_name, OBJ_RECTANGLE, 0, TimeCurrent() - 600, up_price, TimeCurrent(), down_price);
      ObjectSetInteger(ChartID(), box_name, OBJPROP_BACK, true);
      ObjectSetInteger(ChartID(), box_name, OBJPROP_ZORDER, 0);
      ObjectSetInteger(ChartID(), box_name, OBJPROP_FILL, true);
      ObjectSetInteger(ChartID(), box_name, OBJPROP_COLOR, box_color);
    }

    void deleteBox()
    {
      active = false;
      up_price = 0.0;
      down_price = 0.0;

      ObjectDelete(ChartID(), name + "_Up_Line");
      ObjectDelete(ChartID(), name + "_Down_Line");
      ObjectDelete(ChartID(), name + "_Rect");
      ObjectDelete(ChartID(), name + "_Up_Text");
      ObjectDelete(ChartID(), name + "_Down_Text");

      if(moveable)
      {
        ObjectDelete(ChartID(), name + "_selectable");
      }
    }
};

