module namespace tp = "http://kitwallace.co.uk/lib/tp";
import module namespace geo="http://kitwallace.me/geo" at "/db/lib/geo.xqm";
import module namespace ui="http://kitwallace.me/ui" at "/db/lib/ui.xqm";
import module namespace math ="http://exist-db.org/xquery/math"  at "org.exist.xquery.modules.math.MathModule";
import module namespace log ="http://kitwallace.me/log" at "/db/lib/log.xqm";

declare namespace h = "http://www.w3.org/1999/xhtml";
declare variable $tp:googlekey  := "AIzaSyB-sB9Nwqkh-imfUd1-w3_lz4KFhL-_VqU";
declare variable $tp:host := "http://kitwallace.co.uk/trees";
declare variable $tp:base := "/db/apps/trees";
declare variable $tp:photostore := concat($tp:base,"/photos");
declare variable $tp:taglist := doc(concat($tp:base,"/ref/tags.xml"))/tags;
declare variable $tp:treepath := concat($tp:base,"/trees");

(: utility functions :)

declare function tp:replace($text,$replacements) {
   if (empty($replacements))
   then $text
   else
      let $r := tokenize($replacements[1],"%")
      let $rtext := fn:replace($text,$r[1],$r[2]) 
      return tp:replace($rtext , subsequence($replacements,2))
};

(: access functions :)

declare function tp:doc($name) {
    doc(concat($tp:base,"/docs/",$name,".xml"))
};

declare function tp:photopath($id) {
    concat($tp:host,"/photos/",$id)
};

declare function tp:get-trees() {
   collection(concat($tp:base,"/trees"))//tree
};

declare function tp:get-tree-by-id($id) {
   collection(concat($tp:base,"/trees"))//tree[id=$id]
};
declare function tp:get-geocoded-trees() {
   collection(concat($tp:base,"/trees"))//tree[latitude]
};
declare function tp:get-tree-by-tag($tag) {
   collection(concat($tp:base,"/trees"))//tree[tag=$tag]
};

declare function tp:get-tree-by-latin($latin) {
   collection(concat($tp:base,"/trees"))//tree[latin=$latin]
};

declare function tp:get-species() {
  doc(concat($tp:base,"/species/Species.xml"))//species
};
declare function tp:get-species-by-latin($latin){
   doc(concat($tp:base,"/species/Species.xml"))//species[latin=$latin]
};

declare function tp:get-entity($name){
   doc(concat($tp:base,"/ref/model.xml"))//entity[@name=$name]
};

declare function tp:get-tree-photos($treeid) {
   doc(concat($tp:base,"/ref/treephotos.xml"))/photos/photo[treeid=$treeid]
};


(: parse latinname :)

declare function tp:parse-latin($latin) {
    if (contains($latin," x "))
    then tp:parse-cross($latin)
    else tp:parse-noncross($latin)
};

declare function tp:parse-noncross($s) {
  let $parts := tokenize($s," ")
  let $genus := element genus {$parts[1]}
  let $species := if ($parts[2] and not (starts-with($parts[2],"'")))
                  then element species {$parts[2]}
                  else ()
  let $rest := if ($species)
               then string-join(subsequence($parts,3)," ")
               else string-join(subsequence($parts,2)," ")
  let $form := if (starts-with($rest,"f."))
               then element form {normalize-space(substring-after($rest,"f."))}
               else ()
  let $variety := if (starts-with($rest,"var."))
                  then element variety {normalize-space(tokenize($rest, " ")[2])}
                  else if (starts-with($rest,"var "))
                  then element variety {normalize-space(tokenize($rest, " ")[2])}
                  else ()
                  
  let $cultivar := if (starts-with($rest,"'"))
                   then element cultivar {substring($rest,2,string-length($rest)-2)}
                   else if ($rest = ("cv","cultivar"))
                   then element cultivar {}
                   else if ($variety)
                   then let $crest := normalize-space(substring-after($rest,$variety))
                        return
                          if (starts-with($crest,"'"))
                          then element cultivar {substring($crest,2,string-length($crest)-2)}
                          else  ()
                   else ()
                 
  return
     element latin {
        $genus,
        $species,
        $cultivar,
        $form,
        $variety
     }     
};

declare function tp:parse-cross($s){
    let $parts := tokenize($s," x ")
    let $genus := element genus {$parts[1]}
    let $crossp := tokenize($parts[2]," ")
    let $cross := element cross {$crossp[1]}
    let $cultivar := if ($crossp[2]) then element cultivar {string-join(subsequence($crossp,2)," ")} else ()
    return
       element latin {
         $genus,
         $cross,
         $cultivar
      }
};

declare function tp:clean-latin($latin) {
    if (contains($latin,"?")) 
    then substring-before($latin,"?")
    else if (ends-with ($latin,"cv"))
    then substring-before($latin,"cv")
    else $latin
};

(: tree location functions :)
declare function tp:nearest-trees($filter,$lat,$long,$n) {
    let $position := geo:LatLong($lat,$long)
    let $best_matches := 
            ( 
            for $tree in tp:apply-filter($filter)[latitude]
            let $treeposition := geo:LatLong($tree/latitude,$tree/longitude)
            let $distance := geo:plain-distance($treeposition,$position) * 1852 (: meters :)
            order by $distance
            return $tree
            )[ position() <= $n ]
     return $best_matches
};

declare function tp:trees-in-range($lat,$long,$range) {
    let $position := geo:LatLong($lat,$long)
    let $trees := 
            for $tree in tp:get-geocoded-trees()
            let $treeposition := geo:LatLong($tree/latitude,$tree/longitude)
            let $distance := geo:plain-distance($treeposition,$position) * 1852 (: meters :)
            where $distance <= $range
            order by $distance
            return $tree
     return $trees
};

declare function tp:trees-in-range($trees,$latitude,$longitude,$range) {
    let $position := geo:LatLong($latitude,$longitude)
    let $strees := 
            for $tree in $trees[latitude]
            let $treeposition := geo:LatLong($tree/latitude,$tree/longitude)
            let $distance := geo:plain-distance($treeposition,$position) * 1852 (: meters :)
            where $distance <= $range
            order by $distance
            return $tree
     return $strees
};

(: mobile pages :)
declare function tp:trees-to-mobile-table($trees) {
   <table class="sortable"> 
        {for $tree in $trees
       return
        <tr>
          <td><button type="button" onclick="get_tree_with_id('{$tree/id}')">{($tree/name,$tree/id)[1]/string()}</button> </td>
          <td>{round($tree/@distance)}m</td>
          <td>{$tree/@direction/string()}°  {geo:compass-point($tree/@direction)}</td>
         </tr>
      }  
   </table>
};

declare function tp:tree-to-mobile-table($tree) {
   let $gs := string-join(subsequence(tokenize($tree/latin," "),1,if (contains($tree/latin," x ")) then 3 else 2)," ")
   let $now := 2016
   let $namep := tokenize($tree/name,"\s*,\s*")
   let $common := $tree/name/string()
   let $species := tp:get-species-by-latin($tree/latin)
   return
<div>
       <table>
       <tr><th>Name</th><td class="big">{$common}</td></tr>
       <tr><th>Id</th><td>{$tree/id/string()}</td></tr>
       <tr><th>Distance</th><td>{round($tree/@distance)} metres</td></tr>
       <tr><th>Direction</th><td>{$tree/@direction/string()}° {geo:compass-point($tree/@direction)}</td></tr>
       {if (exists($tree/altname)) then 
          <tr><th>Other names</th><td>{$tree/altname/string()}</td></tr> else () 
       }
      {if (exists($tree/latin)) 
       then <tr><th>Latin name</th><td><em>{$tree/latin}</em></td></tr>
       else ()
       }
       {if (exists($tree/location))
       then <tr><th>Location</th><td>{$tree/location/string()}</td></tr>
       else ()
       }
       <tr><th>Tags</th><td>{string-join($tree/tag,",")}</td></tr>
       {if($tree/latitude) then 
          (
           <tr><th>Lat/Long</th><td>{$tree/latitude/string()},{$tree/longitude/string()}&#160; <a target="_blank" class="external" href="http://www.google.com/maps/place/{$tree/latitude},{$tree/longitude}/@{$tree/latitude},{$tree/longitude},18z/data=!3m1!1e3">GoogleMap</a></td></tr>)
       else ()
       }
      {if ($tree/girth) then <tr><th>Girth</th><td>{$tree/girth/string()}&#160;cm</td></tr> else ()}
      {if ($tree/age) then  <tr><th>Age</th><td>{$tree/age/string()}&#160;years  [about {$now - number($tree/age)}]</td></tr>  else ()}  
      {if ($tree/state) then <tr><th>State</th><td>{$tree/state/string()}</td></tr> else () }
      {if ($tree/text) then  <tr><th>Comment</th><td>{$tree/text/string()}</td></tr> else ()}
        <tr><th>Description</th><td>{$species/description/node()}</td></tr>
        <tr><th>Links</th><td><a target="_blank" class="external" href="https://en.wikipedia.org/wiki/{$gs}">Wikipedia</a>
        &#160;|&#160;<span><a href="edittree.xq?id={$tree[1]/id}">Edit</a></span>
        </td></tr>
       </table>
 </div>
 };
 
(: website constructors :)
 
 declare function tp:collections($taglist) {
 <div>
    <h2>Tree Collections</h2>
    <div> 
        <ul>
            {for $tag in $tp:taglist/tag
             order by $tag
             return
               <li><a href="?mode=select&amp;tag={$tag/name}">{$tag/name/string()}</a>&#160;{$tag/title/string()}
               &#160;from {if (starts-with($tag/source,"http")) 
                          then <a href="{$tag/source}">{$tag/source/@title/string()}</a> 
                          else $tag/source/string()
                          }
                  {if ($tag/contains)
                  then 
                       <ul>
                        {for $stag in $tag/contains/tag
                        return
                           <li><a href="?mode=select&amp;tag={$stag/name}">{$stag/name/string()}</a>&#160;{$stag/title/string()}</li>
                        }
                       </ul>
                 else ()
                 }
               </li>
            }
        </ul>
     </div>
 </div>
};

declare function tp:trees-to-table($trees) {
   let $ntrees := count($trees)
   return
   <div><b>{$ntrees} Tree{if ($ntrees = 1) then () else "s"}</b> <img width="30" source="../assets/Info_Symbol.png" title="Click on headings to sort, click on latin name for species info, the count to go directly to the trees"/>
     <table class="sortable"> 
      <tr><th width="15%">Id</th><th>Name</th><th>Girth cm</th><th>Description</th></tr>
      {for $tree in $trees
       let $description := ($tree/text,if ($tree/location != "") then $tree/location else (),$tree/tag)[1]
       return
        <tr>
         <td><a href="?mode=view&amp;id={$tree/id}">{$tree/id/string()}</a></td>
         <td>{$tree/name/string()}</td>
 <!--        <td><em>{$tree/latin/string()}</em></td> -->
         <td>{$tree/girth/string()}</td>
         <td>{$tree/location/string()}&#160;{substring($description,1,30)}&#160;{$tree/state/string()}&#160; {if (string-length($description) > 30) then "..." else ()}</td>
        </tr>
      }  
      </table>
   </div>
};

declare function tp:tree-to-table($tree) {
   let $plant-date := if (exists($tree/survey-date)  and exists($tree/age)) then number(substring($tree/survey-date,1,4)) - number($tree/age) else ()
   let $latin-parse := tp:parse-latin($tree/latin)
   let $latin := tp:clean-latin($tree/latin)
   let $namep := tokenize($tree/name,"\s*,\s*")
   let $common := $tree/name/string()
   let $species := tp:get-species-by-latin($tree/latin)
   let $latlong := if (exists($tree/latitude))
                   then geo:LatLong($tree/latitude,$tree/longitude)
                   else ()
   let $os := if ($latlong)
              then geo:round-Mercator(geo:LatLong-to-OS($latlong),0)
              else ()
   let $grid := if ($os)
                then geo:OS-to-Grid($os/@easting,$os/@northing,4)
                else ()
   return
<div>
       <br/>
       <h2>{$common}</h2>
       <br/>
       <table>
       <tr><th width="20%">ID</th><td>{$tree/id/string()}</td></tr>
       <tr><th>Common name</th><td>{$tree/name/string()} | <a href="?mode=select&amp;common={$tree/name}">Trees</a></td></tr>
       {if (exists($tree/altname)) then 
          <tr><th>Other names</th><td>{$tree/altname/string()}</td></tr> else () 
       }
       <tr><th>Latin name</th><td>{$latin}&#160;|&#160;<a href="?mode=select&amp;latin={$latin}">Trees</a>&#160;|&#160;<a href="?mode=species&amp;latin={$latin}">Species</a>&#160;|&#160;
          <a target="_blank" class="external" href="https://en.wikipedia.org/wiki/{concat($latin-parse/genus," ",$latin-parse/species)}">Wikipedia</a>     
          </td></tr> 
       <tr><th>Collection</th><td>{$tree/tag/string()} | <a href="?mode=select&amp;tag={$tree/tag}">Trees</a></td></tr>
       {if ($tree/latitude) then      
           <tr><th>Lat/Long</th><td>{$tree/latitude/string()},{$tree/longitude/string()}&#160;|&#160;
               <a target="_blank" class="external" href="http://www.google.com/maps/place/{$tree/latitude},{$tree/longitude}/@{$tree/latitude},{$tree/longitude},18z/data=!3m1!1e3">GoogleMap</a>&#160;|&#160;
               <a target="_blank" class="external" href="http://www.openstreetmap.org/#map=18/{$tree/latitude}/{$tree/longitude}">OpenStreetMap</a>
               </td></tr>
       else ()
       }
       {if ($os) 
        then <tr><th>Easting,Northing</th><td>{concat($os/@easting,",",$os/@northing)}</td></tr>
        else ()
       }
       {if ($grid) 
        then <tr><th>OS Grid</th><td>{$grid}</td></tr>
        else ()
       }
      {if ($tree/location) then <tr><th>Location</th><td>{$tree/location/string()}</td></tr> else ()}
      {if ($tree/girth) then <tr><th>Girth</th><td>{$tree/girth/string()}&#160;cm</td></tr> else ()}
      {if ($tree/height) then <tr><th>Height</th><td>{$tree/height/string()}&#160;m</td></tr> else ()}
      {if ($tree/width) then <tr><th>Width</th><td>{$tree/width/string()}&#160;m</td></tr> else ()}
      {if ($tree/age) then  <tr><th>Age</th><td>{$tree/age/string()}&#160;years  {if (exists($plant-date)) then concat("[ planted about ",$plant-date,"]") else ()}</td></tr>  else ()}  
      {if ($tree/state) then <tr><th>State</th><td>{$tree/state/string()}</td></tr> else ()}
      {if ($tree/survey-date) then <tr><th>Survey Date</th><td>{$tree/survey-date/string()}</td></tr> else ()}
      {if ($tree/text) then  <tr><th>Comment</th><td>{$tree/text/string()}</td></tr> else ()}
      {if ($species) 
       then <tr><th>Description</th><td>{$species/description/node()} </td></tr>
       else ()
      }
       <tr><th>Links</th><td>
        <a href="edittree.xq?id={$tree/id}" title="requires authentication">Edit</a></td></tr>
       </table>
 
 </div>
 };
 
declare function tp:species-list() {
let $species := tp:get-species()
return
  <div>
     <h2>{count($species)} Tree Species and Cultivars <img width="20" src="assets/Info_Symbol.png" title="Click on headings to sort, click on latin name for species info, click the count to go directly to the trees"/></h2>
      <table class="sortable"> 
      <tr><th>Latin Name</th><th>Count</th><th class="sorttable_alpha">Dictionary Name</th><th>Common Names</th></tr>
     {for $species in $species
      let $name := $species/common/string()
      let $namep := tokenize($name,"\s+")
      let $sname := if ($name = $species/latin)
                    then $name
                    else if (count($namep) = 1)
                    then $name
                    else if ($namep[last()] = ("Tree","tree"))
                    then $name
                    else if (contains($name, " of "))
                    then $name
                    else if (ends-with($namep[last()],"'"))
                    then let $last := for $p at $i in $namep where starts-with($p,"'") return $i
                         return concat($namep[$last - 1],", ",string-join(subsequence($namep,1, $last - 2 )," ")," - ",string-join(subsequence($namep,$last)," ")) 
                    else concat($namep[last()],", ",string-join(subsequence($namep,1, count($namep) - 1)," ")) 
      let $trees := tp:get-tree-by-latin($species/latin)
      order by $species/latin
      return <tr>
               <td><em><a href="?mode=species&amp;latin={$species/latin}">{$species/latin/string()}</a></em>             
               </td>
               <td><a href="../treehtml.xq?mode=select&amp;latin={$species/latin}">{count($trees)}</a></td>
               <td>{$sname}</td>
               <td><b>{$species/common/string()}</b>&#160;
                      {string-join($species/altname,", ")}
               </td>
             </tr>     
     }
     </table>
   </div>
};

declare function tp:species-page($latin) {
let $species := tp:get-species-by-latin($latin)
let $terms := doc(concat($tp:base,"/ref/terms.xml"))
let $parse := tp:parse-latin($latin)
let $genus := $terms//genus[name=$parse/genus]
let $specie := ($genus/species[name=$parse/species],$terms//species[name=$parse/species])[1]
let $cultivar := $terms//cultivar[name=$parse/cultivar]
let $cross := ($terms//cross[name=$parse/cross],$terms//species[name=$parse/cross])[1]
let $variety := $terms//variety[name=$parse/variety]
let $form := $terms//form[name=$parse/form]

let $trees := tp:get-tree-by-latin($latin)
let $tree-count := count($trees)
return
<div>
   <table>
     <tr><th width="12%">Latin name</th><td>{string(($species/latin,$latin)[1])}</td></tr>
     <tr><th>Genus</th><td><b>{$parse/genus}</b>&#160; {if ($genus/pronunciation != "") then concat("[",$genus/pronunciation/string(),"]")else ()} 
       &#160;   {$genus/meaning/string()}</td></tr>
     {if ($parse/cross)
      then <tr><th>Cross</th><td><b>{$parse/cross}</b>&#160;  {if ($cross/pronunciation != "") then concat("[",$cross/pronunciation/string(),"]")else ()} 
       &#160; {$cross/meaning/string()}</td></tr>
      else ()
    }
     {if ($parse/species)
      then <tr><th>Species</th><td><b>{$parse/species}</b>&#160;  {if ($specie/pronunciation != "") then concat("[",$specie/pronunciation/string(),"]")else ()} 
       &#160; {$specie/meaning/string()}</td></tr>
      else ()
    }
    {if ($parse/cultivar)
     then <tr><th>Cultivar</th>
             <td><b>{$parse/cultivar}</b>&#160;  {if ($cultivar/pronunciation != "") then concat("[",$cultivar/pronunciation/string(),"]")else ()}
             &#160; {$cultivar/meaning/string()}</td></tr>
     else ()
     }
    {if ($parse/variety)
     then <tr><th>Variety</th>
             <td><b>{$parse/variety}</b>&#160;  {if ($variety/pronunciation != "") then concat("[",$variety/pronunciation/string(),"]")else ()}
             &#160; {$variety/meaning/string()}</td></tr>
     else ()
     }
    {if ($parse/form)
     then <tr><th>Form</th>
             <td><b>{$parse/form}</b>&#160;  {if ($form/pronunciation != "") then concat("[",$form/pronunciation/string(),"]")else ()}
             &#160; {$form/meaning/string()}</td></tr>
     else ()
     }
     {if ($species/parent)
      then
       <tr><th>Parents</th><td>
             {for $parent in $species/parent
              return (<a href="?mode=species&amp;latin={$parent}">{$parent/string()}</a>,<br/>)
             }
       </td></tr>
       else ()
     }
     <tr><th>Common name</th><td>{$species/common/string()}</td></tr>
     {if ($species/altname)
     then 
     <tr><th>Alternative names</th><td>{for $name in $species/altname
                                        return ($name/string(),<br/>)}</td></tr> 
     else ()
     }
     <tr><th>Description</th><td>{$species/description/node()}</td></tr>
  
    <tr><th>Links</th><td>
          <span><a class="external" target="_blank" href="https://en.wikipedia.org/wiki/{concat($parse/genus,"_",$parse/species)}">Wikipedia</a></span>
          <span><a target="_blank" class="external" href="https://www.google.co.uk/search?q='{$species/latin}'">Google search</a></span>
          <span><a target="_blank" class="external" href="https://www.google.co.uk/search?q='{$species/latin}'&amp;tbm=isch&amp;gws_rd=ssl">Google Images</a></span><br/>
          <span><a target="_blank" class="external" href="https://species.wikimedia.org/wiki/{concat($parse/genus,"_",$parse/species)}">Wiki Species</a></span>
          <span><a target="_blank" class="external" href="http://www.theplantlist.org/tpl1.1/search?q={lower-case($species/latin)}">The Plant List</a></span>
          <span><a target="_blank" class="external" href="http://www.tree-guide.com/{replace(lower-case($species/common),' ','-')}">Tree guide</a></span>  
          <span><a target="_blank" class="external" href="http://www.pfaf.org/user/Plant.aspx?LatinName={concat($parse/genus,"+",$parse/species)}">Plants for a Future</a></span>
        
         </td></tr>
       <tr><th> </th><td>
           <span><a href="?mode=select&amp;latin={$latin}"> {$tree-count} Tree{if ($tree-count != 1) then "s" else ()}</a></span>
           <span><a href="editspecies.xq?mode=edit&amp;latin={$latin}" title="requires authentication">Edit</a></span>
  
       </td></tr>
   </table>  
 </div>
};

declare function tp:tree-to-html($tree) {
   let $photos := tp:get-tree-photos($tree/id)
   return
    <div id="map_text">
     {tp:tree-to-table($tree)}
     {for $photo in $photos
      return
         <div style="padding-left:50px; padding-top:10px;"> 
           <a href="photos/{$photo/photoid}"> <img src="photos/{$photo/photoid}" width="400"></img> </a>
            <br/>
            <h3>{$photo/caption/string()}</h3>
         </div>
     }    
    </div>
};

(: searching :)
declare function tp:get-filter() {
let $id := request:get-parameter("id","")
let $common := request:get-parameter("common","")
let $latin := request:get-parameter("latin","")
let $state := request:get-parameter("state","")
let $text := request:get-parameter("text","")
let $tags :=request:get-parameter("tag","")
let $latitude := request:get-parameter("latitude","")
let $longitude := request:get-parameter("longitude","")
let $range := request:get-parameter("range","")
let $tree := if ($id) then tp:get-tree-by-id($id) else ()
let $filter := 
     element filter {
         if ($id !="") then element id {$id} else (),
         if ($common != "") then element common {$common} else  (),
         if ($latin != "") then element latin {$latin} else  (),
         if ($state != "") then element state {$state} else  (),
         if ($latitude) then element latitude {$latitude} else  if($tree) then $tree/latitude else  (),
         if ($longitude != "") then element longitude {$longitude} else  if($tree) then $tree/longitude else  (),
         if ($range != "") then element range {$range} else  (),
         if ($text != "") then element text {$text} else (),
         if ($tags != "") then 
             for $tag in $tags
             let $contains := $tp:taglist/tag[name=$tag]/contains/tag 
             return 
                if ($contains) then for $stag in $contains return element tag {$stag/name/string()} else element tag {$tag}
         else ()
     }
return $filter
};

(: 
declare function tp:get-filter() {
   ui:get-entity(tp:get-entity("tree_filter"))
};
:)

declare function tp:apply-filter($filter) {
    if ($filter/id) 
    then tp:get-tree-by-id($filter/id)
    else 
    let $trees := if ($filter/tag) 
                  then tp:get-tree-by-tag($filter/tag) 
                  else tp:get-trees()
                  
    let $trees := if ($filter/state) then $trees[matches(state,$filter/state,"i")] else $trees
    let $trees := if ($filter/latin) then $trees[latin = $filter/latin] else $trees
    let $trees := if ($filter/common) then ($trees[matches(name,$filter/common,"i")], $trees[matches(altname,$filter/common,"i")] ) else $trees
    let $trees := if ($filter/text) then $trees[matches(concat(latin,name,text),$filter/text,"i")] else $trees
    let $trees := if ($filter/range) then tp:trees-in-range($trees, number($filter/latitude),number($filter/longitude),number($filter/range)) else $trees
    return $trees
};

declare function tp:filter-form($filter) {
<form action ="?" method="get">
<div> <input type="submit" value="Select Trees"/>  </div>
<table>
   <input type="hidden" name="mode" value="select"/>
   <tr><th>Tree id</th><td>{$filter/id/string()} &#160;<input type="text" name="id" /></td></tr>
   <tr><th>Tags</th><td>
   <select multiple="multiple" name="tag"  size="{count($tp:taglist/tag)+1}">
   <option value="">{if (empty($filter/tag)) then attribute selected {"selected"} else () }all</option>
   {for $tag in $tp:taglist/tag
    order by $tag
    return
       <option>{if ($tag/name = $filter/tag) then attribute selected {"selected"} else () }{$tag/name/string()}</option>
    }</select></td></tr>
    <tr><th>Latin name</th><td><input type="text" name ="latin" value="{$filter/latin}" size="30"/> </td></tr>
    <tr><th>Common name</th><td><input type="text" name ="common" value="{$filter/common}" size="30"/> </td></tr>
    <tr><th>State</th><td>
           <select name="state" size="3">
             <option value="" selected="selected">all</option>
             <option value="Stump">Stump</option>
             <option value="Group">Group</option>
           </select></td></tr>
  <tr><th>Text contains</th><td> <input type="text" name="text" value="{$filter/text}"/> </td></tr>
    <tr><th>Within Range</th><td>
           Within  <input type="text" size="6" name="range" value="{$filter/range}"/> metres of 
           latitude <input type="text" size="10" name="latitude" value="{$filter/latitude}"/> 
           longitude <input type="text" size="10" name="longitude" value="{$filter/longitude}" /> </td></tr>
    <tr><th>Format</th><td>
           <select name="format" size="4">
             <option value="html" selected="selected">HTML</option>
             <option value="xml">XML</option>
             <option value="csv">CSV tab delimited</option>
             <option value="kml">KML</option>
           </select></td></tr>
  
   </table>
</form>
};

declare function tp:filter-to-params($filter) {
    ui:entity-to-string(tp:get-entity("tree_filter"),$filter,"&amp;")
};

declare function tp:show-filter($filter) {
    ui:entity-to-string(tp:get-entity("tree_filter"),$filter,",")
};

(: output in various formats :)
declare function tp:trees-to-kml($trees) {
 <kml>
   <Document>
   <Style id="tree">
      <IconStyle>
        <Icon><href>http://maps.google.com/mapfiles/kml/pal2/icon12.png</href></Icon>
      </IconStyle>
   </Style>
   <Style id="stump">
       <IconStyle>
        <Icon><href>http://maps.google.com/mapfiles/kml/pal4/icon25.png</href></Icon>
      </IconStyle>
   </Style>
   <Style id="group">
       <IconStyle>
        <Icon><href>http://maps.google.com/mapfiles/kml/pal2/icon4.png</href></Icon>
      </IconStyle>
   </Style>

      <name>Bristol Trees</name>
      {for $tree in $trees
       let $namep := tokenize($tree/name,"\s*,\s*")
       let $common := if (count($namep) > 1) then concat($namep[2]," ",$namep[1]) else $tree/name/string()
       let $description := 
           <div>{$tree/id/string()} : 
           {if ($tree/latin) then <a href="https://en.wikipedia.org/wiki/{$tree/latin}">{$tree/latin/string()}</a> else ()}
           <br/>
           {$tree/text/string()}</div>
       where exists($tree/latitude)
       return
      <Placemark>
           <name>{$tree/id/string()} : {$common}</name>
           <styleUrl>{if (matches($tree/state,"stump","i")) 
                      then "#stump" 
                      else if (matches($tree/state,"group","i")) then "#group"
                      else "#tree"}
           </styleUrl>
           <description>{util:serialize($description,"method=xml")}</description>
           <Point>
              <coordinates>{$tree/longitude/string()},{$tree/latitude/string()},0</coordinates>
           </Point>
      </Placemark>
      }
   </Document>
 </kml>
 };

declare function tp:trees-to-csv ($trees) {
   let $entity := tp:get-entity("tree")
   return ui:entity-to-csv($trees,$entity,"&#9;") 
};

(: photo functions :)

declare function tp:get-jpg-gps($image)  {
let $metadata := contentextraction:get-metadata($image)
let $long := $metadata//h:meta[@name="GPS Longitude"]/@content/string()
let $lat := $metadata//h:meta[@name="GPS Latitude"]/@content/string()
let $alt := $metadata//h:meta[@name="GPS Altitude"]/@content/string()
let $compass := $metadata//h:meta[@name="GPS Img Direction"]/@content/string()
let $datetime := $metadata//h:meta[@name="Creation-Date"]/@content/string()
return
  element data {
      element date {substring-before ($datetime,"T")},
      element time {substring-after($datetime,"T")},
      element latitude {geo:dms-to-decimal($lat)},
      element longitude {geo:dms-to-decimal($long)},
      element alt {substring-before($alt," ")},
      element compass {substring-before($compass," ")}
 }
};

declare function tp:show-meta($item) {
 <ul>
        {for $field in $item/*
         return
          <li> {name($field)} = {$field/string()} </li>
        }
 </ul>
};

declare function tp:load-photo(){
<div>
   <h3>Upload a photo</h3>
   <div>
  
     <form enctype="multipart/form-data" method="post" action="?" >
      <input type="hidden" name="action" value="store"/> 
      <input type="file" name="file" /><br/>
      <hr/>
      Tags   <input type="text" name="tags" size="30"/><br/>
      Tree Id <input type="text" name="treeid" size="20"/><br/>
      Taken by  <input type="text" name="photographer" size="20"/><br/>
      Caption  <input type="text" name="caption" size="60"/><br/>
      <hr/>
      <input type="submit" value="Upload"/>
     </form>
   </div>
   <div>Photos should include exif location data and be sized suitable for a web page ie. about 1M in size</div>
</div>
};

declare function tp:store-photo() {
 let $tags := normalize-space(request:get-parameter("tags",()))
 let $treeid := normalize-space(request:get-parameter("treeid",()))
 let $photographer := normalize-space(request:get-parameter("photographer",()))
 let $caption := normalize-space(request:get-parameter("caption",()))
 let $file := request:get-uploaded-file-data('file')
 return
    if (exists($file))
    then 
    let $login := xmldb:login($tp:base,"admin","perdika")
    let $id := concat(util:uuid(),".jpg")
    let $store := xmldb:store($tp:photostore, $id, $file)
    let $gps := tp:get-jpg-gps($file)
    let $photo :=
          <photo>
            <photoid>{$id}</photoid>
            <treeid>{$treeid}</treeid>
            <caption>{$caption}</caption>
            <photographer>{$photographer}</photographer>
            {for $tag in tokenize($tags,",") return 
                <tag>{lower-case(normalize-space($tag))}</tag>
            }
            <dateStored>{current-dateTime()}</dateStored>
            {$gps/*}
         </photo>
   let $update :=  update insert $photo into doc(concat($tp:base,"/ref/treephotos.xml"))/photos
   return $photo
   else ()
};

declare function tp:log($action) {
   log:log-request("trees",$action) 
};
