<?php

	require_once 'connect.php';
    $uConnect = new mysqli(mysql_host, mysql_user, mysql_pw, mysql_db);
	
	$EscIP = $uConnect->real_escape_string($_POST['IP']);
	$EscName = $uConnect->real_escape_string($_POST['Name']);
	
	$uConnect->query("INSERT INTO `ad_bans` (`Admin Name`, `Banned`, `IP`, `Reason`, `Date`) VALUES ('System', '" . $EscName . "', '" . $EscIP . "', 'Aimbot', UNIX_TIMESTAMP())");
	
	mysqli_close($uConnect);

?>