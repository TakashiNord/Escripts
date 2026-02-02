package require tdom
package require asn

set filename "C:\\rsdu\\Default.XPst"
set xpath {//category[@password]}

set size [file size $filename] 
set f [open $filename]
#fconfigure $f -encoding ascii
set xml [read $f $size ]
close $f

# set data [encoding convertfrom cp1251 $xml]

set doc [dom parse $xml]
set root [$doc ocumentElement]

# Do the update of the in-memory doc
foreach pollerAttr [$root selectNodes $xpath] {
    $pollerAttr setAttribute password "theNewPassword"
}

# Write out (you might or might not want the -doctypeDeclaration option)
set f [open "${filename}_t.xml" "w"]
$doc asXML -channel $f -doctypeDeclaration true
close $f


