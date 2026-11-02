<?php
// Laporan stok (sp_laporan_stok) dan kartu stok per barang (sp_kartu_stok_barang).
require __DIR__ . '/../includes/crud.php';

$judul     = 'Stok';
$kodeAktif = 'stok';
$base      = '../';
$errDb     = '';
$stok      = [];
$kartu     = [];
$idKartu   = (int) ($_GET['id'] ?? 0);

try {
    $st = db()->query('CALL sp_laporan_stok()');
    $stok = $st->fetchAll();
    $st->closeCursor();

    if ($idKartu > 0) {
        $st = db()->prepare('CALL sp_kartu_stok_barang(?)');
        $st->execute([$idKartu]);
        $kartu = $st->fetchAll();
        $st->closeCursor();
    }
} catch (PDOException $e) {
    $errDb = pesan_db($e);
}

include __DIR__ . '/../includes/header.php'; ?>
<?php if ($errDb): ?><div class="pesan err"><?= h($errDb) ?></div><?php endif; ?>

<div class="kotak"><table>
    <tr><th>ID</th><th>Barang</th><th>Satuan</th><th class="angka">Harga</th><th class="angka">Harga jual</th><th class="angka">Stok</th><th></th></tr>
    <?php if (!$stok): ?><tr><td colspan="7" class="kosong">Belum ada barang aktif.</td></tr><?php endif; ?>
    <?php foreach ($stok as $r): ?>
        <tr>
            <td><?= h($r['idbarang']) ?></td>
            <td><?= h($r['nama']) ?></td>
            <td><?= h($r['nama_satuan']) ?></td>
            <td class="angka"><?= tampil_nilai($r['harga'], 'juta') ?></td>
            <td class="angka"><?= tampil_nilai($r['harga_jual'], 'juta') ?></td>
            <td class="angka"><?= h($r['stok']) ?></td>
            <td class="aksi"><a class="btn" href="?id=<?= urlencode((string) $r['idbarang']) ?>">Kartu stok</a></td>
        </tr>
    <?php endforeach; ?>
</table></div>

<?php if ($idKartu > 0): ?>
    <h1 style="margin-top:28px">Kartu stok barang #<?= h($idKartu) ?></h1>
    <div class="kotak"><table>
        <tr><th>Waktu</th><th>Transaksi</th><th>ID transaksi</th><th class="angka">Masuk</th><th class="angka">Keluar</th><th class="angka">Stok</th></tr>
        <?php if (!$kartu): ?><tr><td colspan="6" class="kosong">Belum ada mutasi stok.</td></tr><?php endif; ?>
        <?php foreach ($kartu as $r): ?>
            <tr>
                <td><?= h($r['created_at']) ?></td>
                <td><?= h($r['jenis_transaksi']) ?></td>
                <td><?= h($r['idtransaksi']) ?></td>
                <td class="angka"><?= h($r['masuk']) ?></td>
                <td class="angka"><?= h($r['keluar']) ?></td>
                <td class="angka"><?= h($r['stock']) ?></td>
            </tr>
        <?php endforeach; ?>
    </table></div>
<?php endif; ?>
<?php include __DIR__ . '/../includes/footer.php';
