var debug = false;
var watch_id =0;
var tree_id;
var watching = false;
var ntrees=0;

function fetch_trees(position) {
    if(debug) alert("fetch_trees");
    var lat = position.coords.latitude;
    var long = position.coords.longitude;
    var tag = $('#tag').val();
    if (typeof tag === "undefined") tag=''; else tag = encodeURIComponent(tag);
    var latin = $('#latin').val();
    if (typeof latin === "undefined") latin=''; else latin = encodeURIComponent(latin);
    
    var url = "http://kitwallace.co.uk/trees/mobile.xq?tag="+tag+"&latin="+latin+"&latitude="+lat+"&longitude="+long;
    if(debug) alert(url);
    if (tree_id !="") url += "&id="+tree_id;
    if (ntrees>0) url +="&n="+ntrees;
    $('#info').load(url);
    //restore watching status 
    if (watching)  {
      $('#watching').text('ON');  
    } else {
      $('#watching').text('OFF');
    } 
}

function errorFunction(position) {
    alert('Error!');
}

function get_tree(n) {
    if(debug) alert("get tree");
    ntrees = n;
    tree_id="";
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(fetch_trees, errorFunction,{enableHighAccuracy:true});
    } else {
       alert("no navigator");
    }
};

function get_tree_with_id(id) {
     tree_id = id;
     ntrees=0;
     if(debug) alert("get tree with id " + tree_id); 
     if (navigator.geolocation) {
        if (debug) alert("in navigator");
        navigator.geolocation.getCurrentPosition(fetch_trees, errorFunction,{enableHighAccuracy:true});
    } else {
       alert("no navigator");
    }   
}

function watch_change() {
    if(debug) alert("Watching"+watching);
    if (watching) {
        navigator.geolocation.clearWatch(watch_id);
        watching = false;
        $('#watching').text('OFF');
 //       alert("watching now off");
    }
    else {
        if (navigator.geolocation) {
           watch_id =  navigator.geolocation.watchPosition(fetch_trees, errorFunction, {enableHighAccuracy:true,maximumage:30000});
           watching = true;
           $('#watching').text('ON');
 //          alert("watching now on");
        } else {
           alert("no navigator");
        }
   }
};

$(document).ready(function() { 
    get_tree();
  });
