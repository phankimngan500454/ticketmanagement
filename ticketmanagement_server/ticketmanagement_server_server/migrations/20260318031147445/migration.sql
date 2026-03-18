BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ticket_attachments" (
    "id" bigserial PRIMARY KEY,
    "ticketId" bigint NOT NULL,
    "uploaderId" bigint NOT NULL,
    "fileName" text NOT NULL,
    "mimeType" text NOT NULL,
    "fileData" text NOT NULL,
    "fileSize" bigint NOT NULL,
    "uploadedAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "ticket_attachments"
    ADD CONSTRAINT "ticket_attachments_fk_0"
    FOREIGN KEY("ticketId")
    REFERENCES "tickets"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR ticketmanagement_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('ticketmanagement_server', '20260318031147445', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260318031147445', "timestamp" = now();

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
