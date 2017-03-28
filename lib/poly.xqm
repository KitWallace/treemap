module namespace poly = "http://kitwallace.co.uk/lib/poly";
declare namespace kml = "http://www.opengis.net/kml/2.2";
import module namespace math ="http://exist-db.org/xquery/math" at "org.exist.xquery.modules.math.MathModule";

declare function poly:point($lat,$long) {
    element point  {
        attribute latitude {$lat},
        attribute longitude {$long}
    }
};
declare function poly:kml-placemark-to-polygons($placemark) {
  for $polygon at $i in $placemark//kml:Polygon
  let $path := $polygon//kml:coordinates
  return poly:kml-coordinates-to-polygon($path)
};

declare function poly:kml-coordinates-to-polygon($coordinates) {
  element polygon {
     for $point in  tokenize($coordinates," ")
     let $p := tokenize($point,",")
     return 
        element point {attribute latitude {$p[2]},attribute longitude {$p[1]} }
  }
};

declare function poly:polygon-to-kml-coordinates($polygon) {
    string-join(
         for $point in $polygon/point
         return concat($point/@longitude,",",$point/@latitude)
         ," ")
};

declare function poly:polygon-bounding-box($poly) {
  element box {
         element top-left {
                 element point {
                       attribute latitude {max($poly/point/@latitude) },
                       attribute longitude {min($poly/point/@longitude) }
                  }
         },
         element bottom-right {
                 element point {
                      attribute latitude {min($poly/point/@latitude) },
                      attribute longitude {max($poly/point/@longitude) }
                 }
         }
  }
};

declare function poly:polygon-centroid($polygon) {
   let $n:= count($polygon/point) - 1  (: dont double count the repeated point :)
   let $lat := sum(subsequence($polygon/point,2)/@latitude) div $n
   let $long := sum(subsequence($polygon/point,2)/@longitude) div $n
   return poly:point($lat,$long) 
};

declare function poly:boxes-bounding-box($boxes){
   element box {
         element top-left {element point {attribute latitude {max($boxes//point/@latitude) },
                           attribute longitude {min($boxes//point/@longitude) }
                           }},
         element bottom-right {element point {attribute latitude {min($boxes//point/@latitude) },
                                attribute longitude {max($boxes//point/@longitude) }
                             } }
        }
};

declare function poly:point-in-box($point,$box) {
   ($point/@latitude >= xs:double($box/bottom-right/point/@latitude)) and
   ($point/@latitude <= xs:double($box/top-left/point/@latitude)) and
   ($point/@longitude <= xs:double($box/bottom-right/point/@longitude)) and
   ($point/@longitude >= xs:double($box/top-left/point/@longitude) )
};

declare function poly:box-area($box) {
(: in  m2  :)
   let $longcorr := math:cos(math:radians(($box/bottom-right/point/@latitude + $box/top-left/point/@latitude) div 2))
   let $dlat := ($box/top-left/point/@latitude - $box/bottom-right/point/@latitude) * 60 * 1852 
   let $dlong := ($box/bottom-right/point/@longitude - $box/top-left/point/@longitude)  * 60 * 1852  *  $longcorr
   return round($dlat * $dlong)
};
            
declare function poly:box-to-polygon($box) {
   element polygon {
       $box/top-left/point,
       element point{$box/top-left/point/@latitude, $box/bottom-right/point/@longitude},
       $box/bottom-right/point,
       element point{$box/bottom-right/point/@latitude,$box/top-left/point/@longitude},
       $box/top-left/point
   }
};


declare function poly:polygon-is-closed($polygon) {
    $polygon/point[1]/@latitude = $polygon/point[last()]/@latitude and
    $polygon/point[1]/@longitude = $polygon/point[last()]/@longitude 
};

declare function poly:polygon-to-kml($polygon,$name) {
   <Placemark>
       <name>{($name,$polygon/name,"Polygon")[1]}</name>
       <LineString>
       <coordinates>{poly:polygon-to-kml-coordinates($polygon)}</coordinates>
       </LineString>
   </Placemark>
};

declare function poly:polygons-to-kml($polygons,$name,$color) {
   <Placemark>
       <name>{($name,"Polygon")[1]}</name>
       	<Style><LineStyle><color>{$color}</color></LineStyle><PolyStyle><fill>0</fill></PolyStyle></Style>
         <MultiGeometry>
         {for $polygon in $polygons
          return 
             <Polygon><outerBoundaryIs><LinearRing>
                  <coordinates>{poly:polygon-to-kml-coordinates($polygon)}</coordinates>
                  </LinearRing></outerBoundaryIs>
             </Polygon>
         }
       </MultiGeometry>
   </Placemark>
};
declare function poly:point-to-kml($point,$name) {
     <Placemark>
       <name>{($name,"Point")[1]}</name>
       <Point>
           <coordinates>{concat($point/@longitude,",",$point/@latitude)}</coordinates>
       </Point>
     </Placemark>
};

declare function poly:close-polygon($polygon) {
    if (poly:polygon-is-closed($polygon))
    then $polygon
    else element polygon {
            $polygon/point,
            $polygon/point[1]
         }
};

declare function poly:poly-to-js($polygons) {
<script type="text/javascript">&#10;
{concat ("var polygons = [ &#10;",
 string-join(
  for $polygon at $i in $polygons
  return
    concat("[&#10;",
    string-join(
        for $point in $polygon/point
        return concat("{lat: ",$point/@latitude,", lng: ",$point/@longitude,"}")  
         ,",&#10;"
        )
    ,"]&#10;"
    )
  ,",&#10;"
  ),
"];&#10;"
)
}
</script>
};

declare function poly:is-left ($p0,$p1,$p2) {
    ($p1/@longitude - $p0/@longitude) * ($p2/@latitude - $p0/@latitude) -
    ($p2/@longitude - $p0/@longitude) * ($p1/@latitude - $p0/@latitude) 
};

declare function poly:point-in-polygon($point,$polygon)  {
(: assume polygon is closed
   compute winding number - if 0 then outside
:)
 sum(
    for $p in $polygon/point
    let $pn := $p/following-sibling::point[1]
    return
       if ($p/@latitude <= xs:double($point/@latitude))
       then if ($pn/@latitude > xs:double($point/@latitude))   (: upward crossing :)
            then if (poly:is-left($p,$pn,$point) > 0) (: p is left of edge :)
                 then 1
                 else 0
            else 0
            
       else if ($pn/@latitude <= xs:double($point/@latitude)) (: downward crossing :)
            then  if (poly:is-left($p,$pn,$point) < 0)  (: p is right of edge  :)
                 then -1
                 else 0
            else 0
      ) !=0    
};
declare function poly:point-distance-to-line($p,$a,$b) {
(: no longitude correction here - ? does it matter :)
    let $dx :=  $b/@latitude - $a/@latitude
    let $dy :=  $b/@longitude - $a/@longitude
    let $den := math:sqrt ($dx * $dx + $dy * $dy)
    let $num := math:abs($dy * $p/@latitude - $dx * $p/@longitude + $b/@latitude * $a/@longitude - $b/@longitude * $a/@latitude)
    return $num div $den
};

declare function poly:smooth-points($points,$epsilon) {
   let $n := count($points)
   return 
    if ($n <= 2)
    then $points
    else 
    let $start := $points[1]
    let $end := $points[last()]
    let $furthest :=
        (for $p at $i in subsequence($points,2, count($points)-2)
        let $d := poly:point-distance-to-line($p,$start,$end)
        order by $d descending
        return element index {attribute d {$d}, $i + 1}
        )[1]
    return 
        if ($furthest/@d < $epsilon)
        then ($start,$end)
        else let $k := xs:integer($furthest)
             return 
                let $s1 := poly:smooth-points(subsequence($points,1,$k),$epsilon)
                let $s2 := poly:smooth-points(subsequence($points,$k, $n - $k),$epsilon)
                return  
                   (subsequence($s1,1,count($s1)-1),$s2)
};

declare function poly:point-in-polygon($point,$polygon,$box) {
   if (poly:point-in-box($point,$box))
   then poly:point-in-polygon($point,$polygon)
   else false()
};

declare function poly:search-polygons($point,$polygons) {
   for $poly in $polygons
   where poly:point-in-polygon($polint,$poly)
   return $poly
};
