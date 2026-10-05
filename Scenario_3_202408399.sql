DROP TABLE IF EXISTS allocations;
DROP TABLE IF EXISTS hostel_rooms;

CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    room_name VARCHAR(50) NOT NULL,
    available_bed_spaces INTEGER NOT NULL CHECK (available_bed_spaces >= 0)
);

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    room_id INTEGER REFERENCES hostel_rooms(room_id),
    allocation_status VARCHAR(20) NOT NULL
);


INSERT INTO hostel_rooms (room_name, available_bed_spaces)
VALUES
('Block A Room 101', 4),
('Block B Room 202', 2),
('Block C Room 303', 0);


DO $$
DECLARE
    spaces INTEGER;
BEGIN
    SELECT available_bed_spaces
    INTO spaces
    FROM hostel_rooms
    WHERE room_id = 3;

    IF spaces = 0 THEN
        RAISE NOTICE 'Room is full';

    ELSIF spaces = 1 THEN
        RAISE NOTICE 'Room has one space left';

    ELSE
        RAISE NOTICE 'Room has several spaces';
    END IF;
END $$;


DO $$
DECLARE
    day_counter INTEGER := 1;
BEGIN
    WHILE day_counter <= 3 LOOP
        RAISE NOTICE 'Hostel inspection day: %', day_counter;
        day_counter := day_counter + 1;
    END LOOP;
END $$;


DO $$
DECLARE
    room_check INTEGER;
BEGIN
    FOR room_check IN 1..3 LOOP
        RAISE NOTICE 'Room check number: %', room_check;
    END LOOP;
END $$;


CREATE OR REPLACE PROCEDURE allocate_room(
    p_student_number VARCHAR,
    p_room_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    spaces INTEGER;
BEGIN
    IF p_student_number IS NULL OR trim(p_student_number) = '' THEN
        RAISE EXCEPTION 'Student number cannot be blank';
    END IF;

    SELECT available_bed_spaces
    INTO spaces
    FROM hostel_rooms
    WHERE room_id = p_room_id;

    IF spaces IS NULL THEN
        RAISE NOTICE 'Room does not exist';

    ELSIF spaces <= 0 THEN
        RAISE NOTICE 'Room is full';

    ELSE
        UPDATE hostel_rooms
        SET available_bed_spaces =
            available_bed_spaces - 1
        WHERE room_id = p_room_id;

        INSERT INTO allocations
        (student_number, room_id, allocation_status)
        VALUES
        (p_student_number, p_room_id, 'ALLOCATED');

        RAISE NOTICE 'Room allocated successfully';
    END IF;
END;
$$;


CALL allocate_room('20260001', 1);

CALL allocate_room('20260002', 2);


CALL allocate_room('20260003', 3);


SELECT * FROM hostel_rooms;

SELECT * FROM allocations;


CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_status VARCHAR(20);
    allocated_room INTEGER;
BEGIN
    SELECT allocation_status,
           room_id
    INTO current_status,
         allocated_room
    FROM allocations
    WHERE allocation_id = p_allocation_id;

    IF current_status IS NULL THEN
        RAISE NOTICE 'Allocation does not exist';

    ELSIF current_status = 'CHECKED_OUT' THEN
        RAISE NOTICE 'Student has already checked out';

    ELSE
        UPDATE allocations
        SET allocation_status = 'CHECKED_OUT'
        WHERE allocation_id = p_allocation_id;

        UPDATE hostel_rooms
        SET available_bed_spaces =
            available_bed_spaces + 1
        WHERE room_id = allocated_room;

        RAISE NOTICE 'Student checked out successfully';
    END IF;
END;
$$;


CALL check_out(1);

CALL check_out(1);


DO $$
DECLARE
    room_record RECORD;

    room_cursor CURSOR FOR
        SELECT room_name, available_bed_spaces
        FROM hostel_rooms
        WHERE available_bed_spaces <= 1;
BEGIN
    OPEN room_cursor;

    LOOP
        FETCH room_cursor INTO room_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Room: %, Spaces remaining: %',
            room_record.room_name,
            room_record.available_bed_spaces;
    END LOOP;

    CLOSE room_cursor;
END $$;


DO $$
BEGIN
    CALL allocate_room('', 1);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Invalid student number handled: %',
            SQLERRM;
END $$;


SELECT * FROM hostel_rooms;

SELECT * FROM allocations;

