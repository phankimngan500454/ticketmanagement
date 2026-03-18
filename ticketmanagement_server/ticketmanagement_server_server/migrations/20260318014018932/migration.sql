BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "emergency_contacts" ADD COLUMN "userId" bigint;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "emergency_contacts"
    ADD CONSTRAINT "emergency_contacts_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "app_users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR ticketmanagement_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('ticketmanagement_server', '20260318014018932', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260318014018932', "timestamp" = now();

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
