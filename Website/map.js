'use strict';


// Add AJAX request for data
var fotos = $.ajax({
  url:"./get_coords.php",
  dataType: "json",
  success: console.log("Coordinates successfully loaded."),
  error: function (xhr) {
	alert(xhr.statusText)
  }
})

$.when(fotos).done(function() {

	var map = L.map('map');
	
	L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
	  attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
	}).addTo(map);
	
	var markers = L.markerClusterGroup();

	var geoJsonLayer = L.geoJSON(fotos.responseJSON, { onEachFeature: onEachMarker } );
	markers.addLayer(geoJsonLayer);
	map.addLayer(markers);
    map.fitBounds(markers.getBounds());
    
})


function onEachMarker(feature, layer) {

	layer.on('click', function (e) {
		//destroy any old popups that might be attached
		if (layer._popup != undefined) {
			layer.unbindPopup();
		}
		
		var popup_html = '<img src="./get_foto.php?idSize=1&idFoto='+feature.properties.id+'" /><p>'+feature.properties.id+'</p>';
		layer.bindPopup(popup_html);
		layer.openPopup();
		$("#gallery").load("./get_gallery.php?idFoto="+feature.properties.id);
		
	});
		
}


