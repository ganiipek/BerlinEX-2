struct SStep
{
    int step;
    double lot;
    double net_lot;
    double total_lot;
};

class StepManager
{
    private:
        SStep step[];

        int    current_step;

    public:
        double getStepLot(int cstep)
        {
            if(ArraySize(step) > cstep && cstep > 0)
            {
                return step[cstep - 1].lot;
            }
            return -1.0;
        }

        double getStepNetLot(int cstep)
        {
            if(ArraySize(step) > cstep && cstep > 0)
            {
                return step[cstep - 1].net_lot;
            }
            return -1.0;
        }

        void stepCalculate(double first_position_size, int increament_step, double input_size, int step_count)
        {
            ArrayResize(step, step_count);
            double volume_minimum = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

            for(int current=0; current<step_count; current++)
            {
                if (current == 0)
                {
                    step[current].step              = current + 1;
                    step[current].lot               = first_position_size;
                    step[current].net_lot           = step[current].lot;
                    step[current].total_lot         = step[current].lot;
                }
                else if(MathMod(current, increament_step) == 0)
                {
                    step[current].step              = current + 1;
                    step[current].lot               = step[current-1].lot * input_size;
                    step[current].net_lot           = step[current].lot - step[current-1].lot;
                    step[current].total_lot         = step[current-1].total_lot + step[current].lot;
                }
                else
                {
                    step[current].step              = current + 1;
                    step[current].lot               = step[current-1].lot;
                    step[current].net_lot           = step[current-1].net_lot;
                    step[current].total_lot         = step[current-1].total_lot + step[current].lot;
                }

                double  min_lot_step    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
                int     digits          = countDecimal(min_lot_step);
                if(min_lot_step == 0)   min_lot_step = 1;

                step[current].lot               = NormalizeDouble(MathRound(step[current].lot / min_lot_step) * min_lot_step, countDecimal(volume_minimum));
                step[current].net_lot           = NormalizeDouble(MathRound(step[current].net_lot / min_lot_step) * min_lot_step, countDecimal(volume_minimum));
                step[current].total_lot         = NormalizeDouble(MathRound(step[current].total_lot / min_lot_step) * min_lot_step, countDecimal(volume_minimum));
            }

        }

        void printStep()
        {
            ArrayPrint(step);
        }
};