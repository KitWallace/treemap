let $trees := doc("/db/apps/trees/data/trees.xml")/trees 

return 
  <kml>
   <Document>
   <Style id="tree">
      <IconStyle>
        <Icon><href>http://maps.google.com/mapfiles/kml/pal2/icon12.png</href></Icon>
      </IconStyle>
   </Style>
      <name>Bristol Trees</name>
      {for $tree in $trees/tree
       let $namep := tokenize($tree/name,"\s*,\s*")
       let $common := if (count($namep) > 1) then concat($namep[2]," ",$namep[1]) else $tree/name/string()
       let $description := 
           <div>{$tree/id/string()} : <a href="https://en.wikipedia.org/wiki/{$tree/latin}">{$tree/latin/string()}</a>  <br/>
           {$tree/text/string()}</div>
       where exists($tree/grid)
       return
      <Placemark>
           <name>{$common}</name>
           <styleUrl>#tree</styleUrl>
           <description>{util:serialize($description,"method=xml")}</description>
           <Point>
              <coordinates>{$tree/longitude/string()},{$tree/latitude/string()},0</coordinates>
           </Point>
      </Placemark>
      }
   </Document>
 </kml>
