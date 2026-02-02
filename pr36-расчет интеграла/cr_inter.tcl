
set a 2700
set b 3600
set n 900
set h [ expr ($b-$a)/$n ]

set f [ open "C:\\Tcl\\table.dat" r ]

set i 0
set s 0.0
while {1} {
    set line [gets $f]
    if {[eof $f]} {
        close $f
        break
    }
	if {$i>=[ expr $a ]} { 
	   set v1 [ scan $line "%f" v ]
	   if {$i==$a} { set v [ expr $v/2.0] }
	   if {$i==[ expr $b-1 ]} { set v [ expr $v/2.0] }
	   set s [ expr $s + $v]
	}
	if {$i==[ expr $b-1 ]} { break }
    incr i
}
set Integral1 [ expr $s*$h ]
puts "Integral1=$Integral1"
set Integral2 [ expr $Integral1/$n ]
puts "Integral2=$Integral2"

if {[catch {close $f} err]} {
    puts "ls command failed: $err"
}

