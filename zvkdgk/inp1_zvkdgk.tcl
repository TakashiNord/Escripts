

package require tclodbc
package require sqlite3

proc LogWrite  { s } {
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}

proc GetElem { fpid level } {
  global db1
  set sql4 "select DeviceBase.DeviceBaseId as id, DeviceBase.ParentDeviceId as pid,DeviceBase.DeviceTypeId as tid, DeviceVersion.Name as name \
      from  DeviceBase , DeviceVersion where DeviceVersion.DeviceBaseId=DeviceBase.DeviceBaseId and DeviceBase.ParentDeviceId=$fpid"

#  db1 eval $sql4 recs2 {
#    set sz [ array size recs2 ]
# if {$sz<=1} { break ; }
#    set st [ string repeat " " $level ]
#    LogWrite "$st $recs2(id) $recs2(name)"
# set p [ expr $level+1 ]
#    GetElem $recs2(pid) $p
#  }

  set st [ string repeat " " $level ]
  set recs2 [ db1 eval $sql4 ] ;
  for { set i 0} {$i<[llength $recs2]} {incr i 4} {
    set id [lindex $recs2 $i]
    set name [lindex $recs2 [expr $i+3]]
    LogWrite "$st $id  $name"
    set p [ expr $level+2 ]
    set ret [ GetElem $id $p ]
  }

  return 0
}


# ===============================================
proc  main { } {
# ===============================================
  global db1
  global db2
  global own
  global rf

  # avtorization
  set tns "rsdu2"
  set usr "rsduadmin" ; # sys "rsduadmin" admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1"

# Устанавливаем соединение к БД
#  database db2 $tns $usr $pwd
#  db2 set autocommit off

# открываем - создаем бд
  set phdb "D:\\DBsqlite\\zvkdgk.db"

  sqlite3 db1 $phdb ;# associate the SQLite database with the object

# Амурская генерация  «Амурская генерация»  71
# АО «ДГК»  АО «ДГК»  72
# ЦЭС ХЭ  СП ЦЭС ХЭС ДРСК 77
# ТЭЦ Океанариум  ТЭЦ Океанариум  78
# Восточная ТЭЦ Восточная ТЭЦ 79
# ОДИАС ПЭС ДРСК  ОДИАС ПЭС ДРСК  81
# СЭС ПЭС ДРСК  СЭС ПЭС ДРСК  82
# ЦЭС ПЭС ДРСК  ЦЭС ПЭС ДРСК  83
# ХабРДУ  Хабаровское РДУ 84
# ОДУ В ОДУ Востока 85
# Мини ТЭЦ Центральная  ТЭЦ Центральная 91
# Амурский ЦУС  ЦУС Амурского ПМЭС  114
# БурГЭС  Бурейская ГЭС 115
# ЗейГЭС  Зейская ГЭС 116
# ХбТЭЦ3  Хабаровская ТЭЦ-3 134
# КмТЭЦ3  Комсомольская ТЭЦ-3 135
# ХбТЭЦ1  Хабаровская ТЭЦ-1 136
# МайГРЭС Майская ГРЭС  137
# КмТЭЦ2  Комсомольская ТЭЦ-2 138
# КмТЭЦ1  Комсомольская ТЭЦ-1 139
# АмТЭЦ1  Амурская ТЭЦ-1  140
# ПаГРЭС  Партизанская ГРЭС 143
# ВТЭЦ-2  Владивостокская ТЭЦ-2 144
# АТЭЦ  Артемовская ТЭЦ 145
# ПримГРЭС  Приморская ГРЭС 191
# РайГРЭС Райчихинская ГРЭС 192
# БлТЭЦ Благовещенская ТЭЦ  193
# Хаб ДГК ОАО ДГК Хабаровская генерация 194
# НеГРЭС  Нерюнгринская ГРЭС  197
# ЧуТЭЦ Чульманская ТЭЦ 201
# Головной ЦУС  Головной ЦУС  208
# МГТЭС Мобильные ГТЭС  215
# ПТС Приморские тепловые сети  216
# Приморский ЦУС  ЦУС Приморского ПМЭС  219
# ПримРДУ Приморское РДУ  220
# ОАО "ДГК" ДГК 336
# Хабаровский ЦУС ЦУС Хабаровского ПМЭС 337
# «Амурская генерация»  «Амурская генерация»  349
# АмурРДУ Амурское РДУ  350
# Совгаванская ТЭЦ  Совгаванская ТЭЦ  352
# "Амурская генерация"  "Амурская генерация"  362
# "Хабаровская генерация" "Хабаровская генерация" 363

  set PowerObject [ list  134 135 136 137 138 139 140 143 144 145 191 192 193 197 201 352 ]

  #set PowerObjectId 134 ;
  foreach PowerObjectId $PowerObject {

    set namefile "zvkdgk.txt"
    set sql0 "select Ident, Name, PowerObjectId from PowerObject where PowerObjectId=$PowerObjectId"
    db1 eval $sql0 recd {
      set namefile $recd(Name)
    }


    # лог - файл
    set ph [info script]
    set md "a+"
    if {$ph==""} {
       set ph inp_zvkdgk.log
    } else {
       set p1 [ file dirname $ph ] ; # [file dirname /foo/bar/grill.txt] -> /foo/bar
       set ph [ file join $p1 zvkdgk_${namefile}.log ]
       #set ph [file rootname $ph ].log
       set md "w+"
    }
    set rf [ open $ph $md ]


    set sql1 "Select PowerObjectDeviceId , DeviceId from  PowerObjectDevice where PowerObjectId=$PowerObjectId"
    set sql2 "Select DeviceBaseId , ParentDeviceId from  DeviceBase where DeviceBaseId="
    set sql3 "select DeviceBaseId, DeviceTypeId from  DeviceBase where DeviceBase.ParentDeviceId is null and \
      DeviceBase.DeviceBaseId in (select DeviceId from  PowerObjectDevice where PowerObjectDevice.PowerObjectId=$PowerObjectId )"

    set sql33 "Select DeviceBase.DeviceBaseId as id, DeviceBase.ParentDeviceId as pid,DeviceBase.DeviceTypeId as tid, DeviceVersion.Name as name \
     from  DeviceBase , DeviceVersion where DeviceBase.ParentDeviceId is null and \
     DeviceBase.DeviceBaseId in (select DeviceId from  PowerObjectDevice where PowerObjectDevice.PowerObjectId=$PowerObjectId ) \
     and DeviceVersion.DeviceBaseId=DeviceBase.DeviceBaseId"

    global recs1
    # building tree
    set recs1 [ db1 eval $sql33 ] ;
    #LogWrite $recs1
    set st ""
    for { set i 0} {$i<[llength $recs1]} {incr i 4} {
      set id [lindex $recs1 $i]
      set name [lindex $recs1 [expr $i+3]]
      LogWrite "\n$st $id  $name"
      set ret [ GetElem $id 1 ]
    }


    close $rf

  }

  db1 close

# Закрываем соединение к БД
#  db2 commit
#  db2 disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"



  return 0 ;
}

  main
