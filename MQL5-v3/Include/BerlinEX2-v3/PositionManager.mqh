#include <Trade/Trade.mqh>
#include <BerlinEX2-v3/Others.mqh>

enum ENUM_POSITION_PROGRAM_STATE
{
   POSITION_PROGRAM_STATE_ERROR,
   POSITION_PROGRAM_STATE_PREPARED,
   POSITION_PROGRAM_STATE_SEND_OPEN,
   POSITION_PROGRAM_STATE_IN_PROCESS,
   POSITION_PROGRAM_STATE_SEND_CLOSE,
   POSITION_PROGRAM_STATE_CLOSED
};

enum ENUM_POSITION_BREAKOUT_TYPE
{
   POSITION_BREAKOUT_TYPE_STEP,
   POSITION_BREAKOUT_TYPE_STEP_PARTIAL,
   POSITION_BREAKOUT_TYPE_HEDGE_IN,
   POSITION_BREAKOUT_TYPE_HEDGE_OUT
};

struct SPosition
{
   ulong                         ticket;  
   double                        volume;
   ENUM_ORDER_TYPE               order_type;
   double                        open_price;
   int                           step;
   int                           magic_number;
   ENUM_POSITION_PROGRAM_STATE   program_state;
   ENUM_POSITION_BREAKOUT_TYPE   breakout_type;

   string ToString()
   {
      return StringFormat("ticket: %s, step: %s, magic_number: %s, volume: %s, open_price: %s, program_state: %s", 
         IntegerToString(ticket), 
         IntegerToString(step), 
         IntegerToString(magic_number),
         DoubleToString(volume),
         DoubleToString(open_price, _Digits),
         EnumToString(program_state)
      );
   }
};

class PositionManager
{
   SPosition position_list[];
   bool debug;
   int magic_number;
   
   void add(SPosition &position)
   {
      int array_size = ArraySize(position_list);
      ArrayResize(position_list, array_size + 1);
      position_list[array_size] = position;

      if(debug)
      {
         PrintFormat("[%s-%s] positionManager (add) --> %s",
            _Symbol,
            IntegerToString(magic_number),
            position.ToString()
         );
      }
   }

   void remove(SPosition &position)
   {
      bool isShiftOn = false;
      for(int i=0; i < ArraySize(position_list) - 1; i++) 
      {
         if(position_list[i].ticket == position.ticket) 
         {
            isShiftOn = true;
         }
         if(isShiftOn == true) 
         {
            position_list[i] = position_list[i + 1];
         }
      }
      ArrayResize(position_list, ArraySize(position_list) - 1);

      if(debug)
      {
         PrintFormat("[%s-%s] positionManager (remove) --> %s",
            _Symbol,
            IntegerToString(magic_number),
            position.ToString()
         );
      }
      
   }

   public:
      PositionManager(bool _debug, int _magic_number)
      {
         debug = _debug;
         magic_number = _magic_number;
      }

      bool send(double order_price, ENUM_ORDER_TYPE type, double volume, int magic, int step, ENUM_POSITION_BREAKOUT_TYPE breakout_type = POSITION_BREAKOUT_TYPE_STEP)
      {
         MqlTradeRequest request = {};
         MqlTradeResult result   = {};

         request.action          = TRADE_ACTION_DEAL;
         request.price           = order_price;
         request.symbol          = _Symbol;
         request.magic           = magic;
         request.type            = type;
         request.volume          = volume;
         request.type_filling    = GetFilling(_Symbol);

         switch(breakout_type)
         {
            case POSITION_BREAKOUT_TYPE_STEP:
            {
               request.comment         = "S#" + IntegerToString(step); 
               break;
            }
            case POSITION_BREAKOUT_TYPE_HEDGE_IN:
            {
               request.comment         = "HI#" + IntegerToString(step); 
               break;
            }
            case POSITION_BREAKOUT_TYPE_HEDGE_OUT:
            {
               request.comment         = "HO#" + IntegerToString(step); 
               break;
            }
         }
         
         
         if(OrderSend(request, result))
         {
            if (result.retcode == 10009)
            {
               SPosition position;
               position.ticket         = result.deal;
               position.step           = step;
               position.volume         = volume;
               position.open_price     = result.price;
               position.order_type     = type;
               position.magic_number   = magic_number;
               position.program_state  = POSITION_PROGRAM_STATE_IN_PROCESS;
               position.breakout_type  = breakout_type;
   
               add(position);
               return true;
            }
         }

         return false;
      }

      bool hedging()
      {
         double            net_lot  = getNetLot();
         ENUM_ORDER_TYPE   type     = net_lot > 0 ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
         double            volume   = MathAbs(net_lot);
         double            price    = type == ORDER_TYPE_BUY ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
         int               step     = getLastStep();

         if(send(price, type, volume, step, POSITION_BREAKOUT_TYPE_HEDGE_IN))
         {
            return true;
         }

         return false;
      }

      void close(ulong ticket)
      {
         bool is_exists = false;
         for(int i=0; i < ArraySize(position_list); i++) 
         {
            if(position_list[i].ticket == ticket) 
            {
               is_exists = true;
               position_list[i].program_state = POSITION_PROGRAM_STATE_SEND_CLOSE;
               break;
            }
         }

         if(!is_exists)
         {
            // listeye ekle
         }

         CTrade trade;
         trade.SetAsyncMode(true);
         trade.PositionClose(ticket);
      }

      void closeAll()
      {
         for(int i=0; i<ArraySize(position_list); i++) 
         {
            close(position_list[i].ticket);
         }
      }

      void closeAllTerminal(int order_magic)
      {
         int total_positions = PositionsTotal();
         for (int i=0; i<total_positions; i++)
         {
            long                ticket = (long) PositionGetTicket(i);
            string              symbol = PositionGetString(POSITION_SYMBOL);
            long                magic  = PositionGetInteger(POSITION_MAGIC);

            if (symbol == _Symbol && magic == order_magic)
            {
               close(ticket);
            }
         }
      }

      void closeAll(int step)
      {
         for(int i=0; i<ArraySize(position_list); i++) 
         {
            if(position_list[i].step <= step) 
            {
               close(position_list[i].ticket);
            }
         }
      }

      void closeAllHedge(int step)
      {
         int hedge_out_count        = 0;
         int last_hedge_out_ticket  = 0;

         for(int i=0; i<ArraySize(position_list); i++) 
         {
            if(position_list[i].step <= step && position_list[i].breakout_type != POSITION_BREAKOUT_TYPE_HEDGE_OUT) 
            {
               close(position_list[i].ticket);
            }
            else
            {
               hedge_out_count++;

               if(position_list[i].ticket > last_hedge_out_ticket)
               {
                  last_hedge_out_ticket = position_list[i].ticket;
               }
            }
         }

         
         if(hedge_out_count > 1)
         {
            for(int i=0; i<ArraySize(position_list); i++) 
            {
               if(position_list[i].step <= step && position_list[i].breakout_type == POSITION_BREAKOUT_TYPE_HEDGE_OUT && position_list[i].ticket != last_hedge_out_ticket) 
               {
                  close(position_list[i].ticket);
               }
            }
         }
      }

      int getPositionCount()
      {
         return ArraySize(position_list);
      }

      int getTerminalPositionCount(int order_magic)
      {
         int position_count = 0;
         int total_positions = PositionsTotal();
         for (int i=0; i<total_positions; i++)
         {
            long                ticket = (long) PositionGetTicket(i);
            string              symbol = PositionGetString(POSITION_SYMBOL);
            long                magic  = PositionGetInteger(POSITION_MAGIC);

            if (symbol == _Symbol && magic == order_magic)
            {
               position_count++;
            }
         }

         return position_count;
      }

      double getProfit()
      {
         double profit = 0;
         for(int i=0; i < ArraySize(position_list); i++) 
         {
            if(PositionSelectByTicket(position_list[i].ticket))
            {
               profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + getComission(position_list[i].ticket);
            }
         }
         return profit;
      }

      double getNetLot()
      {
         double net_lot = 0;
         for(int i=0; i < ArraySize(position_list); i++) 
         {
            if(position_list[i].order_type == ORDER_TYPE_BUY)
            {
               net_lot += position_list[i].volume;
            }
            else if(position_list[i].order_type == ORDER_TYPE_SELL)
            {
               net_lot -= position_list[i].volume;
            }
         }
         return net_lot;
      }

      int getLastStep()
      {
         int last_step = 0;
         for(int i=0; i < ArraySize(position_list); i++) 
         {
            if(position_list[i].step > last_step) 
            {
               last_step = position_list[i].step;
            }
         }
         return last_step;
      }

      double getComission(long position_ticket)
      {
         HistorySelectByPosition(position_ticket);
         int total_deals = HistoryDealsTotal();

         double commission = 0;
         for(int k=0; k<total_deals; k++)
         {
            long deal_ticket  = (long) HistoryDealGetTicket(k);
            commission       += HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION) + HistoryDealGetDouble(deal_ticket, DEAL_FEE);
         }
         return commission*2;
      }

      double getOpenPrice()
      {
         double open_price = 0;
         int    ticket     = 0;
         for(int i=0; i < ArraySize(position_list); i++) 
         {
            if(PositionSelectByTicket(position_list[i].ticket))
            {
               if(position_list[i].ticket > ticket)
               {
                  ticket      = position_list[i].ticket;
                  open_price  = PositionGetDouble(POSITION_PRICE_OPEN);
               }
            }
         }
         return open_price;
      }

      void OnTick()
      {
         for(int i=0; i < ArraySize(position_list); i++)
         {
            if(position_list[i].program_state == POSITION_PROGRAM_STATE_SEND_CLOSE)
            {
               if(PositionSelectByTicket(position_list[i].ticket))
               {
                  close(position_list[i].ticket);
               }
               else
               {
                  position_list[i].program_state = POSITION_PROGRAM_STATE_CLOSED;
                  remove(position_list[i]);
               }
            }
         }
      }
};