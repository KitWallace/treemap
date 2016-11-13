import module namespace tp = "http://kitwallace.co.uk/lib/tp" at "lib/tp-dev.xqm";
import module namespace geo="http://kitwallace.me/geo" at "/db/lib/geo.xqm";

(:
http://treesofbristol.space/mobile.xq?lat=51.4780417&long=-2.5898586
:)

let $filter := tp:get-filter()  
let $selecting := exists($filter/tag) or exists ($filter/latin)
let $position := if (exists($filter/latitude)) then geo:LatLong($filter/latitude,$filter/longitude) else ()
let $nv := request:get-parameter("n",())
let $n := if ($nv="undefined") then 1 else if (exists($nv)) then number($nv) else 1
let $strees :=
  if (exists($filter/id))
  then 
       tp:get-tree-by-id($filter/id)   
  else if (exists($position) and $selecting)
  then 
       tp:nearest-trees($filter,xs:double($position/@latitude),xs:double($position/@longitude), $n)    
  else ()

let $strees := 
    for $tree in $strees
    let $distance :=
          if ($tree/latitude)
          then
             let $treeposition := geo:LatLong($tree/latitude,$tree/longitude)
             return geo:plain-distance($position, $treeposition) * 1852 (: meters :)
          else 0
    let $direction :=
           if ($tree/latitude)
           then 
             let $treeposition := geo:LatLong($tree/latitude,$tree/longitude)
             return round(geo:plain-direction($position,$treeposition))
           else 0
    return
       element tree {
          if ($distance >0 )
          then (attribute distance {$distance}, attribute direction {$direction} )
          else (),
               $tree/*
       }
       
let $serialize := util:declare-option("exist:serialize","method=xhtml media-type=text/html")
return
<div>
  <div class="latlong">
    {if ($filter/latitude) then
    let $lat-d := xs:string(round-half-to-even(xs:double($position/@latitude),6))
    let $long-d :=  xs:string(round-half-to-even(xs:double($position/@longitude),6)) 
    return 
      <div>
        <a target="_blank" class="external" href="http://www.google.com/maps/place/{$lat-d},{$long-d}/@{$lat-d},{$long-d},18z/data=!3m1!1e3">{$lat-d},{$long-d}</a>
      </div>

    else ()
    } 
  </div>
  <hr/>
   

 {if (exists($strees)) 
  then 
        if (count($strees) > 1 )
        then
             tp:trees-to-mobile-table($strees)
        else tp:tree-to-mobile-table($strees[1])
   else if ($selecting)
   then <div>no trees found</div>
   else <div>you need to choose a collection or a species</div>      
 }
</div>
