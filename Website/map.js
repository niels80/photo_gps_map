'use strict';

var map = L.map('map');
var markers = L.markerClusterGroup();

updateMap(0,1);

// Button for years
Array.from(document.getElementsByClassName('btnJahr')).forEach((element) => {
  element.addEventListener('click', (event) => {
    updateMap(event.target.value);
  });
});

document.getElementById('resetZoom').addEventListener('click', (event) => {
    map.setView([0,0],2);
 });


function updateMap(year=0,resetZoom=0) {
	
	
	
	// Add AJAX request for data
	var fotos = $.ajax({
	  url:"./get_coords.php?jahr="+year,
	  dataType: "json",
	  success: console.log(year+" Coordinates successfully loaded."),
	  error: function (xhr) {
		alert(xhr.statusText)
	  }
	})

	$.when(fotos).done(function() {

		
		markers.clearLayers();
		
		L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
		  attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
		}).addTo(map);
		
		var geoJsonLayer = L.geoJSON(fotos.responseJSON, { onEachFeature: onEachMarker } );
		markers.addLayer(geoJsonLayer);
		map.addLayer(markers);
		
		if (resetZoom>0) {
			map.setView([0,0],2);
		}
	})
}


function onEachMarker(feature, layer) {

	layer.on('click', function (e) {
		//destroy any old popups that might be attached
		if (layer._popup != undefined) {
			layer.unbindPopup();
		}
		
		var popup_html = '<img src="./get_foto.php?idSize=1&idFoto='+feature.properties.id+'" /><p>'+feature.properties.id+'</p>';
		layer.bindPopup(popup_html, {
			maxWidth: "auto"
		});
		layer.openPopup();
		$("#gallery").load("./get_gallery.php?idFoto="+feature.properties.id);
		
	});
		
}







