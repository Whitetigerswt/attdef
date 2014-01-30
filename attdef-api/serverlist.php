<?php

	require_once 'connect.php';
    $uConnect = new mysqli(mysql_host, mysql_user, mysql_pw, mysql_db);
	
	$EscIP = $uConnect->real_escape_string($_POST['IP']);
	$EscName = $uConnect->real_escape_string($_POST['HostName']);

	if(!strcmp($EscIP, "noip")) $EscIP = $_SERVER['REMOTE_ADDR'];

	$EscIP = $EscIP . ":" . $uConnect->real_escape_string($_POST['Port']);

	if($result = $uConnect->query("SELECT `IP` FROM `attdef_servers` WHERE `IP` = '" . $EscIP . "'")) {
		if($result->num_rows > 0) { // IP already exists

		} else { // IP doesn't already exist
			$uConnect->query("INSERT INTO `attdef_servers` (`IP`, `HostName`) VALUES ('" . $EscIP . "', '" . $EscName . "')");
		}
		$result->close();
	} else $uConnect->query("INSERT INTO `attdef_servers` (`IP`, `HostName`) VALUES ('" . $EscIP . "', '" . $EscName . "')");
	
	mysqli_close($uConnect);

?>