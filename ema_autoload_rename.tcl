#!/usr/bin/env tclsh

#===========================================
proc EMA_renameautoload { } {
#===========================================
  set fn1 [ glob /etc/init.d/rc*/*ema* ]
  foreach name $fn1 {
    set dir [file dirname $name]
    set fn [file tail $name]
    if {[string match -nocase "K*ema*" $fn]} {
      set fn2 [file join $dir "K01ema_autoload" ]
      if {0==[file exists $fn2]} { file rename -- $name $fn2 }
    }
    if {[string match -nocase "S*ema*" $fn]} {
      set fn2 [file join $dir "S99ema_autoload" ]
      if {0==[file exists $fn2]} { file rename -- $name $fn2 }
    }
  }
  set fn2 [ glob /etc/init.d/rc*/*ema* ]
}

EMA_renameautoload
