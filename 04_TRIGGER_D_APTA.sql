USE db_pbd_demo;

-- =====================================================
-- TRIGGER (1 buah): trg_detail_penjualan_ai
-- Setiap baris baru di detail_penjualan otomatis:
--   1. dicek stoknya (ditolak jika stok kurang)
--   2. dicatat sebagai pengeluaran di kartu_stok (jenis 'J' = Penjualan)
-- Stok barang = nilai kolom stock pada baris kartu_stok terakhir.
-- =====================================================
DELIMITER $$

DROP TRIGGER IF EXISTS trg_detail_penjualan_ai$$
CREATE TRIGGER trg_detail_penjualan_ai
AFTER INSERT ON detail_penjualan
FOR EACH ROW
BEGIN
  DECLARE v_stok INT;

  SELECT COALESCE((SELECT stock
                   FROM kartu_stok
                   WHERE idbarang = NEW.idbarang
                   ORDER BY idkartu_stok DESC
                   LIMIT 1), 0)
  INTO v_stok;

  IF v_stok < NEW.jumlah THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok tidak mencukupi';
  END IF;

  INSERT INTO kartu_stok (jenis_transaksi, masuk, keluar, stock, idtransaksi, idbarang)
  VALUES ('J', 0, NEW.jumlah, v_stok - NEW.jumlah, NEW.penjualan_idpenjualan, NEW.idbarang);
END$$

DELIMITER ;
