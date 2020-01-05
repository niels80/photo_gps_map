<?php
header('Content-type: application/json');

require_once('./init.php');
$ini = get_ini();

$idFoto = -1;
if(isset($_REQUEST['idFoto'])) {
	$idFoto = (int)preg_replace("/[^0-9 ]/", '', $_REQUEST['idFoto']);
}

$idSize = 1;
if(isset($_REQUEST['idSize'])) {
	$idSize = (int)preg_replace("/[^0-9 ]/", '', $_REQUEST['idSize']);
}

$folder = $ini['SM_EXPORT_FOLDER'];
if ($idSize > 1) {
	$folder = $ini['MD_EXPORT_FOLDER'];
}

$imagefile = $folder . sprintf("%04d",$idFoto >> 10) . "/" . sprintf("%08d",$idFoto) . ".jpg";

header('Content-type: image/jpg');
readfile($imagefile);


exit;

