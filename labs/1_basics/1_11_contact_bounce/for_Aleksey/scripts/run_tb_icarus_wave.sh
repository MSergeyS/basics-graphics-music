#!/bin/sh

#-----------------------------------------------------------------------------

waveform_viewer="gtkwave"
# waveform_viewer="surfer"

#-----------------------------------------------------------------------------

simulate_rtl()
{
    prj_path="../out"
    import_path="../src"
	quartus_lib_path="C:/intelFPGA/22.1std/quartus/eda/sim_lib"

    if ! command -v iverilog > /dev/null 2>&1
    then
        printf "%s\n"                                                \
               "ERROR: Icarus Verilog (iverilog) is not in the path" \
               "or cannot be run."                                   \
               "See README.md file in the package directory"         \
               "for the instructions how to install Icarus."         \
               "Press enter"

        read -r enter
        exit 1
    fi

    rm -f $prj_path/dump.vcd
    rm -f $prj_path/log.txt

        iverilog -g2005-sv -s testbench  -o $prj_path/sim.out >> $prj_path/log.txt 2>&1  \
                -I *.*v ../*.*v  $import_path/*.*v         2>&1 | tee "$prj_path/log.txt"

    shopt -u nullglob

    #-------------------------------------------------------------------------

    vvp $prj_path/sim.out 2>&1 | tee "$prj_path/log.txt"

    if grep -m 1 ERROR "$prj_path/log.txt" ; then
        warning errors detected
    fi
    
    #-------------------------------------------------------------------------
                
    rm -f $prj_path/sim.out

    # Don't print iverilog warning about not supporting constant selects
    sed -i '/sorry: constant selects/d' $prj_path/log.txt
    # Don't print $finish calls to make log cleaner
    sed -i '/finish called/d' $prj_path/log.txt
    
}

#-----------------------------------------------------------------------------

open_waveform()
{
    if [ -f $prj_path/dump.vcd ]
    then

        if [ "$waveform_viewer" = "gtkwave" ]
        then
            if [ -f gtkwave.tcl ]
            then
                gtkwave $prj_path/dump.vcd --script gtkwave.tcl
            else
                gtkwave $prj_path/dump.vcd &
            fi
        elif [ "$waveform_viewer" = "surfer" ]
        then
            if [ -f state.ron ]
            then
                surfer $prj_path/dump.vcd --state-file state.ron &
            else
                surfer $prj_path/dump.vcd &
            fi
        fi

    else
        printf "No dump.vcd file found\n"
        printf "Check that it's generated in testbench for this exercise\n\n"
    fi
}

#-----------------------------------------------------------------------------

simulate_rtl

while getopts ":lw-:" opt
do
    case $opt in
        -)
            case $OPTARG in
                lint)
                    lint_code;;
                wave)
                    open_waveform;;
                *)
                    printf "ERROR: Unknown option\n"
                    printf "Press enter\n"
                    read -r enter
                    exit 1
            esac;;
        l)
            lint_code;;
        w)
            open_waveform;;
        ?)
            printf "ERROR: Unknown option\n"
            printf "Press enter\n"
            read -r enter
            exit 1;;
    esac
done

#-----------------------------------------------------------------------------

grep -e PASS -e FAIL -e ERROR -e Error -e error -e Timeout -e ++ $prj_path/log.txt \
    | sed -e 's/PASS/\x1b[0;32m&\x1b[0m/g' -e 's/FAIL/\x1b[0;31m&\x1b[0m/g'
