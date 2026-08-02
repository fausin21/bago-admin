<?php
/**
 * Get Auto Isolir Users
 * 
 * List semua pelanggan beserta status auto_isolir dan status bayar bulan ini.
 * 
 * URL: http://aplikasi.bago.web.id/api/admin/get_auto_isolir_users.php
 * Optional: ?auto_only=1 (hanya yg auto_isolir aktif)
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

include "connection.php";

$response = ['success' => false, 'data' => []];

try {
    $auto_only = isset($_GET['auto_only']) ? (int)$_GET['auto_only'] : 0;
    $bulan_ini = date('n');
    $tahun_ini = date('Y');

    // Query pelanggan dengan info tagihan bulan ini
    $where = $auto_only ? "WHERE p.auto_isolir = 1" : "";
    
    $query = "SELECT 
                p.id_pelanggan,
                p.nama,
                p.alamat,
                p.no_hp,
                p.auto_isolir,
                p.tgl_auto_isolir,
                p.id_paket,
                p.id_teknisi,
                pk.paket,
                pk.tarif,
                t.id_tagihan,
                t.status AS status_bayar,
                t.bulan,
                t.tahun,
                t.tgl_bayar
              FROM tb_pelanggan p
              LEFT JOIN tb_paket pk ON p.id_paket = pk.id_paket
              LEFT JOIN (
                  SELECT t1.* 
                  FROM tb_tagihan t1
                  INNER JOIN (
                      SELECT id_pelanggan, MAX(id_tagihan) as max_id
                      FROM tb_tagihan 
                      WHERE bulan = $bulan_ini AND tahun = $tahun_ini
                      GROUP BY id_pelanggan
                  ) t2 ON t1.id_tagihan = t2.max_id
              ) t ON p.id_pelanggan = t.id_pelanggan
              $where
              ORDER BY p.auto_isolir DESC, p.nama ASC";

    $result = mysqli_query($connection3, $query);

    if (!$result) {
        throw new Exception('Query error: ' . mysqli_error($connection3));
    }

    $data = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $status_bayar = 'BL'; // Belum bayar (default)
        if (!empty($row['status_bayar'])) {
            $status_bayar = $row['status_bayar'];
        }

        $data[] = [
            'id_pelanggan' => $row['id_pelanggan'],
            'nama' => $row['nama'],
            'alamat' => $row['alamat'] ?? '',
            'no_hp' => $row['no_hp'] ?? '',
            'auto_isolir' => (int)($row['auto_isolir'] ?? 0),
            'tgl_auto_isolir' => (int)($row['tgl_auto_isolir'] ?? 1),
            'nama_paket' => $row['paket'] ?? '',
            'harga_paket' => $row['tarif'] ?? '0',
            'status_bayar' => $status_bayar,
            'sudah_bayar' => in_array($status_bayar, ['LS', 'LS_ADMIN']) ? 1 : 0,
            'tgl_bayar' => $row['tgl_bayar'] ?? '',
            'bulan' => $row['bulan'] ?? $bulan_ini,
            'tahun' => $row['tahun'] ?? $tahun_ini
        ];
    }

    $response['success'] = true;
    $response['data'] = $data;
    $response['total'] = count($data);
    $response['total_auto_isolir'] = count(array_filter($data, function($d) { return $d['auto_isolir'] == 1; }));
    $response['total_belum_bayar'] = count(array_filter($data, function($d) { return $d['sudah_bayar'] == 0; }));
    $response['bulan'] = $bulan_ini;
    $response['tahun'] = $tahun_ini;

} catch (Exception $e) {
    $response['success'] = false;
    $response['message'] = $e->getMessage();
}

echo json_encode($response, JSON_PRETTY_PRINT);

if (isset($connection3)) mysqli_close($connection3);
?>
