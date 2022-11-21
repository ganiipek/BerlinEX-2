#define VERSION "1.2"

#property copyright "yalcinex.com © Copyright 2022"
#property link      "https://www.yalcinex.com"
#property version   VERSION
#property description "Automated Trade by Yalcin Karapinar"
#property strict

#include <BerlinEX2-v3/Dictionary.mqh>
#include <BerlinEX2-v3/RestAPI.mqh>
#include <BerlinEX2-v3/StepManager.mqh>
#include <BerlinEX2-v3/PositionManager.mqh>
#include <BerlinEX2-v3/GUIManager.mqh>
//#include <Emirhan_bb_stoch/GUIManager_v2.mqh>
#include <BerlinEX2-v3/Others.mqh>
#include <Trade/Trade.mqh>

#resource "\\Indicators\\BerlinEX2-v3\\HeikanAshi_EMA.ex5"
#resource "\\Indicators\\BerlinEX2-v3\\BerlinEX2.ex5"


string program_name         = "Emirhan_bb_stoch";
bool   program_login_status = false;

CDictionary *dict_step = new CDictionary();
int     step_list[];

enum ENUM_PROGRAM_TRADE_TYPE
{
   PROGRAM_TRADE_WAITING,        // TRADE WATING
   PROGRAM_TRADE_BUY,            // TRADE BUY
   PROGRAM_TRADE_SELL,           // TRADE SELL
   PROGRAM_TRADE_CLOSING         // TRADE CLOSING
};

enum ENUM_BOLLINGER_BANDS_STRATEGY
{
    BOLLINGER_BANDS_STRATEGY_BASE_LINE,       // BUY if price is above base line, SELL if price is below base line
    BOLLINGER_BANDS_STRATEGY_BETWEEN_LINES    // BUY if price is between base line and upper line, SELL if price is between base line and lower line
};

enum ENUM_STOCHTASTIC_OSCILLATOR_STRATEGY
{
    STOCHTASTIC_OSCILLATOR_STRATEGY_MIDDLE,          // BUY or SELL if price is between middle line and upper line
    STOCHTASTIC_OSCILLATOR_STRATEGY_EXCESSIVE        // BUY if value is above 20, SELL if value is below 80 
};

enum ENUM_SOURCE_PRICE_STRATEGY
{
    SOURCE_PRICE_STRATEGY_NORMAL,                   // Source Price Normal
    SOURCE_PRICE_STRATEGY_HEIKEN_ASHI,              // Source Price Heiken Ashi
};

input group       "<---------- INDICATOR SETTINGS ------------>"
input ENUM_TIMEFRAMES         input_heiken_ashi_slow_ema_time_frame           = PERIOD_M1;         // Heikin Ashi Slow EMA Time Frame
input int                     input_heiken_ashi_slow_ema_time_frame_shift     = 0;                 // Heikin Ashi Slow EMA Time Frame Shift
input int                     input_heiken_ashi_slow_ema_period               = 30;                // Heikin Ashi Slow EMA Period

input ENUM_TIMEFRAMES         input_heiken_ashi_fast_ema_time_frame           = PERIOD_H1;         // Heikin Ashi Fast EMA Time Frame
input int                     input_heiken_ashi_fast_ema_time_frame_shift     = 0;                 // Heikin Ashi Fast EMA Time Frame Shift
input int                     input_heiken_ashi_fast_ema_period               = 1;                 // Heikin Ashi Fast EMA Period

input group       "<---------- TRADE SETTINGS ------------>"
input int                  input_magic_number               = 3658;                 // Magic Number
input double               input_default_volume             = 0.1;                  // Default Volume
input int                  input_increament_step            = 3;                    // How many steps do you increase?
input double               input_increament_step_size       = 2;                    // Increment Step Rate 
input int                  input_wait_step_point            = 50;                   // Wait Step Point
input int                  input_wait_increament_step       = 10;                   // Wait Increament Step
input double               input_wait_increament_value      = 2.0;                  // Wait Increament Value 
input bool                 input_trade_hour_active          = true;                 // Trade Hour Active
input datetime             input_trade_hour_start_time      = D'03:00:00';          // Trade Hour Start Time
input datetime             input_trade_hour_stop_time       = D'22:00:00';          // Trade Hour Stop Time
input int                  input_tsl_activation_point       = 50;                   // TSL Price Activation Point
input int                  input_tsl_follow_point           = 10;                   // TSL Price Follow Point
input bool                 input_stop_tsl_active            = true;                 // Stop TSL Active
input int                  input_stop_tsl_step_value        = 15;                    // Stop TSL Step
input int                  input_stop_tsl_point             = 20;                   // Stop TSL Point
input bool                 input_stop_step_active           = false;                 // Stop Step Active
input int                  input_stop_step_value            = 15;                   // Stop Step Step


input group "<------------- DEVELOPER ------------->";
input bool                 input_debug                      = true;                 // Debug
input bool                 input_show_interface             = true;                 // Show Interface
input bool                 input_connection_safe            = true;                 // Safe Connection


class TradeManager
{
    string                      local_program_name;
    ENUM_PROGRAM_TRADE_TYPE     limited_program_trade_type;
    ENUM_PROGRAM_TRADE_TYPE     program_trade_type;
    int                         current_step;
    int                         magic_number;
    bool                        tsl_active;
    double                      tsl_last_price;
    double                      last_opened_position_price ;
    double                      weighted_open_price;

    datetime                    NewCandleTime;

    PositionManager     *positionManager;


    public: 
        void OnInit(ENUM_PROGRAM_TRADE_TYPE trade_type, int magic, PositionManager* positionManagerPointer)
        {
            limited_program_trade_type  = trade_type;
            ENUM_BASE_CORNER base_corner = CORNER_LEFT_LOWER;

            if(trade_type == PROGRAM_TRADE_BUY)
            {
                local_program_name  = program_name + "_BUY";
                base_corner         = CORNER_LEFT_LOWER;
            }
            else if(trade_type == PROGRAM_TRADE_SELL)
            {
                local_program_name = program_name + "_SELL";
                base_corner         = CORNER_LEFT_UPPER;
            }
            
            // guiManager.OnInit(local_program_name, base_corner);
            positionManager         = positionManagerPointer;

            setProgramTradeType(PROGRAM_TRADE_WAITING);
            setCurrentStep(0);

            tsl_active                  = false;
            tsl_last_price              = 0;
            last_opened_position_price  = 0;
            weighted_open_price         = 0;
            NewCandleTime               = TimeCurrent();
            magic_number                = magic;  
        }

        ENUM_PROGRAM_TRADE_TYPE getProgramTradeType()
        {
            return program_trade_type;
        }

        int getCurrentStep()
        {
            return current_step;
        }

        void setProgramTradeType(ENUM_PROGRAM_TRADE_TYPE type)
        {
            program_trade_type = type;

            if(input_show_interface)
            {
                // guiManager.updateProgramTradeType(EnumToString(program_trade_type));
            }

            if(input_debug)
            {
                PrintFormat("[%s-%s] tradeManager (setProgramTradeType) --> %s",
                _Symbol,
                IntegerToString(magic_number),
                EnumToString(type)
                );
            }
        } 

        void setCurrentStep(int _current_step)
        {
            current_step = _current_step;

            if(input_show_interface)
            {
                // guiManager.updateCurrentStep(current_step);
            }

            if(input_debug)
            {
                PrintFormat("[%s-%s] tradeManager (setCurrentStep) --> %s",
                _Symbol,
                IntegerToString(magic_number),
                IntegerToString(_current_step)
                );
            }
        }

        void setTSLStatus(bool value)
        {
            tsl_active = value;
        }

        void setTSLPrice(double price)
        {
            tsl_last_price = price;

            if(input_show_interface)
            {
                if(price == 0)
                {
                    ObjectDelete(ChartID(), local_program_name + "_tsl");
                }
                else
                {
                    color line_color = clrAqua;
                    if(limited_program_trade_type == PROGRAM_TRADE_SELL)
                    {
                        line_color = clrYellow;
                    }
                    
                    HLineCreate(ChartID(), local_program_name + "_tsl", tsl_last_price, line_color);
                    ChartRedraw();
                }
            }
        }

        void closeAll()
        {
            setProgramTradeType(PROGRAM_TRADE_CLOSING);
            positionManager.closeAll();
            positionManager.closeAllTerminal(magic_number);

            PrintFormat("[%s-%s] tradeManager (closeAll)",
                _Symbol,
                IntegerToString(magic_number)
            );
        }

        void calculateTSLandSL(MqlTick &tick)
        {
            double price = (tick.ask + tick.bid) / 2;
            if(program_trade_type == PROGRAM_TRADE_BUY)
            {
                if(price - tsl_last_price > input_tsl_follow_point * _Point)
                {
                    tsl_last_price = price - input_tsl_follow_point * _Point;
                    //  sl_price  = tick.bid - ((tsl_price_activation_pip * stop_loss_coefficient) / MathPow(10, SymbolInfoInteger(input_nok_symbol, SYMBOL_DIGITS) - 1));

                    setTSLPrice(tsl_last_price);
                    //  setSLLine(sl_price);
                }
                else if(price > tsl_last_price)
                {
                    tsl_active = true;
                }
            }
            else if(program_trade_type == PROGRAM_TRADE_SELL)
            {
                if(tsl_last_price - price > input_tsl_follow_point * _Point)
                {
                    tsl_last_price = price + input_tsl_follow_point * _Point;
                    //  sl_price  = tick.ask + ((tsl_price_activation_pip * stop_loss_coefficient) / MathPow(10, SymbolInfoInteger(input_nok_symbol, SYMBOL_DIGITS) - 1));

                    setTSLPrice(tsl_last_price);
                    //  setSLLine(sl_price);
                }
                else if(price < tsl_last_price)
                {
                    tsl_active = true;
                }
            }    
        }

        bool IsNewCandle(ENUM_TIMEFRAMES timeframes=0)
        {
            // If the time of the candle when the function ran last
            // is the same as the time this candle started,
            // return false, because it is not a new candle.
            if (NewCandleTime == iTime(Symbol(), timeframes, 0)) return false;
            
            // Otherwise, it is a new candle and we need to return true.
            else
            {
                // If it is a new candle, then we store the new value.
                NewCandleTime = iTime(Symbol(), timeframes, 0);
                return true;
            }
        }

        void OnDeinit()
        {
            // guiManager.OnDeinit();
        }

        void OnTick(MqlTick &tick)
        {
            double price = (tick.ask + tick.bid) / 2;
            positionManager.OnTick();
            
            if(program_trade_type == PROGRAM_TRADE_CLOSING)
            {
                if(positionManager.getPositionCount() == 0 && positionManager.getTerminalPositionCount(magic_number) == 0)
                {
                    saveStep(dict_step, step_list, current_step);
                    
                    tsl_active                  = false;
                    setTSLPrice(0);
                    last_opened_position_price  = 0;

                    setProgramTradeType(PROGRAM_TRADE_WAITING);
                    setCurrentStep(0);

                    ChartRedraw();
                }   
                else
                {
                    positionManager.closeAll();
                    positionManager.closeAllTerminal(magic_number);
                }
            }
            else if(checkTradeHours(tick))
            {
                if(IsNewCandle(PERIOD_M5))
                {
                    ENUM_ORDER_TYPE berlienex2_strategy  = checkBerlinEX2Strategy();

                    if(program_trade_type == PROGRAM_TRADE_WAITING)
                    {
                        if(berlienex2_strategy != -1)
                        {
                            calculateStep();
                            ENUM_ORDER_TYPE         order_type              = berlienex2_strategy;
                            double                  order_price             = 0;
                            

                            if(limited_program_trade_type == PROGRAM_TRADE_BUY && order_type == ORDER_TYPE_BUY)
                            {
                                order_price         = tick.ask;
                                program_trade_type  = PROGRAM_TRADE_BUY;
                            }
                            else if(limited_program_trade_type == PROGRAM_TRADE_SELL && order_type == ORDER_TYPE_SELL)
                            {
                                order_price         = tick.bid;
                                program_trade_type  = PROGRAM_TRADE_SELL;
                            }

                            if(order_price > 0)
                            {
                                if(positionManager.send(order_price, order_type, stepManager.getStepLot(current_step + 1), magic_number, 1))
                                {
                                    setProgramTradeType(program_trade_type);
                                    setCurrentStep(1);

                                    last_opened_position_price  = order_price;
                                    weighted_open_price         = order_price;  

                                    if(program_trade_type == PROGRAM_TRADE_BUY)
                                    {
                                        setTSLPrice(order_price + input_tsl_activation_point * _Point);
                                    }
                                    else if(program_trade_type == PROGRAM_TRADE_SELL)
                                    {
                                        setTSLPrice(order_price - input_tsl_activation_point * _Point);
                                    }
                                    else
                                    {
                                        PrintFormat("\n\n Error: program_trade_type is %s", EnumToString(program_trade_type));
                                    }
                                
                                    if(input_show_interface)
                                    {
                                        // guiManager.updateLastOpenedPrice(last_opened_position_price, _Digits); 
                                        // guiManager.updateWeightedPrice(weighted_open_price, _Digits); 
                                    }
                                }
                            }
                        }
                    }
                    else if(program_trade_type == PROGRAM_TRADE_BUY)
                    {
                        if(NormalizeDouble(last_opened_position_price, _Digits) == 0) last_opened_position_price = getLastOpenedPrice(magic_number, program_trade_type == PROGRAM_TRADE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
                        if(NormalizeDouble(weighted_open_price, _Digits) == 0)        weighted_open_price        = getWeightedOpenPrice(magic_number);
                        
                        double wait_point = input_wait_increament_step > current_step ? input_wait_step_point : input_wait_step_point * input_wait_increament_value;
                        if(price < last_opened_position_price - wait_point * _Point)
                        {
                            calculateStep();
                            
                            bool    isTradeOpen     = false;
                            double  order_price     = tick.ask;
                            int     next_step       = getCurrentStep() + 1;

                            if(input_stop_step_active && input_stop_step_value < next_step)
                            {
                                PrintFormat("[%s-%s] Stop Step Close All --> Current Step: %s - Next Step: %s",
                                    _Symbol,
                                    IntegerToString(magic_number),
                                    IntegerToString(getCurrentStep()),
                                    IntegerToString(getCurrentStep() + 1)
                                );

                                closeAll();
                            }
                            else
                            {
                                if(positionManager.send(order_price, ORDER_TYPE_BUY, stepManager.getStepLot(current_step + 1), magic_number, next_step))
                                {
                                    isTradeOpen = true;
                                    setCurrentStep(next_step);
                                }

                                if(isTradeOpen)
                                {
                                    last_opened_position_price = order_price;
                                    weighted_open_price        = getWeightedOpenPrice(magic_number);

                                    if(input_stop_tsl_active && input_stop_tsl_step_value <= current_step)
                                    {
                                        setTSLPrice(weighted_open_price + input_stop_tsl_point * _Point);
                                    }
                                    else
                                    {
                                        setTSLPrice(weighted_open_price + input_tsl_activation_point * _Point);
                                    }

                                    if(input_show_interface)
                                    {
                                        // guiManager.updateLastOpenedPrice(last_opened_position_price, _Digits); 
                                        // guiManager.updateWeightedPrice(weighted_open_price, _Digits); 
                                    }
                                }
                            }
                            
                        }
                    }
                    else if(program_trade_type == PROGRAM_TRADE_SELL)
                    {
                        if(NormalizeDouble(last_opened_position_price, _Digits) == 0) last_opened_position_price = getLastOpenedPrice(magic_number, program_trade_type == PROGRAM_TRADE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
                        if(NormalizeDouble(weighted_open_price, _Digits) == 0)        weighted_open_price        = getWeightedOpenPrice(magic_number);

                        double wait_point = input_wait_increament_step > current_step ? input_wait_step_point : input_wait_step_point * input_wait_increament_value;
                        if(price > last_opened_position_price + wait_point * _Point)
                        {
                            calculateStep();

                            bool    isTradeOpen     = false;
                            double  order_price     = tick.bid;
                            int     next_step       = current_step + 1;

                            if(input_stop_step_active && input_stop_step_value < next_step)
                            {
                                PrintFormat("[%s-%s] Stop Step Close All --> Current Step: %s - Next Step: %s",
                                    _Symbol,
                                    IntegerToString(magic_number),
                                    IntegerToString(getCurrentStep()),
                                    IntegerToString(getCurrentStep() + 1)
                                );

                                closeAll();
                            }
                            else
                            {
                                if(positionManager.send(order_price, ORDER_TYPE_SELL, stepManager.getStepLot(current_step + 1), magic_number, next_step))
                                {
                                    isTradeOpen = true;
                                    setCurrentStep(next_step);
                                }

                                if(isTradeOpen)
                                {
                                    last_opened_position_price = order_price;
                                    weighted_open_price        = getWeightedOpenPrice(magic_number);
                                    
                                    if(input_stop_tsl_active && input_stop_tsl_step_value <= current_step)
                                    {
                                        setTSLPrice(weighted_open_price - input_stop_tsl_point * _Point);
                                    }
                                    else
                                    {
                                        setTSLPrice(weighted_open_price - input_tsl_activation_point * _Point);
                                    }

                                    if(input_show_interface)
                                    {
                                        // guiManager.updateLastOpenedPrice(last_opened_position_price, _Digits); 
                                        // guiManager.updateWeightedPrice(weighted_open_price, _Digits); 
                                    }
                                }
                            }
                        }
                    }
                }

                double price = (tick.ask + tick.bid) / 2;
                if(program_trade_type == PROGRAM_TRADE_BUY)
                {
                    calculateTSLandSL(tick);

                    if(tsl_active && price <= tsl_last_price)
                    {
                        Print("\n------------------------------------------------------");
                        if(input_stop_tsl_active && input_stop_tsl_step_value <= current_step)
                        {
                            
                            PrintFormat("Stop step reached. Order is closed. Price: %s | TSL Price: %s | Weighted Price: %s | Step: %s",
                                DoubleToString(price, _Digits),
                                DoubleToString(tsl_last_price, _Digits),
                                DoubleToString(weighted_open_price, _Digits),
                                IntegerToString(current_step)
                            );
                        }
                        else
                        {
                            PrintFormat("TSL reached. Order is closed. Price: %s | TSL Price: %s | Weighted Price: %s | Step: %s",
                                DoubleToString(price, _Digits),
                                DoubleToString(tsl_last_price, _Digits),
                                DoubleToString(weighted_open_price, _Digits),
                                IntegerToString(current_step)
                            );
                        }
                        Print("------------------------------------------------------\n");
                        
                        closeAll();
                    }
                }
                else if(program_trade_type == PROGRAM_TRADE_SELL)
                {
                    calculateTSLandSL(tick);

                    if(tsl_active && price >= tsl_last_price)
                    {
                        Print("\n------------------------------------------------------");
                        if(input_stop_tsl_active && input_stop_tsl_step_value <= current_step)
                        {
                            
                            PrintFormat("Stop step reached. Order is closed. Price: %s | TSL Price: %s | Weighted Price: %s | Step: %s",
                                DoubleToString(price, _Digits),
                                DoubleToString(tsl_last_price, _Digits),
                                DoubleToString(weighted_open_price, _Digits),
                                IntegerToString(current_step)
                            );
                        }
                        else
                        {
                            PrintFormat("TSL reached. Order is closed. Price: %s | TSL Price: %s | Weighted Price: %s | Step: %s",
                                DoubleToString(price, _Digits),
                                DoubleToString(tsl_last_price, _Digits),
                                DoubleToString(weighted_open_price, _Digits),
                                IntegerToString(current_step)
                            );
                        }
                        Print("------------------------------------------------------\n");
                        
                        closeAll();
                    }
                }
            }
            else
            {
                if(program_trade_type != PROGRAM_TRADE_WAITING && program_trade_type != PROGRAM_TRADE_CLOSING)
                {
                    double profit = positionManager.getProfit();
                    if(profit >= 0)
                    {
                        Print("\n------------------------------------------------------");
                        PrintFormat("Outside of trading hours. Order is closed with '%s $' profit.",
                            DoubleToString(profit, _Digits)
                        );
                        Print("------------------------------------------------------\n");
                        closeAll();
                    }
                }
            }
        }
};

int     handle_berlinex2;

double  buffer_berlinex2[];

// bool    tsl_active                  = false;
// double  tsl_last_price              = 0;
// double  last_opened_position_price  = 0;
// double  weighted_open_price         = 0;

RestAPI             yalcinAPI(true, true);
StepManager         stepManager;
// CProgram            guiManager;
PositionManager     positionManagerBuy(input_debug, input_magic_number);
PositionManager     positionManagerSell(input_debug, input_magic_number + 1);

TradeManager        tradeManagerBuy;
TradeManager        tradeManagerSell;

int OnInit()
{
    CJAVal result_json;
    
    if(!MQLInfoInteger(MQL_TESTER))
    {
        int sleep_seconds = 0 + (1000*MathRand())/32768;
        Sleep(sleep_seconds);

        result_json = yalcinAPI.login(
                (int) AccountInfoInteger(ACCOUNT_LOGIN), 
                AccountInfoString(ACCOUNT_COMPANY), 
                AccountInfoString(ACCOUNT_NAME),
                VERSION
            );
        
        if(result_json["status"].ToInt() == 200)
        {
            program_login_status = true;

            // guiManager.OnInitEvent();
            // if(!guiManager.CreateTradePanel())
            // {
            //     Print(__FUNCTION__," > Failed to create graphical interface!");
            //     return(INIT_FAILED);
            // }
        }
    } 

    if (MQLInfoInteger(MQL_TESTER) || program_login_status)
    {
        ArraySetAsSeries(buffer_berlinex2, true);

        handle_berlinex2 = iCustom(
            _Symbol, 
            PERIOD_CURRENT, 
            "\\Indicators\\BerlinEX2-v3\\BerlinEX2.ex5",
            input_heiken_ashi_slow_ema_time_frame,
            input_heiken_ashi_slow_ema_time_frame_shift,
            input_heiken_ashi_slow_ema_period,
            input_heiken_ashi_fast_ema_time_frame,
            input_heiken_ashi_fast_ema_time_frame_shift,
            input_heiken_ashi_fast_ema_period
        );

        if(handle_berlinex2 == INVALID_HANDLE)
        {
            PrintFormat("Failed to create handle of the BerlinEX2 indicator for the symbol %s/%s, error code %d",
                        _Symbol,
                        EnumToString(PERIOD_CURRENT),
                        GetLastError());
            return(INIT_FAILED);
        }
        
        tradeManagerBuy.OnInit(PROGRAM_TRADE_BUY, input_magic_number, &positionManagerBuy);
        tradeManagerSell.OnInit(PROGRAM_TRADE_SELL, input_magic_number + 1, &positionManagerSell);
        // EventSetTimer(60*60);
        
        return(INIT_SUCCEEDED);
    }
    
    ExpertRemove();
    return(INIT_FAILED);
}

void OnDeinit(const int reason)
{
    tradeManagerBuy.OnDeinit();
    tradeManagerSell.OnDeinit();
    EventKillTimer();
    // guiManager.OnDeinitEvent(reason);

    if(MQLInfoInteger(MQL_TESTER))
    {
        printSteps();
    }
}

void OnTick()
{
    MqlTick new_tick;
    if(SymbolInfoTick(_Symbol, new_tick))
    {
        positionManagerBuy.OnTick();
        // positionManagerSell.OnTick();

        tradeManagerBuy.OnTick(new_tick);
        // tradeManagerSell.OnTick(new_tick);
    }
}

void OnTimer()
{
    if(!MQLInfoInteger(MQL_TESTER))
    {
        // guiManager.OnTimerEvent();
        program_login_status = yalcinAPI.loginCheck(
            (int) AccountInfoInteger(ACCOUNT_LOGIN), 
            AccountInfoString(ACCOUNT_COMPANY), 
            AccountInfoString(ACCOUNT_NAME),
            VERSION
        );
    }
}

void OnChartEvent(const int    id,
                  const long   &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if(!MQLInfoInteger(MQL_TESTER))
    {
        // guiManager.ChartEvent(id, lparam, dparam, sparam);
    }
}

bool fillBerlinEX2Buffer()
{
    if(CopyBuffer(handle_berlinex2, 1, 0, 10, buffer_berlinex2) < 0) return false;

    return true;
}

bool checkTradeHours(MqlTick &tick)
{
    datetime trade_start_time  = StringToTime(TimeToString(tick.time, TIME_DATE) + " " + TimeToString(input_trade_hour_start_time, TIME_SECONDS));
    datetime trade_end_time    = StringToTime(TimeToString(tick.time, TIME_DATE) + " " + TimeToString(input_trade_hour_stop_time, TIME_SECONDS));

    if(!input_trade_hour_active || tick.time >= trade_start_time && tick.time <= trade_end_time)
    {
        return true;
    }
    return false;
}

ENUM_ORDER_TYPE checkBerlinEX2Strategy()
{
    if(!fillBerlinEX2Buffer()) return -1;

    if(buffer_berlinex2[1] == 0 && buffer_berlinex2[0] == 1) return ORDER_TYPE_SELL;
    else if(buffer_berlinex2[1] == 1 && buffer_berlinex2[0] == 0) return ORDER_TYPE_BUY;

    return -1;
}


double getWeightedOpenPrice(int order_magic)
{
    double weighted_open_price = 0;
    double total_volume        = 0;

    int total_positions = PositionsTotal();
    for (int i=0; i<total_positions; i++)
    {
        long     ticket = (long) PositionGetTicket(i);
        string   symbol = PositionGetString(POSITION_SYMBOL);
        long     magic  = PositionGetInteger(POSITION_MAGIC);

        if (symbol == _Symbol && magic == order_magic)
        {
            weighted_open_price += PositionGetDouble(POSITION_PRICE_OPEN) * PositionGetDouble(POSITION_VOLUME);
            total_volume        += PositionGetDouble(POSITION_VOLUME);
        }
    }

    return NormalizeDouble(weighted_open_price / total_volume, _Digits);
}

double getLastOpenedPrice(int order_magic, ENUM_ORDER_TYPE order_type)
{
    int price = 0;
    int total_positions = PositionsTotal();
    for (int i=0; i<total_positions; i++)
    {
        long                ticket = (long) PositionGetTicket(i);
        string              symbol = PositionGetString(POSITION_SYMBOL);
        long                magic  = PositionGetInteger(POSITION_MAGIC);
        ENUM_ORDER_TYPE     type   = PositionGetInteger(POSITION_TYPE);

        if (symbol == _Symbol && magic == order_magic && type == order_type)
        {
            double open_price = PositionGetDouble(POSITION_PRICE_OPEN);

            if(order_type == ORDER_TYPE_BUY && open_price > price)
            {
                price = open_price;
            }
            else if(order_type == ORDER_TYPE_SELL && open_price < price)
            {
                price = open_price;
            }
        }
    }
    return 0;
}

void calculateStep()
{
   stepManager.stepCalculate(input_default_volume, input_increament_step, input_increament_step_size, 50);
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
    int total_step   = 0;
    CJAVal json_steps;

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
        json_steps[diff] = count;

        PrintFormat("Step: %s ---> %s (%%%s)",
            IntegerToString(step_list[i]),
            IntegerToString(count),
            DoubleToString((double)count / (double)total_step * 100, 2)
        );
    }
    Print("Total Step: " + IntegerToString(total_step));
    Print(json_steps.Serialize());

    Print("\nStep - Lot: ");
    stepManager.stepCalculate(input_default_volume, input_increament_step, input_increament_step_size, 30);
    stepManager.printStep();
/*
    Print("\n Program Settings:");
    // CJAVal json_settings = getProgramSettings();
    PrintFormat("\"indicators\":%s",
        json_settings["indicators"].Serialize()
    );
    PrintFormat("\"strategy\":%s",
        json_settings["strategy"].Serialize()
    );
    PrintFormat("\"trade\":%s",
        json_settings["trade"].Serialize()
    );*/
}

double angleCalculate(double &buffer[], ENUM_TIMEFRAMES timeframe, double point)
{
   if(ArraySize(buffer) > 2)
   {
      double adjacent = sqrt(PeriodSeconds(timeframe)*60);
      double opposite = (buffer[0]-buffer[1]) / point;
      double angle = MathArctan((double)opposite/(double)adjacent) * 180/3.14;
        
      return angle;
   }
   
   return 0;
}
/*
CJAVal getProgramSettings()
{
    CJAVal json_settings;
    json_settings["indicators"]["bb_timeframes"]            = (int) input_bb_timeframes;
    json_settings["indicators"]["bb_periods"]               = input_bb_periods;
    json_settings["indicators"]["bb_deviation"]             = input_bb_deviation;
    json_settings["indicators"]["bb_shift"]                 = input_bb_shift;
    json_settings["indicators"]["bb_applied_price"]         = (int) input_bb_applied_price;
    json_settings["indicators"]["stoch_timeframes"]         = (int) input_stoch_timeframes;
    json_settings["indicators"]["stoch_k_periods"]          = input_stoch_k_periods;
    json_settings["indicators"]["stoch_d_periods"]          = input_stoch_d_periods;
    json_settings["indicators"]["stoch_slowing"]            = input_stoch_slowing;
    json_settings["indicators"]["stoch_methods"]            = (int) input_stoch_methods;
    json_settings["indicators"]["stoch_sto_price"]          = (int) input_stoch_sto_price;

    json_settings["strategy"]["bb_strategy"]                = (int) input_bb_strategy;
    json_settings["strategy"]["stoch_strategy"]             = (int) input_stoch_strategy;

    json_settings["trade"]["default_volume"]                = input_default_volume;
    json_settings["trade"]["increament_step"]               = input_increament_step;
    json_settings["trade"]["increament_step_size"]          = input_increament_step_size;
    json_settings["trade"]["wait_step_point"]               = input_wait_step_point;
    json_settings["trade"]["wait_increament_step"]          = input_wait_increament_step;
    json_settings["trade"]["wait_increament_value"]         = input_wait_increament_value;
    json_settings["trade"]["trade_hour_status"]             = input_trade_hour_active;
    json_settings["trade"]["trade_hour_start"]              = TimeToString(input_trade_hour_start_time, TIME_MINUTES);
    json_settings["trade"]["trade_hour_end"]                = TimeToString(input_trade_hour_stop_time, TIME_MINUTES);
    json_settings["trade"]["tsl_activation_point"]          = input_tsl_activation_point;
    json_settings["trade"]["tsl_follow_point"]              = input_tsl_follow_point;
    json_settings["trade"]["stop_tsl_active"]               = input_stop_tsl_active;
    json_settings["trade"]["stop_tsl_step_value"]           = input_stop_tsl_step_value;
    json_settings["trade"]["stop_tsl_point"]                = input_stop_tsl_point;
    json_settings["trade"]["stop_step_active"]              = input_stop_step_active;
    json_settings["trade"]["stop_step_value"]               = input_stop_step_value;

    return json_settings;
}*/