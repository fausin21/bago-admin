<?php

include "kon.php";
$query = mysqli_query($koneksi, "SELECT * FROM teknisi where nama='$_GET[nama]'");
$hasil = mysqli_fetch_array($query);
$id_teknisi = $hasil['id'];
echo $id_teknisi;
?>
