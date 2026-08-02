<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

$servername = "localhost"; // Ganti dengan alamat server database Anda
$username = "fausin"; // Ganti dengan username database Anda
$password = "anggita"; // Ganti dengan password database Anda
$dbname = "app"; // Ganti dengan nama database Anda

// Buat koneksi
$conn = new mysqli($servername, $username, $password, $dbname);

// Periksa koneksi
if ($conn->connect_error) {
    die(json_encode(array("status" => "error", "message" => "Connection failed: " . $conn->connect_error)));
}

// Baca data mentah dari body request
$data = json_decode(file_get_contents("php://input"), true);

$id = $data['id'];
$korwil = $data['korwil'];
$no_hp = $data['no_hp'];
$bulanan = floatval(str_replace("Rp", "", $data['bulanan']));
$voucher = floatval(str_replace("Rp", "", $data['voucher']));
$pppoe = floatval(str_replace("Rp", "", $data['pppoe']));
$total = floatval(str_replace("Rp", "", $data['total']));
$ket = $data['ket'];

// Query untuk menyimpan data
$sql = "INSERT INTO setoran_korwil (id, korwil, no_hp, bulanan, voucher, pppoe, total, ket) 
        VALUES ('$id', '$korwil', '$no_hp', '$bulanan', '$voucher', '$pppoe', '$total', '$ket')";

if ($conn->query($sql) === TRUE) {
    echo json_encode(array("status" => "success", "message" => "Data successfully inserted"));
} else {
    echo json_encode(array("status" => "error", "message" => "Error: " . $sql . "<br>" . $conn->error));
}

$conn->close();
?>
