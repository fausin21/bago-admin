<?php
// Koneksi ke database
$servername = "localhost";
$username = "fausin";
$password = "anggita";
$dbname = "app";

$conn = new mysqli($servername, $username, $password, $dbname);

// Periksa koneksi
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Ambil data POST
$data = json_decode(file_get_contents('php://input'), true);
$id = isset($data['id']) ? $data['id'] : '';

// Periksa apakah ID ada
if (empty($id)) {
    http_response_code(400); // Bad Request
    echo json_encode(array("message" => "ID is required."));
    exit();
}

// Dapatkan tanggal saat ini
$date = date('Y-m-d'); // Menggunakan format tanggal yang umum digunakan dalam database

// Escape variabel ID
$id = $conn->real_escape_string($id);

// Update kolom 'ket' menjadi tanggal saat ini
$sql = "UPDATE setoran_korwil SET ket = '$date' WHERE id = '$id'";

if ($conn->query($sql) === TRUE) {
    echo json_encode(array("message" => "Status updated to 'lunas' with current date."));
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(array("message" => "Failed to update status: " . $conn->error));
}

$conn->close();
?>
