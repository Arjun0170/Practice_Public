#===========================================================
# systolic_array.sdc  (Genus)
# Synthesis-level constraints for a synchronous compute core
#===========================================================

# ---------------------------
# User knobs
# ---------------------------
set CLK_PORT       clk
set CLK_PERIOD_NS  2.000          ;# <-- change per run (ns). Example: 2ns = 500MHz
set CLK_UNCERT_NS  0.050          ;# clock uncertainty (ns) - small but non-zero
set IN_DELAY_NS    0.200          ;# generic input delay (ns)  (only matters if you time IO)
set OUT_DELAY_NS   0.200          ;# generic output delay (ns) (only matters if you time IO)

# ---------------------------
# Create clock
# ---------------------------
create_clock -name core_clk -period $CLK_PERIOD_NS [get_ports $CLK_PORT]
set_clock_uncertainty $CLK_UNCERT_NS [get_clocks core_clk]

# (Optional) Model a realistic clock transition
# set_clock_transition 0.050 [get_clocks core_clk]

# ---------------------------
# Reset handling
# ---------------------------
# rst is treated as asynchronous or non-timed for synthesis STA purposes.
# Prevent reset paths from contaminating timing.
set_false_path -from [get_ports rst]
set_false_path -to   [get_ports rst]

# ---------------------------
# I/O constraints (lightweight)
# ---------------------------
# For a compute-core study, you usually do NOT want aggressive IO timing closure.
# Still, providing small delays helps the tool avoid assuming zero delay.

# Inputs (exclude clk and rst)
set ALL_IN  [remove_from_collection [all_inputs]  [get_ports "$CLK_PORT rst"]]
set ALL_OUT [all_outputs]

# Apply generic IO delays relative to the core clock
set_input_delay  $IN_DELAY_NS  -clock core_clk $ALL_IN
set_output_delay $OUT_DELAY_NS -clock core_clk $ALL_OUT

# (Optional) If you want to treat data ports as ideal/untimed (common for IP blocks):
# Uncomment these to ignore IO timing on wide buses and focus on internal paths.
# set_false_path -from [get_ports {input_matrix[*] weight_matrix[*]}]
# set_false_path -to   [get_ports {output_matrix[*] cycles_count[*] compute_done}]

# ---------------------------
# Basic design-rule constraints (helps QoR)
# ---------------------------
# Keep these mild unless you have library guidance.
set_max_transition 0.150 [current_design]     ;# ns
set_max_fanout     32    [current_design]

# If your library is slow or you see aggressive buffering, relax these.

# ---------------------------
# Misc sanity
# ---------------------------
# Tell tool to consider clocks ideal for now (Genus will still optimize datapaths).
# (No additional constraints needed.)

# End of file



