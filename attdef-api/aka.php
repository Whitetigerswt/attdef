<?php

	require_once 'connect.php';
    $uConnect = new mysqli(mysql_host, mysql_user, mysql_pw, mysql_db);
	
	$EscIP = $uConnect->real_escape_string($_POST['IP']);
	$EscName = $uConnect->real_escape_string($_POST['Name']);
		
	if($result = $uConnect->query("SELECT `Names` FROM `AKAs` WHERE `IP` = '" . $EscIP . "'")) {
		if($result->num_rows > 0) {
			$row = $result->fetch_assoc();
			
			$add = true;
			
			if(stristr($row['Names'], ",") != FALSE) {
				$names = $row['Names'];
				if(strlen($names) > 3) {
					if(!strcmp($names, $EscName)) {
						$add = false;
					}
				}
			} else {
				$names = explode(",", $row['Names']);
				for($i = 0; $i < count($names); $i++) {
					if(strlen($names[$i]) > 3) {
						if(!strcmp($names[$i], $EscName)) {
							$add = false;
							break;
						}
					}
				}
			}
			if($add == true) {
				$uConnect->query("UPDATE `AKAs` SET `Names` = '" . $row['Names'] . "," . $EscName . "' WHERE `IP` = '" . $EscIP . "'");
			}
		} else {
			$uConnect->query("INSERT INTO `AKAs` (`IP`, `Names`) VALUES ('" . $EscIP . "', '" . $EscName . "')");
		}
	}
	
	mysqli_close($uConnect);
	
?>