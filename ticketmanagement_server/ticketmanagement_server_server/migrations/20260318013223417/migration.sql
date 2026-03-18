BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "emergency_contacts" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "phoneNumber" text NOT NULL,
    "description" text,
    "sortOrder" bigint NOT NULL
);


--
-- MIGRATION VERSION FOR ticketmanagement_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('ticketmanagement_server', '20260318013223417', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260318013223417', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();


COMMIT;
