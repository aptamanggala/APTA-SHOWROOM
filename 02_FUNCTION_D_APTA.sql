USE db_pbd_demo;

DELIMITER $$

DROP FUNCTION IF EXISTS fn_harga_jual$$
CREATE FUNCTION fn_harga_jual(p_idbarang INT)
RETURNS INT
READS SQL DATA
BEGIN
  DECLARE v_harga  INT;
  DECLARE v_persen DOUBLE;

  SELECT harga INTO v_harga
  FROM barang
  WHERE idbarang = p_idbarang;

  IF v_harga IS NULL THEN
    RETURN 0;
  END IF;

  SELECT COALESCE(
           (SELECT persen FROM margin_penjualan WHERE status = 1 LIMIT 1),
           0)
  INTO v_persen;

  RETURN ROUND(v_harga * (1 + v_persen / 100));
END$$

DELIMITER ;
