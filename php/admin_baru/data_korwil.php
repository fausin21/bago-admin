<?php
include 'kon.php';
$query = "SELECT * FROM setoran_korwil where ket='BL'";
$result = mysqli_query($koneksi, $query);

$data = array();
if (mysqli_num_rows($result) > 0) {
    while ($row = mysqli_fetch_assoc($result)) {
        $id = $row['id'];
        $korwil = $row['korwil'];
        $bulanan = $row['bulanan'];
        $voucher = $row['voucher'];
        $pppoe = $row['pppoe'];
        $total = $row['total'];
        $no_hp=$row['no_hp'];
        $ket = $row['ket'];

        $data[] = array(
            'id' => $id,
            'korwil' => $korwil,
            'bulanan' => $bulanan,
            'voucher' => $voucher,
            'pppoe' => $pppoe,
            'total' => $total,
            'ket' => $ket,
            'no_hp' => $no_hp
        );
    }
}

echo json_encode($data);

