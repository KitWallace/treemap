declare option exist:serialize "method=xhtml media-type=text-html";
declare function local:tree-to-table($tree) {
   let $gs := string-join(subsequence(tokenize($tree/latin," "),1,if (contains($tree/latin," x ")) then 3 else 2)," ")
   let $now := 2016
   let $namep := tokenize($tree/name,"\s*,\s*")
   let $common := if (count($namep) > 1) then concat($namep[2]," ",$namep[1]) else $tree/name/string()
   return
<div>
       <br/>
       <h2>{$common}</h2>
       <br/>
       <table>
       <tr><th width="20%">ID</th><td>{$tree/id/string()}</td></tr>
       <tr><th>Common name</th><td><a href="?common={$tree/name}">{$tree/name/string()}</a></td></tr>
       {if (exists($tree/altname)) then 
          <tr><th>Other names</th><td>{$tree/altname/string()}</td></tr> else () 
       }
       <tr><th>Latin name</th><td>{$tree/latin}&#160;<a target="_blank" class="external" href="https://en.wikipedia.org/wiki/{$gs}">Wikipedia</a> </td></tr>
 <!--      <tr><th>Lat/Long</th><td><a href="http://www.google.com/maps/place/{$tree/latitude},{$tree/longitude}/@{$tree/latitude},{$tree/longitude},18z/data=!3m1!1e3">{$tree/latitude/string()},{$tree/longitude/string()}</a></td></tr> -->
       <tr><th>Collection</th><td><a href="?tag={$tree/tag}">{$tree/tag/string()}</a></td></tr>
       {if($tree/latitude) then 
          (<tr><th>OS grid</th><td>{$tree/grid/string()}</td></tr>,
           <tr><th>Lat/Long</th><td>{$tree/latitude/string()},{$tree/longitude/string()}</td></tr>)
       else ()
       }
      {if ($tree/girth) then <tr><th>Girth</th><td>{$tree/girth/string()}&#160;cm</td></tr> else ()}
      {if ($tree/age) then  <tr><th>Age</th><td>{$tree/age/string()}&#160;years  [about {$now - number($tree/age)}]</td></tr>  else ()}  
       <tr><th>Description</th><td>{$tree/text/string()}</td></tr>
       </table>
 
 </div>
 };
 
 
declare function local:about() {
  <div style="font-size:smaller">
     <h2>About the site</h2>
     <div>This site has been constructed to support the work of the <a class="external" target="_blank" href="https://bristoltreeforum.org/">Bristol Tree Forum</a> </div>
    
     <div>The data on trees mapped here has been collected by Richard Bland. </div>
     <div>The original semi-structured text has been converted to a <a href="data/trees.xml"> structured xml document</a>.
     </div><div>The location of all trees can be <a href="treekml.xq">extracted as kml</a>. Save the page as e.g. trees.kml and then view in Google Earth </div>
     <div>This site is under development by <a class="external" target="_blank" href="http://kitwallace.co.uk">Chris Wallace</a> and Mark Ashdown.  Current issues are on <a class="external" target="_blank" href="https://github.com/KitWallace/treemap/issues">Github</a>.
     </div>  
   </div>
};


let $taglist := ("Veteran","Champion","Remarkable")
let $key := "yourprivatekey"
let $trees := doc("/db/apps/trees/data/trees.xml")/trees 
let $id := request:get-parameter("id",())
let $common := request:get-parameter("common",())
let $latin := request:get-parameter("latin",())
let $search := request:get-parameter("contains",())
let $tag :=request:get-parameter("tag",())
let $list := request:get-parameter("list",())
let $home := concat($common,$latin,$id,$search,$tag) = ""  and not( exists($list))
let $strees := 
     if ($id) then $trees/tree[id=$id]
     else if ($common) then $trees/tree[name=$common]
     else if ($latin) then $trees/tree[latin=$latin]
     else if ($search) then $trees/tree[matches(text,$search,"i")]
     else if ($tag) then if ($tag="All") then $trees/tree else $trees/tree[tag=$tag] 
     else if ($list) then ()
     else $trees
return 
<html>
  <head>
  <title>Trees of Bristol</title>
    <link rel="stylesheet" type="text/css"
            href="https://fonts.googleapis.com/css?family=Merriweather Sans"/>
    <link rel="stylesheet" type="text/css"
            href="https://fonts.googleapis.com/css?family=Gentium Book Basic"/>
    <script type="text/javascript" src="../js/sorttable.js"></script> 
    <script src="https://maps.googleapis.com/maps/api/js?key={$key}"></script> 
    <script type="text/javascript">

var map;
var bounds = new google.maps.LatLngBounds();
var position;
var infowindow = null;
var marker;
var trees = [
   { string-join(
       for $tree in $strees
       let $title :=  concat($tree/id," : ",replace($tree/name,"'","\\'")) 
       let $text := replace($tree/text,"'","\\'")
       let $description :=  util:serialize(
         <div><h1><a href="?id={$tree/id}">{$tree/name/string()}</a></h1><div>{$text}</div></div>,
          "method=xhtml media-type=text/html indent=no") 


       where exists($tree/latitude)
       return
          concat("['",$title,"',",
                  $tree/latitude/string(),",",$tree/longitude/string(),
                  ",'",$description,"']")
       ,",&#10;")
     }
     ];

function htmlDecode(input){{
  var e = document.createElement('div');
  e.innerHTML = input;
  return e.childNodes[0].nodeValue;
}}

function initialize() {{
  div = document.getElementById("map_canvas");
  map = new google.maps.Map(div,{{
      zoom:  {if (count($strees) = 1 ) then 16 else 10},
      center: new google.maps.LatLng(51.467425,-2.575213),
      mapTypeId: 'satellite'
      }}); 
   addMarkers();
   infowindow =  new google.maps.InfoWindow( {{
          content: "loading ... "
       }});         
   if (trees.length == 1) {{
        google.maps.event.addListenerOnce(map, 'zoom_changed', function() {{
             map.setZoom(15); 
        }});
        map.fitBounds(bounds);
       }}
   else if (trees.length == 0) {{
      map.position(new google.maps.LatLng(51.467425,-2.575213));
      map.setZoom(12);
      }}
   else map.fitBounds(bounds);

}}   

function addMarkers() {{
   for (i in trees){{
       var m = trees[i];
       var text = htmlDecode(m[3]);        
       position = new google.maps.LatLng(m[1],m[2]);
       bounds.extend(position);
       marker = new google.maps.Marker({{
          position: position,
          title: m[0],
          map: map,
          icon: "http://maps.google.com/mapfiles/kml/pal2/icon12.png",
          html: text
       }});


       google.maps.event.addListener(marker,'click', function() {{
            infowindow.setContent(this.html);
            infowindow.open(map, this);
        }});
   }}
 }}
 
</script> 
    <link rel="stylesheet" type="text/css" href="assets/base.css" media="screen" ></link>
    </head>
    <body onload="initialize()">

   <h1>Trees of Bristol   
       <span style="font-size: smaller">
           &#160; <a href="?">Home</a>
           &#160; <a href="?list=common">Common Names</a>  
           &#160; <a href="?list=latin">Latin Names</a>         
           &#160; <a href="?list=about">About</a>         
       </span>    
  </h1>
  <hr/>
  {if ($home) then 
 
    <div>
    <h2>Collections</h2>
    <div> 
        <ul>
            <li><a href="?tag=All">All</a></li>
            {for $tag in $taglist
             return
               <li><a href="?tag={$tag}">{$tag}</a></li>
            }
       </ul>
     </div>
     <h2>Search</h2>
     <div>
        <form action="?" method="get">
           Search the descriptions for  <input type="text" size="30" name="contains"/>
           <input type="submit"  value="Search"></input>
        </form>
     </div>    
   </div>
   else
  if ($list = "common")
  then
   <div>
     <h2>Common names</h2>
     <ul>
     {for $name in distinct-values($trees/tree/name)
      order by $name
      return <li><a href="?common={$name}">{$name}</a></li>
     }
     </ul>
   </div>
  else 
  if ($list = "latin")
  then
   <div>
     <h2>Latin names</h2>
     <ul>
     {for $name in distinct-values($trees/tree/latin)
      order by $name
      return <li><a href="?latin={$name}">{$name}</a></li>
     }
     </ul>
   </div>
  else 
  if ($list = "about") 
  then local:about()
  else
  if (count($strees) > 1)
  then 
     <div id="map_text">
     <h2>{($tag,$common,$latin,$id,concat("Matching '",$search,"'"))[1]}</h2>
     <table class="sortable"> 
      <tr><th>Id</th><th>Name</th><th>Girth cm</th><th>Description</th></tr>
      {for $tree in $strees
       return
        <tr>
         <td><a href="?id={$tree/id}">{$tree/id/string()}</a></td><td>{$tree/name/string()}</td><td>{$tree/girth/string()}</td><td> {substring($tree/text,1,40)} ...</td>
        </tr>
      }  
      </table>
     </div>
  else if (count($strees)=1)
  then 
    let $tree := $strees[1]
    return
     <div id="map_text">
     {local:tree-to-table($tree)}
    </div>
   else 
    <div>empty</div>
  }
     {if ($strees)
     then <div id="map_canvas" >
       </div>
      else()
      }
  </body>

</html>

  
