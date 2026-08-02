<?php
include 'kon.php'; // File koneksi database

// Query untuk mendapatkan daftar paket
$sql = "SELECT id_paket, paket, tarif FROM tb_paket";
$result = mysqli_query($koneksi, $sql);

if ($result) {
    $response = array();
    while ($row = mysqli_fetch_assoc($result)) {
        $response[] = $row;
    }
    echo json_encode($response);
} else {
    echo json_encode(array('error' => 'Failed to fetch packages'));
}

mysqli_close($koneksi);
?>
