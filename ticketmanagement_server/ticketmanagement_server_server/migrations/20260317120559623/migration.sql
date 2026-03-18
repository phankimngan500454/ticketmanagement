BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "app_users" (
    "id" bigserial PRIMARY KEY,
    "username" text NOT NULL,
    "passwordHash" text NOT NULL,
    "fullName" text,
    "phone" text,
    "roleId" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "deptId" bigint
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "assets" (
    "id" bigserial PRIMARY KEY,
    "assetName" text NOT NULL,
    "assetType" text,
    "serialNumber" text
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "categories" (
    "id" bigserial PRIMARY KEY,
    "categoryName" text NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "departments" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ticket_comments" (
    "id" bigserial PRIMARY KEY,
    "ticketId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "commentText" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "tickets" (
    "id" bigserial PRIMARY KEY,
    "subject" text NOT NULL,
    "description" text,
    "status" text NOT NULL,
    "priority" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "requesterId" bigint NOT NULL,
    "assigneeId" bigint,
    "categoryId" bigint NOT NULL,
    "assetId" bigint,
    "proposedDeadline" timestamp without time zone,
    "finalDeadline" timestamp without time zone,
    "deadlineStatus" text,
    "adminNote" text,
    "proposedByUserId" bigint
);

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "ticket_comments"
    ADD CONSTRAINT "ticket_comments_fk_0"
    FOREIGN KEY("ticketId")
    REFERENCES "tickets"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "ticket_comments"
    ADD CONSTRAINT "ticket_comments_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "app_users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "tickets"
    ADD CONSTRAINT "tickets_fk_0"
    FOREIGN KEY("requesterId")
    REFERENCES "app_users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "tickets"
    ADD CONSTRAINT "tickets_fk_1"
    FOREIGN KEY("categoryId")
    REFERENCES "categories"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR ticketmanagement_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('ticketmanagement_server', '20260317120559623', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260317120559623', "timestamp" = now();

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
