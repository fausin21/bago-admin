<?php
include "kon.php";
 
$query = mysqli_query($koneksi, "SELECT id, username,password,no_hp,tanggal FROM usuarios where cabang='bayar_sentul'");
$data = array();
while ($row = mysqli_fetch_assoc($query)) {
    $id = $row['id'];
    $username = $row['username'];
    $password = $row['password'];
    $no_hp = $row['no_hp'];
    $tanggal = $row['tanggal']; // tambahkan field tanggal
    $data[] = array(
        'id' => $id,
        'username' => $username,
        'password' => $password,
        'tanggal' => $tanggal, // tambahkan field tanggal
        'no_hp' => $no_hp
    );
}
echo json_encode($data);
?>

