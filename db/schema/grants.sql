DO $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM pg_catalog.pg_roles
         WHERE rolname = 'inspector'
    ) THEN
        ALTER ROLE inspector WITH LOGIN PASSWORD 'NetoSQL2025';
    ELSE
        CREATE ROLE inspector LOGIN PASSWORD 'NetoSQL2025';
    END IF;
END;
$$;

GRANT ALL PRIVILEGES ON SCHEMA fetisov_food TO inspector;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA fetisov_food TO inspector;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA fetisov_food TO inspector;
GRANT EXECUTE ON ALL ROUTINES IN SCHEMA fetisov_food TO inspector;

GRANT USAGE ON SCHEMA information_schema, pg_catalog, exts TO inspector;
GRANT EXECUTE ON FUNCTION exts.uuid_generate_v4() TO inspector;
