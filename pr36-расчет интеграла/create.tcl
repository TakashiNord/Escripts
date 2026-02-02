

set f [ open "C:\\Tcl\\table.dat" w ]

for {set i 0} { $i<3600} {incr i} {
  set randNum [expr { int(100 * rand()) }]
  puts $f $randNum

} 

if {[catch {close $f} err]} {
    puts "ls command failed: $err"
}


