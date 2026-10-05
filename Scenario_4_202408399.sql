DROP TABLE IF EXISTS dispensing_records;
DROP TABLE IF EXISTS medicines;

CREATE TABLE medicines (
    medicine_id SERIAL PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL,
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE dispensing_records (
    dispensing_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    medicine_id INTEGER REFERENCES medicines(medicine_id),
    quantity INTEGER NOT NULL,
    dispensing_status VARCHAR(20) NOT NULL
);


INSERT INTO medicines (medicine_name, stock_quantity)
VALUES
('Paracetamol', 100),
('Amoxicillin', 30),
('Vitamin C', 5);

SELECT * FROM medicines;

DO $$
DECLARE
    stock INTEGER;
BEGIN
    SELECT stock_quantity
    INTO stock
    FROM medicines
    WHERE medicine_id = 3;

    IF stock = 0 THEN
        RAISE NOTICE 'Medicine is out of stock';

    ELSIF stock <= 10 THEN
        RAISE NOTICE 'Medicine is low on stock';

    ELSE
        RAISE NOTICE 'Medicine is sufficiently stocked';
    END IF;
END $$;

DO $$
DECLARE
    review_day INTEGER := 1;
BEGIN
    WHILE review_day <= 3 LOOP
        RAISE NOTICE 'Stock review day: %', review_day;
        review_day := review_day + 1;
    END LOOP;
END $$;


DO $$
DECLARE
    shelf_check INTEGER;
BEGIN
    FOR shelf_check IN 1..3 LOOP
        RAISE NOTICE 'Shelf inspection number: %', shelf_check;
    END LOOP;
END $$;


CREATE OR REPLACE PROCEDURE dispense_medicine(
    p_student_number VARCHAR,
    p_medicine_id INTEGER,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    stock INTEGER;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Dispensing quantity must be greater than zero';
    END IF;

    SELECT stock_quantity
    INTO stock
    FROM medicines
    WHERE medicine_id = p_medicine_id;

    IF stock IS NULL THEN
        RAISE NOTICE 'Medicine does not exist';

    ELSIF p_quantity > stock THEN
        RAISE NOTICE 'Not enough medicine in stock';

    ELSE
        UPDATE medicines
        SET stock_quantity = stock_quantity - p_quantity
        WHERE medicine_id = p_medicine_id;

        INSERT INTO dispensing_records
        (student_number, medicine_id, quantity, dispensing_status)
        VALUES
        (p_student_number, p_medicine_id, p_quantity, 'DISPENSED');

        RAISE NOTICE 'Medicine dispensed successfully';
    END IF;
END;
$$;


CALL dispense_medicine('20260001', 1, 10);

CALL dispense_medicine('20260002', 2, 5);


CALL dispense_medicine('20260003', 3, 20);


SELECT * FROM medicines;

SELECT * FROM dispensing_records;


CREATE OR REPLACE PROCEDURE reverse_dispensing(
    p_dispensing_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_status VARCHAR(20);
    dispensed_quantity INTEGER;
    dispensed_medicine_id INTEGER;
BEGIN
    SELECT dispensing_status,
           quantity,
           medicine_id
    INTO current_status,
         dispensed_quantity,
         dispensed_medicine_id
    FROM dispensing_records
    WHERE dispensing_id = p_dispensing_id;

    IF current_status IS NULL THEN
        RAISE NOTICE 'Dispensing record does not exist';

    ELSIF current_status = 'REVERSED' THEN
        RAISE NOTICE 'Dispensing record has already been reversed';

    ELSE
        UPDATE dispensing_records
        SET dispensing_status = 'REVERSED'
        WHERE dispensing_id = p_dispensing_id;

        UPDATE medicines
        SET stock_quantity =
            stock_quantity + dispensed_quantity
        WHERE medicine_id = dispensed_medicine_id;

        RAISE NOTICE 'Dispensing reversed successfully';
    END IF;
END;
$$;


CALL reverse_dispensing(1);

CALL reverse_dispensing(1);


DO $$
DECLARE
    medicine_record RECORD;

    medicine_cursor CURSOR FOR
        SELECT medicine_name, stock_quantity
        FROM medicines
        WHERE stock_quantity <= 10;
BEGIN
    OPEN medicine_cursor;

    LOOP
        FETCH medicine_cursor INTO medicine_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Medicine: %, Stock remaining: %',
            medicine_record.medicine_name,
            medicine_record.stock_quantity;
    END LOOP;

    CLOSE medicine_cursor;
END $$;


DO $$
BEGIN
    CALL dispense_medicine('20260004', 1, -5);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Invalid negative quantity handled: %',
            SQLERRM;
END $$;


SELECT * FROM medicines;

SELECT * FROM dispensing_records;


