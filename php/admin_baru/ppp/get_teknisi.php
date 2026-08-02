<?php
include 'kon.php'; // File koneksi database

// Query untuk mendapatkan daftar teknisi
$sql = "SELECT id, nama,nomer,cabang FROM teknisi";
$result = mysqli_query($koneksi, $sql);

if ($result) {
    $response = array();
    while ($row = mysqli_fetch_assoc($result)) {
        $response[] = $row;
    }
    echo json_encode($response);
} else {
    echo json_encode(array('error' => 'Failed to fetch technicians'));
}

mysqli_close($koneksi);
?>
