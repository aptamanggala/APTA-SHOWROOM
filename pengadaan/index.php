<?php
require __DIR__ . '/../includes/crud.php';

$judul     = 'Pengadaan';
$kodeAktif = 'pengadaan';
$base      = '../';
$baris     = [];
$errDb     = '';

$nama_status = ['P' => 'Proses', 'S' => 'Selesai'];
$fs          = (string) ($_GET['f_status'] ?? '');
$where       = isset($nama_status[$fs]) ? 'WHERE p.status = ?' : '';

try {
    $s = db()->prepare(
        "SELECT p.idpengadaan, p.`timestamp` AS waktu, v.nama_vendor, u.username, p.status,
                p.subtotal_nilai, p.ppn, p.total_nilai
         FROM pengadaan p
         JOIN vendor v ON v.idvendor = p.vendor_idvendor
         JOIN `user` u ON u.iduser = p.user_iduser
         $where
         ORDER BY p.idpengadaan DESC"
    );
    $s->execute($where ? [$fs] : []);
    $baris = $s->fetchAll();
} catch (PDOException $e) {
    $errDb = pesan_db($e);
}

include __DIR__ . '/../includes/header.php'; ?>
<?php if ($errDb): ?><div class="pesan err"><?= h($errDb) ?></div><?php endif; ?>

<div class="filter">
    <span class="label">Status</span>
    <div class="pills">
        <a class="pill<?= $fs === '' ? ' aktif' : '' ?>" href="?">Semua</a>
        <?php foreach ($nama_status as $kode => $label): ?>
            <a class="pill<?= $fs === $kode ? ' aktif' : '' ?>" href="?f_status=<?= h($kode) ?>"><?= h($label) ?></a>
        <?php endforeach; ?>
    </div>
</div>

<div class="bar">
    <span><?= count($baris) ?> data</span>
    <a class="btn utama" href="tambah.php">Tambah pengadaan</a>
</div>
<div class="kotak"><table>
    <tr><th>ID</th><th>Waktu</th><th>Vendor</th><th>User</th><th>Status</th>
        <th class="angka">Subtotal</th><th class="angka">PPN</th><th class="angka">Total</th><th></th></tr>
    <?php if (!$baris): ?><tr><td colspan="9" class="kosong">Tidak ada data.</td></tr><?php endif; ?>
    <?php foreach ($baris as $r): ?>
        <tr>
            <td><?= h($r['idpengadaan']) ?></td>
            <td><?= h($r['waktu']) ?></td>
            <td><?= h($r['nama_vendor']) ?></td>
            <td><?= h($r['username']) ?></td>
            <td><?= h($nama_status[$r['status']] ?? $r['status']) ?></td>
            <td class="angka"><?= tampil_nilai($r['subtotal_nilai'], 'juta') ?></td>
            <td class="angka"><?= tampil_nilai($r['ppn'], 'juta') ?></td>
            <td class="angka"><?= tampil_nilai($r['total_nilai'], 'juta') ?></td>
            <td class="aksi"><a class="btn" href="detail.php?id=<?= urlencode((string) $r['idpengadaan']) ?>">Detail</a></td>
        </tr>
    <?php endforeach; ?>
</table></div>
<?php include __DIR__ . '/../includes/footer.php';
