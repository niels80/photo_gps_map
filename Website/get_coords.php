<?php
header('Content-type: application/json');

require_once('./init.php');
$ini = get_ini();

$idCluster = -1;
if(isset($_REQUEST['idCluster'])) {
	$idCluster = preg_replace("/[^0-9 ]/", '', $_REQUEST['idCluster']);
}


echo json_encode(get_coords($idCluster));  //, JSON_PRETTY_PRINT


exit;


/* Function to connect to our local MySQL server, using the PDO extension */
function db_connect()
{
	global $ini;
	
	$db =mysqli_connect($ini['DB_HOSTNAME'], $ini['DB_USER'], $ini['DB_PASSWORD'], $ini['DB_DATABASE']);
	if(!$db)
	{
	  trigger_error("Verbindungsfehler: ".mysqli_connect_error());
	}
	return $db;
}

/* Function to retrieve the users */
function get_coords($idCluster)
{
	$db = db_connect();
	
	$features = array();
		
	$query = 'SELECT ID_FOTO,FROM_UNIXTIME(TS_CREATE) AS TIME, GPS_LAT,GPS_LON FROM fotos.fotos WHERE GPS_LAT IS NOT NULL ORDER BY ID_FOTO ASC';
	$result = mysqli_query($db, $query);
	
	while ($row = mysqli_fetch_assoc($result))
	{
		
		$coords = array($row['GPS_LON'],$row['GPS_LAT']);
		
		$geometry = array(
			"type"=>"Point",
			"coordinates"=>$coords);
			
		$properties = array(
			"time"=>$row['TIME'],
			"id"=>$row['ID_FOTO']);
			
		$features[] = array(
			"type"=>"Feature",
			"properties"=>$properties,
			"geometry"=>$geometry);
			
	}
	
	return $features;
}