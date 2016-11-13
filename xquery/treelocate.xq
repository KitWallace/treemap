import module namespace tp = "http://kitwallace.co.uk/lib/tp" at "lib/tp.xqm";

declare option exist:serialize "method=xhtml media-type=text/html omit-xml-declaration=no indent=yes 
        doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Transitional//EN
        doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd";

let $log := tp:log("treelocate")
return
<html>
    <head>
        <title>Bristol Tree Locator</title>
        <link rel="stylesheet" type="text/css" href="assets/mobile3.css"  ></link>
        <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script> 
        <script src="assets/mobile.js" type="text/javascript" charset="utf-8"></script>    
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <link href="http://bristoltrees.space/assets/BTF.png" rel="icon" sizes="128x128" />
        <link rel="shortcut icon" type="image/png" href="http://kitwallace.co.uk/trees/assets/BTF.png"/>
        <link rel="stylesheet" type="text/css"
            href="https://fonts.googleapis.com/css?family=Merriweather Sans"/>
        <link rel="stylesheet" type="text/css"
            href="https://fonts.googleapis.com/css?family=Gentium Book Basic"/>

    </head>
    <body>
        <div>
            <span style="font-size: 18pt;"><a href="?">Bristol Tree Locator</a></span> 
        </div>
        <hr/>
        
          <div style="padding-botton:20px"><span class="btext" >Collection <select id="tag" name="tag" >
              <option value="">all</option>
             {for $tag in $tp:taglist/tag
              order by $tag
              return
                 <option>{$tag/name/string()}</option>
             }</select></span>
          
         </div>
          <div style="padding-botton:20px"><span class="btext" >Species <select id="latin" name="latin" >
             <option value="">all</option>
            {for $species in tp:get-species()
              order by $species
              return
                 <option>{$species/latin/string()}</option>
             }</select></span>     
          </div>
          <hr/>
          <div>
          <span class="btext">Nearest </span>
             <button  class="button" onclick="get_tree(1)" title="Get nearest Tree">Tree</button> &#160;
             <button  class="button" onclick="get_tree(5)" title="Get nearest Five Trees">5 </button> &#160;
             <button  class="button" onclick="get_tree(10)" title="Get nearest Ten Trees">10</button> &#160;
          <span class="btext">Continuous Update </span>
             <button id="watching" class="button" onclick="watch_change()">OFF</button>
          </div>    
       <hr/>

       <div id="info">        
       </div>
       <hr/>
        <div> by&#160;<a target="_blank" class="external" href="http://bristoltrees.space">Trees of Bristol</a>&#160;for <a class="external" target="_blank" href="https://bristoltreeforum.org/">Bristol Tree Forum</a> 
        </div>
    </body>
</html>
