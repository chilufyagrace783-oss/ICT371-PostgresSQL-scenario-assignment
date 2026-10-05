DROP TABLE IF EXISTS book_loans;
DROP TABLE IF EXISTS books;

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    available_copies INTEGER NOT NULL CHECK (available_copies >= 0)
);

CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    book_id INTEGER REFERENCES books(book_id),
    quantity INTEGER NOT NULL,
    loan_status VARCHAR(20) NOT NULL
);


INSERT INTO books (title, available_copies)
VALUES
('Database Systems', 10),
('Computer Networks', 4),
('Operating Systems', 1);

SELECT * FROM books;


DO $$
DECLARE
    copies INTEGER;
BEGIN
    SELECT available_copies
    INTO copies
    FROM books
    WHERE book_id = 3;

    IF copies = 0 THEN
        RAISE NOTICE 'Book is unavailable';
    ELSIF copies <= 2 THEN
        RAISE NOTICE 'Book has low copies';
    ELSE
        RAISE NOTICE 'Book is sufficiently stocked';
    END IF;
END $$;


DO $$
DECLARE
    counter INTEGER := 1;
BEGIN
    WHILE counter <= 3 LOOP
        RAISE NOTICE 'Overdue reminder number: %', counter;
        counter := counter + 1;
    END LOOP;
END $$;


DO $$
DECLARE
    shelf_number INTEGER;
BEGIN
    FOR shelf_number IN 1..3 LOOP
        RAISE NOTICE 'Library shelf number: %', shelf_number;
    END LOOP;
END $$;


CREATE OR REPLACE PROCEDURE borrow_book(
    p_student_number VARCHAR,
    p_book_id INTEGER,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    copies INTEGER;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero';
    END IF;

    SELECT available_copies
    INTO copies
    FROM books
    WHERE book_id = p_book_id;

    IF copies IS NULL THEN
        RAISE NOTICE 'Book does not exist';

    ELSIF p_quantity > copies THEN
        RAISE NOTICE 'Not enough copies available';

    ELSE
        UPDATE books
        SET available_copies = available_copies - p_quantity
        WHERE book_id = p_book_id;

        INSERT INTO book_loans
        (student_number, book_id, quantity, loan_status)
        VALUES
        (p_student_number, p_book_id, p_quantity, 'BORROWED');

        RAISE NOTICE 'Book borrowed successfully';
    END IF;
END;
$$;


CALL borrow_book('20260001', 1, 2);

CALL borrow_book('20260002', 2, 1);


CALL borrow_book('20260003', 3, 5);


SELECT * FROM books;

SELECT * FROM book_loans;


CREATE OR REPLACE PROCEDURE return_book(
    p_loan_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_status VARCHAR(20);
    returned_quantity INTEGER;
    returned_book_id INTEGER;
BEGIN
    SELECT loan_status, quantity, book_id
    INTO current_status, returned_quantity, returned_book_id
    FROM book_loans
    WHERE loan_id = p_loan_id;

    IF current_status IS NULL THEN
        RAISE NOTICE 'Loan does not exist';

    ELSIF current_status = 'RETURNED' THEN
        RAISE NOTICE 'Loan has already been returned';

    ELSE
        UPDATE book_loans
        SET loan_status = 'RETURNED'
        WHERE loan_id = p_loan_id;

        UPDATE books
        SET available_copies = available_copies + returned_quantity
        WHERE book_id = returned_book_id;

        RAISE NOTICE 'Book returned successfully';
    END IF;
END;
$$;


CALL return_book(1);

CALL return_book(1);


DO $$
DECLARE
    book_record RECORD;

    book_cursor CURSOR FOR
        SELECT title, available_copies
        FROM books
        WHERE available_copies <= 2;
BEGIN
    OPEN book_cursor;

    LOOP
        FETCH book_cursor INTO book_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Book: %, Copies remaining: %',
            book_record.title,
            book_record.available_copies;
    END LOOP;

    CLOSE book_cursor;
END $$;


DO $$
BEGIN
    CALL borrow_book('20260004', 1, 0);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Invalid quantity handled: %', SQLERRM;
END $$;


SELECT * FROM books;

SELECT * FROM book_loans;