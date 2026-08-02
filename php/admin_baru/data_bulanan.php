<?php
include 'kon.php'; // Adjust to your database connection file

header('Content-Type: application/json');

$response = [];

if (isset($_POST['korwil'])) {
    $korwil = $_POST['korwil'];

    // Query to get the count of data with sts = 3 from the usuarios table
    $sql = "SELECT COUNT(*) AS jumlah FROM usuarios WHERE cabang = '$korwil' AND sts = 3";
    $query = mysqli_query($koneksi, $sql);
    $result = mysqli_fetch_assoc($query);

    // Prepare response
    $response['monthly'] = $result['jumlah'];
} else {
    $response['error'] = 'Korwil not specified';
}

echo json_encode($response);
?>
