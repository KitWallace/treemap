import module namespace tp = "http://kitwallace.co.uk/lib/tp" at "lib/tp.xqm";

let $format := request:get-parameter("format","html")
let $mode  := request:get-parameter("mode","home")
let $filter := tp:get-filter()            
let $strees := 
     if (exists($filter/*) and $mode= ("select","view"))
     then tp:apply-filter($filter)
     else ()
let $ntrees := count($strees)    
let $log := tp:log("treehtml")
return 

if ($format="html") 
then
let $serialize := util:declare-option("exist:serialize","method=xhtml media-type=text-html")
return 

<html>
  <head>
  <title>Trees of Bristol</title>
    <meta charset="UTF-8"/>
    <link rel="stylesheet" type="text/css"
            href="https://fonts.googleapis.com/css?family=Merriweather Sans"/>
    <link rel="stylesheet" type="text/css"
            href="https://fonts.googleapis.com/css?family=Gentium Book Basic"/>
    <script type="text/javascript" src="assets/sorttable.js"></script> 
    <script src="https://maps.googleapis.com/maps/api/js?key={$tp:googlekey}"></script> 
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <link href="http://kitwallace.co.uk/trees/assets/BTF.png" rel="icon" sizes="128x128" />
    <link rel="shortcut icon" type="image/png" href="http://kitwallace.co.uk/trees/assets/BTF.png"/>
    <link rel="stylesheet" type="text/css" href="assets/base.css" media="screen" ></link>
    {if ($ntrees > 3000)
    then()
    else
    <script type="text/javascript">
var markers = [
   { string-join(
       for $tree in $strees
       let $text := replace($tree/text,"'","\\'")
       let $name := replace($tree/name,"'","\\'")
       let $title :=  concat($tree/id," : ",$name) 
       let $icon := if (matches($tree/state,"stump","i"))
                    then "http://maps.google.com/mapfiles/kml/pal4/icon25.png" 
                    else if (matches($tree/state,"group","i") )
                    then "http://maps.google.com/mapfiles/kml/pal2/icon4.png"
                    else "http://maps.google.com/mapfiles/kml/pal2/icon12.png"
       let $description :=  util:serialize(
         <div><h1><a href="?mode=view&amp;id={$tree/id}">{if ($tree/name) then $name else $tree/id/string()}</a>{if ($tree/altname) then concat(" or ", replace($tree/altname,"'","\\'")) else() }</h1><div><em>{replace($tree/latin/string(),"'","\\'")}</em>&#160;{$text}</div></div>,
          "method=xhtml media-type=text/html indent=no") 


       where exists($tree/latitude)
       return
          concat("['",$title,"',",
                  $tree/latitude/string(),",",$tree/longitude/string(),
                  ",'",$description,"','",$icon,"']")
       ,",&#10;")
     }
     ];

var centre =  new google.maps.LatLng(51.467425,-2.575213);

</script> 
   }
    <script type="text/javascript" src="assets/map.js"></script> 
 
     </head>
    <body onload="initialize()">

   <h1><a href="?">Trees of Bristol</a>  
       <span style="font-size: smaller">
           &#160; <a href="?mode=collections">Collections</a>         
           &#160; <a href="?mode=species-list">Species</a>         
           &#160; <a href="?mode=search">Search</a>         
           &#160; <a href="?mode=links">Links</a>           
       </span>    
  </h1>
  <hr/>

  {if ($mode="home") then 
   <div>
     {tp:doc("about")}   
   </div>
  else if ($mode="links")
  then <div>    
     {tp:doc("links")}
   </div>
 else if ($mode="collections")
  then <div>
    
     {tp:collections($tp:taglist)}
   </div>
  else if ($mode = "search")
  then 
  <div>
  <b>{$ntrees} match{if ($ntrees = 1) then "" else  "es" }</b>
  {tp:filter-form($filter)}
  </div>
  else 
  if ($mode = "species-list")
  then tp:species-list()
  else 
  if ($mode = "species")
  then tp:species-page($filter/latin)
  else 
  if ($mode="select" and $ntrees > 0)
  then 
     <div id="map_text">
        <div><a href="?mode=search&amp;{tp:filter-to-params($filter)}">Filter: </a> {tp:show-filter($filter)}</div>
        <hr/>
 
        {tp:trees-to-table($strees)}
     </div>
  else if ($mode="view" and $ntrees=1)
  then
    <div id="map-text">
      <div><a href="?mode=search&amp;{tp:filter-to-params($filter)}">Filter: </a> {tp:show-filter($filter)}</div>
      <hr/>
      {tp:tree-to-html($strees[1])}
    </div>
  else 
    <div><b>No matches</b>
      {tp:filter-form($filter)}
    </div>
  }
  {if ($ntrees> 0 and $ntrees <3000)
  then <div id="map_canvas" >
       </div>
   else()
  }
  </body>

</html>
else if ($format="xml" and count($strees) >0)
then element result {$strees}
else if ($format ="kml" and count($strees) >0)
then tp:trees-to-kml($strees)
else if ($format = "csv" and count($strees) > 0)
then let $serialize := util:declare-option("exist:serialize","method=text media-type=text/plain")
     return  tp:trees-to-csv($strees)
else ()
  
