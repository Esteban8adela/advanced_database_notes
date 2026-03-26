CREATE OR REPLACE TRIGGER trg_pet_care_log_insert
BEFORE INSERT ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    -- Asigna automáticamente la fecha/hora actual y el usuario
    :NEW.UPDATE_DATE := SYSDATE;
    :NEW.UPDATED_BY_USER := USER;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error inesperado en insert: ' || SQLERRM);
END;
/

CREATE OR REPLACE TRIGGER trg_pet_care_log_update
BEFORE UPDATE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    -- Verifica que el usuario que actualiza sea el que creó el registro
    IF USER != :OLD.UPDATED_BY_USER THEN
        RAISE_APPLICATION_ERROR(-20002, 'Update fallido: Solo puedes modificar registros que tú creaste.');
    END IF;

    -- Actualiza el timestamp para esta nueva modificación
    :NEW.UPDATE_DATE := SYSDATE;

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20002 THEN
            RAISE;
        ELSE
            RAISE_APPLICATION_ERROR(-20003, 'Error inesperado en update: ' || SQLERRM);
        END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_pet_care_log_delete
BEFORE DELETE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    -- Verifica si el usuario es el manager
    IF USER != 'JOEMANAGER' THEN
        RAISE_APPLICATION_ERROR(-20004, 'Delete fallido: Solo JOEMANAGER puede borrar registros.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20004 THEN
            RAISE; 
        ELSE
            RAISE_APPLICATION_ERROR(-20005, 'Error inesperado en delete: ' || SQLERRM);
        END IF;
END;
/