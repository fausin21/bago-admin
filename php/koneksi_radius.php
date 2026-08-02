<?php
// bikin koneksi ke database dgn nama host, user, password, dan nama database
$konek = mysqli_connect("192.168.99.157","fausin","Anggita123!","radius");
// cek koneksi
if (mysqli_connect_errno()) {
	echo "Koneksi database gagal : " . mysqli_connect_error();
}else{
    
}
?>
