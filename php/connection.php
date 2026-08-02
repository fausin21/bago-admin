<?php

$hostname = "192.168.99.157";
$username = "fausin";
$password = "Anggita123!";
$database = "radius";

$hostname2 = "192.168.99.100";
$username2 = "fausin";
$password2 = "Anggita123!";
$database2 = "radius";

$hostname3 = "192.168.99.252";
$username3 = "fausin";
$password3 = "anggita";
$database3 = "app";

$hostname4 = "192.168.99.102";
$username4 = "fausin";
$password4 = "Anggita123!";
$database4 = "radius";

$hostname5 = "192.168.99.96";
$username5 = "fausin";
$password5 = "anggita";
$database5 = "radius";

$connection = mysqli_connect($hostname, $username, $password, $database);
$connection2 = mysqli_connect($hostname2, $username2, $password2, $database2);
$connection3 = mysqli_connect($hostname3, $username3, $password3, $database3);
$connection4 = mysqli_connect($hostname4, $username4, $password4, $database4); // rabunan
$connection5 = mysqli_connect($hostname5, $username5, $password5, $database5); // KDS

if (!$connection) {
    die("Koneksi 1 gagal: " . mysqli_connect_error());
}

if (!$connection2) {
    die("Koneksi 2 gagal: " . mysqli_connect_error());
}

if (!$connection3) {
    die("Koneksi 3 gagal: " . mysqli_connect_error());
}

if (!$connection4) {
    die("Koneksi 4 gagal: " . mysqli_connect_error());
}

if (!$connection5) {
    die("Koneksi 5 gagal: " . mysqli_connect_error());
}

// Helper function for HTML escaping
if (!function_exists('e')) {
    function e($text) {
        return htmlspecialchars($text, ENT_QUOTES, 'UTF-8');
    }
}
?>