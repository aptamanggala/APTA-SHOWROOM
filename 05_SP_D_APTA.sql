USE db_pbd_demo;

-- =====================================================
-- STORED PROCEDURE (1 buah): sp_buat_penjualan
-- Membuat transaksi penjualan satu barang per panggilan.
--   p_idpenjualan = 0 / NULL -> buat header penjualan baru (margin aktif otomatis)
--   p_idpenjualan = id lama  -> tambah barang ke penjualan itu
-- Isi SP: validasi -> header -> detail (harga dari fn_harga_jual) -> hitung subtotal, PPN 11%, total.
-- Insert detail_penjualan memicu trigger trg_detail_penjualan_ai (kartu stok keluar).
-- Semua validasi dilakukan SEBELUM ada data yang ditulis.
-- Transaksi (BEGIN/COMMIT) dipegang pemanggil, yaitu penjualan/tambah.php.
-- =====================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_buat_penjualan$$
CREATE PROCEDURE sp_buat_penjualan(
  IN    p_iduser       INT,
  IN    p_idbarang     INT,
  IN    p_jumlah       INT,
  INOUT p_idpenjualan  INT
)
BEGIN
  DECLARE v_idmargin INT;
  DECLARE v_stok     INT;
  DECLARE v_harga    INT;
  DECLARE v_sub      INT;
  DECLARE v_ppn      INT;

  -- ---- validasi ----
  IF p_jumlah IS NULL OR p_jumlah <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah harus lebih dari 0';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM `user` WHERE iduser = p_iduser) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User tidak ditemukan';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM barang WHERE idbarang = p_idbarang AND status = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Barang tidak ditemukan atau nonaktif';
  END IF;

  SELECT COALESCE((SELECT stock
                   FROM kartu_stok
                   WHERE idbarang = p_idbarang
                   ORDER BY idkartu_stok DESC
                   LIMIT 1), 0)
  INTO v_stok;

  IF v_stok < p_jumlah THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok tidak mencukupi';
  END IF;

  -- ---- header penjualan ----
  IF p_idpenjualan IS NULL OR p_idpenjualan = 0 THEN
    SELECT idmargin_penjualan INTO v_idmargin
    FROM margin_penjualan
    WHERE status = 1
    LIMIT 1;

    IF v_idmargin IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tidak ada margin penjualan yang aktif';
    END IF;

    INSERT INTO penjualan (iduser, idmargin_penjualan)
    VALUES (p_iduser, v_idmargin);

    SET p_idpenjualan = LAST_INSERT_ID();
  ELSEIF NOT EXISTS (SELECT 1 FROM penjualan WHERE idpenjualan = p_idpenjualan) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Penjualan tidak ditemukan';
  END IF;

  -- ---- detail penjualan (memicu trigger -> kartu_stok) ----
  SET v_harga = fn_harga_jual(p_idbarang);

  INSERT INTO detail_penjualan (harga_satuan, jumlah, subtotal, penjualan_idpenjualan, idbarang)
  VALUES (v_harga, p_jumlah, v_harga * p_jumlah, p_idpenjualan, p_idbarang);

  -- ---- total ----
  SELECT SUM(subtotal) INTO v_sub
  FROM detail_penjualan
  WHERE penjualan_idpenjualan = p_idpenjualan;

  SET v_ppn = ROUND(v_sub * 0.11);

  UPDATE penjualan
  SET subtotal_nilai = v_sub,
      ppn            = v_ppn,
      total_nilai    = v_sub + v_ppn
  WHERE idpenjualan = p_idpenjualan;
END$$

DELIMITER ;
