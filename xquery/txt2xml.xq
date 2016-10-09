import module namespace geo="http://kitwallace.me/geo" at "/db/lib/geo.xqm";

let $filename := "/db/apps/trees/data/BristolTrees.txt"
let $text := util:binary-to-string(util:binary-doc($filename))    
let $paras := tokenize($text,"&#10;")
let $trees :=

 element trees 
   {for $p in $paras
    let $p := replace($p,"&#65533;","'")
    let $sentences := tokenize($p,"\.")
    let $idtext := normalize-space($sentences[1])
    let $idval :=replace($idtext,"-",".")
    where $idval castable as xs:float and count($sentences) > 3
    return
     let $phrases1 := tokenize($sentences[2],",")
     let $latin := $phrases1[last()]
     let $names := tokenize(string-join(subsequence($phrases1,1,count($phrases1)-1),", ")," or ")
     let $phrases2 := tokenize($sentences[3],",")
     let $gridtext:= normalize-space($sentences[3])
     let $girth:= tokenize(replace($p,"girth.*?\s(\d+)cm","xxx$1xxx","i"),"xxx")[2]
     let $age:= tokenize(replace($p,"age.*?\s(\d+)\D","xxx$1xxx","i"),"xxx")[2]
     
     let $grid := replace($gridtext," ","")
     let $os := if (matches($grid,"^\w\w\d\d\d\d\d\d\d\d$"))
                then geo:Grid-to-OS($grid)
                else ()
     let $ll:= if ($os) then geo:OS-to-LatLong($os) else ()
     let $text := if ($os) 
                  then string-join(subsequence($sentences,4),". ")
                  else string-join(subsequence($sentences,3),". ")
     let $tag := if (number($idval) <= 51) then "Veteran"
                 else if (number($idval) <=182) then "Champion"
                 else "Remarkable"
     return
      element tree {
         element id {concat("RB-",replace($idtext,"[,&amp;]","-"))},
         element name {normalize-space($names[1])},
         if (count($names) > 1 ) then element altname {normalize-space($names[2])} else (),
         element latin {normalize-space($latin)},
         element tag {$tag},
         element text {normalize-space($text)},

         if ($girth ne "") then element girth {$girth} else (),
         if ($age ne "") then element age {$age} else (),
         if (exists($os))
         then 
         (element grid {$gridtext},
          element easting {$os/@easting/string()},
          element northing {$os/@northing/string()},
          element latitude {round-half-to-even(number($ll/@latitude),6)},
          element longitude {round-half-to-even(number($ll/@longitude),6)}
           )
          else ()
      }
     }
 
let $store := xmldb:store("/db/apps/trees/data","trees.xml",$trees)
return 
<result>{$store} - {count($trees/tree)} trees saved </result>
