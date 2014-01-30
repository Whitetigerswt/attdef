<?php

	require_once 'connect.php';
    $uConnect = new mysqli(mysql_host, mysql_user, mysql_pw, mysql_db);
	
	$code = $uConnect->real_escape_string($_POST['Code']);
	
	mysqli_close($uConnect);
	
?>