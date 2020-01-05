<?php

require_once('./init.php');
$ini = get_ini();

$idFoto = -1;
if(isset($_REQUEST['idFoto'])) {
	$idFoto = (int)preg_replace("/[^0-9 ]/", '', $_REQUEST['idFoto']);
}

print_gallery($idFoto,3*60*60);

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
function print_gallery($idFoto,$seconds)
{
	$db = db_connect();
	
	$query = 'SELECT TS_CREATE FROM fotos.fotos WHERE ID_FOTO='.$idFoto;
	$result = mysqli_query($db, $query);
	$row    = mysqli_fetch_assoc($result);
	$ts     = (int)$row['TS_CREATE'];
	$tsMin  = (int)$ts-$seconds/2;
	$tsMax  = (int)$ts+$seconds/2;
		
	$query = 'SELECT ID_FOTO,FROM_UNIXTIME(TS_CREATE) AS TIME, FILE_NAME FROM fotos.fotos WHERE TS_CREATE>'.$tsMin.' AND TS_CREATE< '.$tsMax.' ORDER BY TS_CREATE ';
	$result = mysqli_query($db, $query);
	
	$html_preview = '  <div class="row" id="galleryPreview" data-toggle="modal" data-target="#exampleModal">';
	
	$html_modal = '	    <!-- Modal -->
						<!-- 
						This part is straight out of Bootstrap docs. Just a carousel inside a modal.
						-->
						<div class="modal fade" id="exampleModal" tabindex="-1" role="dialog" aria-hidden="true">
						  <div class="modal-dialog" role="document">
							<div class="modal-content">
							  <div class="modal-header">
								<button type="button" class="close" data-dismiss="modal" aria-label="Close">
								  <span aria-hidden="true">&times;</span>
								</button>
							  </div>
							  <div class="modal-body">
								<div id="carouselExample" class="carousel slide" data-ride="carousel">
								   <div class="carousel-inner">
		
	';
	
	$i = 0;
	
	while ($row = mysqli_fetch_assoc($result))
	{
		$i++;
		$active = "";
		if ($i == 1) { $active = " active "; }
		
		$html_preview  .= '
				<div class="col-sm">
					<img src="./get_foto.php?idSize=1&idFoto='.$row['ID_FOTO'].'"  alt="'.$row['FILE_NAME'].'" data-target="#carouselExample" data-slide-to="'.($i-1).'">
				</div> 
				';
		$html_modal .= '
			<div class="carousel-item '.$active.' ">
				<img class="d-block w-100" src="./get_foto.php?idSize=2&idFoto='.$row['ID_FOTO'].'"  alt="'.$row['FILE_NAME'].'"  />
				<div class="carousel-caption d-none d-md-block">
					<p>'.$row['TIME'].' / '.$row['FILE_NAME'].'</p>
				</div>
			</div>
		';
	}
	
	
	$html_preview .= '		</div> ';
	
	$html_modal .= ' 		</div>
							<a class="carousel-control-prev" href="#carouselExample" role="button" data-slide="prev">
								<span class="carousel-control-prev-icon" aria-hidden="true"></span>
								<span class="sr-only">Previous</span>
							 </a>
							<a class="carousel-control-next" href="#carouselExample" role="button" data-slide="next">
								<span class="carousel-control-next-icon" aria-hidden="true"></span>
								<span class="sr-only">Next</span>
							</a>
						</div>
					  </div>
					  <div class="modal-footer">
						<button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
					  </div>
					</div>
				  </div>
				 </div>
					  ';
					  
	echo $html_preview;
	echo $html_modal;
}