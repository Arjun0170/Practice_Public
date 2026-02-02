# Cadence Genus(TM) Synthesis Solution, Version 21.14-s082_1, built Jun 23 2022 14:32:08

# Date: Wed Jan 28 12:54:16 2026
# Host: encmitcad19 (x86_64 w/Linux 4.18.0-425.3.1.el8.x86_64) (20cores*28cpus*1physical cpu*Intel(R) Core(TM) i7-14700 33792KB)
# OS:   Red Hat Enterprise Linux release 8.7 (Ootpa)

set LIB_SLOW   "/home/install/FOUNDRY/digital/45nm/dig/lib/slow.lib"
set RTL_LIST   [list \
  "mac_unit.sv" \
  "systolic_array.sv" \
]
set TOP_DESIGN "systolic_array"
set SDC_FILE   "constraints.sdc"
set VCD_FILE   "activity.vcd"
set VCD_SCOPE  "systolic_array_tb.dut"
set SAIF_FILE  "activity.saif"
set SAIF_SCOPE "systolic_array_tb.dut"
set RUN_TAG    "RUN"
set OUTDIR     "genus_out/${RUN_TAG}"
set RPTDIR     "${OUTDIR}/reports"
file mkdir $OUTDIR
file mkdir $RPTDIR
read_libs $LIB_SLOW
if {[catch {report_libs > ${RPTDIR}/libs.rep} _msg]} {
  puts "INFO: report_libs unavailable (license). Skipping."
}
foreach f $RTL_LIST {
  read_hdl -sv $f
}
set_db top $TOP_DESIGN
elaborate $TOP_DESIGN
check_design -unresolved > ${RPTDIR}/check_unresolved.rep
read_sdc $SDC_FILE
set_db syn_generic_effort medium
set_db syn_map_effort     medium
set_db syn_opt_effort     medium
syn_generic
syn_map
syn_opt
check_design -summary > ${RPTDIR}/check_summary.rep
report_messages -severity {warning error} > ${RPTDIR}/messages_warn_err.rep
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
set fh [open "${OUTDIR}/activity_used.txt" "w"]
puts $fh "ACT_SRC=${ACT_SRC}"
puts $fh "VCD_FILE=${VCD_FILE}"
puts $fh "VCD_SCOPE=${VCD_SCOPE}"
puts $fh "SAIF_FILE=${SAIF_FILE}"
puts $fh "SAIF_SCOPE=${SAIF_SCOPE}"
close $fh
report_timing_summary                > ${RPTDIR}/timing_setup_summary.rep
report_timing -delay_type max -max_paths 20 -sort_by slack \
                                     > ${RPTDIR}/timing_setup_top20.rep
report_timing_summary -delay_type min > ${RPTDIR}/timing_min_summary.rep
report_timing -delay_type min -max_paths 20 -sort_by slack \
                                     > ${RPTDIR}/timing_min_top20.rep
report_constraints -all_violators     > ${RPTDIR}/constraints_violators.rep
report_design_rules                   > ${RPTDIR}/design_rules.rep
report_clocks                         > ${RPTDIR}/clocks.rep
report_qor                            > ${RPTDIR}/qor.rep
report_area                           > ${RPTDIR}/area_summary.rep
report_area -hier                     > ${RPTDIR}/area_hier.rep
report_gate_count                     > ${RPTDIR}/gate_count.rep
report_summary                        > ${RPTDIR}/summary.rep
report_power                          > ${RPTDIR}/power_summary.rep
report_power -hier                    > ${RPTDIR}/power_hier.rep
write_hdl                             > ${OUTDIR}/${TOP_DESIGN}_mapped_netlist.sv
write_sdc                             > ${OUTDIR}/${TOP_DESIGN}_exported.sdc
puts "DONE: Outputs in $OUTDIR"
exit
