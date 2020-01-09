<?php

require_once('./init.php');
$ini = get_ini();

$idFoto = -1;
if(isset($_REQUEST['idFoto'])) {
	$idFoto = (int)preg_replace("/[^0-9 ]/", '', $_REQUEST['idFoto']);
}


echo get_link($idFoto);

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
function get_link($idFoto)
{
	global $ini;
	$db = db_connect();
	
	$query = 'SELECT CONCAT(FILE_BASE,FILE_DIR,FILE_NAME) AS LINK, FILE_NAME AS NAME FROM fotos.fotos WHERE ID_FOTO='.$idFoto;
	$result = mysqli_query($db, $query);
	$row    = mysqli_fetch_assoc($result);
	$link     = '<a href="'.$ini['DOWNLOAD_PREFIX'].$row['LINK'].'">'.$row['NAME'].'</a>';
	return($link);
}