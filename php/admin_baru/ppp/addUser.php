<?php
error_reporting(0);
include 'kon.php'; // File koneksi database
$pass_acak = mt_rand(1000, 9999);

  
$carikode = mysqli_query($koneksi,"SELECT id_pelanggan FROM tb_pelanggan order by id_pelanggan desc");
$datakode = mysqli_fetch_array($carikode);
$kode = $datakode['id_pelanggan'];
$urut = substr($kode, 1, 3);
$tambah = (int) $urut + 1;
if (strlen($tambah) == 1){
    $format = "C"."00".$tambah;
         }else if (strlen($tambah) == 2){
         $format = "C"."0".$tambah;
                }else (strlen($tambah) == 3){
                $format = "C".$tambah
                    };
                    
 

// Ambil data dari permintaan POST
$nama = $_POST['nama'];
$alamat = $_POST['alamat'];
$no_hp = $_POST['no_hp'];
$email = $nama . '@gmail.com'; // Email default

$level = 'PLG'; // Level default
$id_paket = $_POST['id_paket'];
$id_teknisi = $_POST['id_teknisi'];

// Query untuk menambahkan data pengguna baru
$sql = "INSERT INTO tb_pelanggan (id_pelanggan,nama, alamat, no_hp, email, password, level, id_paket, id_teknisi) 
        VALUES ('$format','$nama', '$alamat', '$no_hp', '$email', '$pass_acak', '$level', '$id_paket', '$id_teknisi')";

if (mysqli_query($koneksi, $sql)) {
    echo json_encode(array('message' => 'User added successfully'));
} else {
    echo json_encode(array('error' => 'Failed to add user'));
}

mysqli_close($koneksi);
?>
