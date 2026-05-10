BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ticket_events" (
    "id" bigserial PRIMARY KEY,
    "ticketId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "eventType" text NOT NULL,
    "oldValue" text,
    "newValue" text,
    "description" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Index for fast lookup by ticketId
CREATE INDEX "ticket_events_ticketId_idx" ON "ticket_events" USING btree ("ticketId");

--
-- MIGRATION VERSION FOR ticketmanagement_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('ticketmanagement_server', '20260507003000000', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260507003000000', "timestamp" = now();

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
