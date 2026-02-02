#============================================================
# Genus "study-grade" synthesis script (timing/area/power)
# - Clean outputs per RUN_TAG
# - Activity annotation (SAIF preferred, else VCD)
# - Setup + Min(delay) timing reports (min ~= hold-style)
# - License-safe: optional commands wrapped in catch
#============================================================

# --------------------------
# User knobs
# --------------------------
set LIB_SLOW   "/home/install/FOUNDRY/digital/45nm/dig/lib/slow.lib"
set RTL_LIST   [list \
  "mac_unit.sv" \
  "systolic_array.sv" \
]

set TOP_DESIGN "systolic_array"
set SDC_FILE   "constraints.sdc"

# Activity inputs (optional)
set VCD_FILE   "activity.vcd"
set VCD_SCOPE  "systolic_array_tb.dut"

set SAIF_FILE  "activity.saif"
set SAIF_SCOPE "systolic_array_tb.dut"

# Tag per run to avoid overwrites (ex: N16_K1024)
set RUN_TAG    "RUN"
set OUTDIR     "genus_out/${RUN_TAG}"
set RPTDIR     "${OUTDIR}/reports"

# --------------------------
# Housekeeping
# --------------------------
file mkdir $OUTDIR
file mkdir $RPTDIR

# --------------------------
# Read libraries + RTL
# --------------------------
read_libs $LIB_SLOW

# Optional: library reporting (may be license-gated)
if {[catch {report_libs > ${RPTDIR}/libs.rep} _msg]} {
  puts "INFO: report_libs unavailable (license). Skipping."
}

foreach f $RTL_LIST {
  read_hdl -sv $f
}

set_db top $TOP_DESIGN
elaborate $TOP_DESIGN

check_design -unresolved > ${RPTDIR}/check_unresolved.rep

# --------------------------
# Constraints
# --------------------------
read_sdc $SDC_FILE

# --------------------------
# Synthesis effort knobs
# --------------------------
set_db syn_generic_effort medium
set_db syn_map_effort     medium
set_db syn_opt_effort     medium

# --------------------------
# Synthesis flow
# --------------------------
syn_generic
syn_map
syn_opt

# --------------------------
# Post-synth checks
# --------------------------
check_design -summary > ${RPTDIR}/check_summary.rep
report_messages -severity {warning error} > ${RPTDIR}/messages_warn_err.rep

# --------------------------
# Activity annotation (SAIF preferred, else VCD)
# --------------------------
set ACT_SRC "none"
set ACT_NOTE ""

if {[file exists $SAIF_FILE]} {
  puts "INFO: Found SAIF: $SAIF_FILE (scope=$SAIF_SCOPE)"
  if {[catch {read_saif $SAIF_FILE -scope $SAIF_SCOPE} _msg]} {
    puts "WARN: read_saif failed: $_msg"
  } else {
    set ACT_SRC "saif"
  }
} elseif {[file exists $VCD_FILE]} {
  puts "INFO: Found VCD: $VCD_FILE (scope=$VCD_SCOPE)"
  if {[catch {read_vcd $VCD_FILE -scope $VCD_SCOPE} _msg]} {
    puts "WARN: read_vcd failed: $_msg"
  } else {
    set ACT_SRC "vcd"
  }
} else {
  puts "WARN: No SAIF/VCD found. Power will use default activity assumptions."
  set ACT_SRC "none"
}

# Stamp evidence for your report/debug
set fh [open "${OUTDIR}/activity_used.txt" "w"]
puts $fh "ACT_SRC=${ACT_SRC}"
puts $fh "VCD_FILE=${VCD_FILE}"
puts $fh "VCD_SCOPE=${VCD_SCOPE}"
puts $fh "SAIF_FILE=${SAIF_FILE}"
puts $fh "SAIF_SCOPE=${SAIF_SCOPE}"
close $fh

# --------------------------
# TIMING (Setup + Min/hold-style)
# --------------------------
# Setup (max delay)
report_timing_summary                > ${RPTDIR}/timing_setup_summary.rep
report_timing -delay_type max -max_paths 20 -sort_by slack \
                                     > ${RPTDIR}/timing_setup_top20.rep

# Min-delay (hold-style view)
report_timing_summary -delay_type min > ${RPTDIR}/timing_min_summary.rep
report_timing -delay_type min -max_paths 20 -sort_by slack \
                                     > ${RPTDIR}/timing_min_top20.rep

# Constraints / DRV checks
report_constraints -all_violators     > ${RPTDIR}/constraints_violators.rep
report_design_rules                   > ${RPTDIR}/design_rules.rep

# Clocks + QoR
report_clocks                         > ${RPTDIR}/clocks.rep
report_qor                            > ${RPTDIR}/qor.rep

# --------------------------
# AREA / COUNTS
# --------------------------
report_area                           > ${RPTDIR}/area_summary.rep
report_area -hier                     > ${RPTDIR}/area_hier.rep
report_gate_count                     > ${RPTDIR}/gate_count.rep
report_summary                        > ${RPTDIR}/summary.rep

# --------------------------
# POWER (activity-based if ACT_SRC != none)
# --------------------------
report_power                          > ${RPTDIR}/power_summary.rep
report_power -hier                    > ${RPTDIR}/power_hier.rep

# --------------------------
# Write artifacts
# --------------------------
write_hdl                             > ${OUTDIR}/${TOP_DESIGN}_mapped_netlist.sv
write_sdc                             > ${OUTDIR}/${TOP_DESIGN}_exported.sdc

puts "DONE: Outputs in $OUTDIR"
exit




