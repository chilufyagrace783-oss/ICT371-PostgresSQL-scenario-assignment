DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS lab_sessions;

CREATE TABLE lab_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(100) NOT NULL,
    available_workstations INTEGER NOT NULL CHECK (available_workstations >= 0)
);

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    lecturer VARCHAR(100) NOT NULL,
    session_id INTEGER REFERENCES lab_sessions(session_id),
    workstations INTEGER NOT NULL,
    reservation_status VARCHAR(20) NOT NULL
);


INSERT INTO lab_sessions (session_name, available_workstations)
VALUES
('Database Practical',30),
('Networking Practical',15),
('Programming Practical',5);


SELECT * FROM lab_sessions;


DO $$
DECLARE
    workstations INTEGER;
BEGIN
    SELECT available_workstations
    INTO workstations
    FROM lab_sessions
    WHERE session_id = 3;

    IF workstations = 0 THEN
        RAISE NOTICE 'Session is full';

    ELSIF workstations <= 5 THEN
        RAISE NOTICE 'Session is nearly full';

    ELSE
        RAISE NOTICE 'Session has enough workstations';
    END IF;
END $$;


DO $$
DECLARE
    counter INTEGER := 1;
BEGIN
    WHILE counter <= 3 LOOP
        RAISE NOTICE 'Session preparation reminder %', counter;
        counter := counter + 1;
    END LOOP;
END $$;


DO $$
DECLARE
    workstation_check INTEGER;
BEGIN
    FOR workstation_check IN 1..3 LOOP
        RAISE NOTICE 'Workstation check number: %', workstation_check;
    END LOOP;
END $$;


CREATE OR REPLACE PROCEDURE reserve_workstations(
    p_lecturer VARCHAR,
    p_session_id INTEGER,
    p_workstations INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    available INTEGER;
BEGIN
    IF p_workstations <= 0 THEN
        RAISE EXCEPTION 'Number of workstations must be greater than zero';
    END IF;

    SELECT available_workstations
    INTO available
    FROM lab_sessions
    WHERE session_id = p_session_id;

    IF available IS NULL THEN
        RAISE NOTICE 'Session does not exist';

    ELSIF p_workstations > available THEN
        RAISE NOTICE 'Not enough workstations available';

    ELSE
        UPDATE lab_sessions
        SET available_workstations =
            available_workstations - p_workstations
        WHERE session_id = p_session_id;

        INSERT INTO reservations
        (lecturer, session_id, workstations, reservation_status)
        VALUES
        (p_lecturer, p_session_id, p_workstations, 'RESERVED');

        RAISE NOTICE 'Workstations reserved successfully';
    END IF;
END;
$$;


CALL reserve_workstations('Dr Banda', 1, 10);

CALL reserve_workstations('Dr Phiri', 2, 5);


CALL reserve_workstations('Dr Mwansa', 3, 10);


SELECT * FROM lab_sessions;

SELECT * FROM reservations;


CREATE OR REPLACE PROCEDURE cancel_reservation(
    p_reservation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_status VARCHAR(20);
    reserved_workstations INTEGER;
    reserved_session_id INTEGER;
BEGIN
    SELECT reservation_status,
           workstations,
           session_id
    INTO current_status,
         reserved_workstations,
         reserved_session_id
    FROM reservations
    WHERE reservation_id = p_reservation_id;

    IF current_status IS NULL THEN
        RAISE NOTICE 'Reservation does not exist';

    ELSIF current_status = 'CANCELLED' THEN
        RAISE NOTICE 'Reservation has already been cancelled';

    ELSE
        UPDATE reservations
        SET reservation_status = 'CANCELLED'
        WHERE reservation_id = p_reservation_id;

        UPDATE lab_sessions
        SET available_workstations =
            available_workstations + reserved_workstations
        WHERE session_id = reserved_session_id;

        RAISE NOTICE 'Reservation cancelled successfully';
    END IF;
END;
$$;


CALL cancel_reservation(1);

CALL cancel_reservation(1);


DO $$
DECLARE
    session_record RECORD;

    session_cursor CURSOR FOR
        SELECT session_name, available_workstations
        FROM lab_sessions
        WHERE available_workstations <= 5;
BEGIN
    OPEN session_cursor;

    LOOP
        FETCH session_cursor INTO session_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Session: %, Workstations remaining: %',
            session_record.session_name,
            session_record.available_workstations;
    END LOOP;

    CLOSE session_cursor;
END $$;


DO $$
BEGIN
    CALL reserve_workstations('Dr Tembo', 1, 0);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Invalid workstation quantity handled: %',
            SQLERRM;
END $$;


SELECT * FROM lab_sessions;

SELECT * FROM reservations;


