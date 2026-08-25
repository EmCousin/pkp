SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: attendance_record_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.attendance_record_status AS ENUM (
    'present',
    'absent',
    'excused'
);


--
-- Name: member_level; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.member_level AS ENUM (
    'white',
    'yellow',
    'green',
    'red'
);


--
-- Name: payment_method; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payment_method AS ENUM (
    'cash',
    'bank_transfer',
    'bank_check',
    'credit_card'
);


--
-- Name: advance_authentication_generation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.advance_authentication_generation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (
    NEW.encrypted_password IS DISTINCT FROM OLD.encrypted_password
    OR (OLD.locked_at IS NULL AND NEW.locked_at IS NOT NULL)
  ) AND NEW.authentication_generation = OLD.authentication_generation THEN
    NEW.authentication_generation = OLD.authentication_generation + 1;
  END IF;
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: action_mailbox_inbound_emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.action_mailbox_inbound_emails (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    message_checksum character varying NOT NULL,
    message_id character varying NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: action_mailbox_inbound_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.action_mailbox_inbound_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: action_mailbox_inbound_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.action_mailbox_inbound_emails_id_seq OWNED BY public.action_mailbox_inbound_emails.id;


--
-- Name: action_text_rich_texts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.action_text_rich_texts (
    id bigint NOT NULL,
    body text,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL,
    record_id bigint NOT NULL,
    record_type character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: action_text_rich_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.action_text_rich_texts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: action_text_rich_texts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.action_text_rich_texts_id_seq OWNED BY public.action_text_rich_texts.id;


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    name character varying NOT NULL,
    record_id bigint NOT NULL,
    record_type character varying NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    content_type character varying,
    created_at timestamp without time zone NOT NULL,
    filename character varying NOT NULL,
    key character varying NOT NULL,
    metadata text,
    service_name character varying NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: attendance_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendance_records (
    id bigint NOT NULL,
    attendance_sheet_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    member_id bigint NOT NULL,
    status public.attendance_record_status DEFAULT 'present'::public.attendance_record_status NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: attendance_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attendance_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attendance_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attendance_records_id_seq OWNED BY public.attendance_records.id;


--
-- Name: attendance_sheets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendance_sheets (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    date date NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: attendance_sheets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attendance_sheets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attendance_sheets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attendance_sheets_id_seq OWNED BY public.attendance_sheets.id;


--
-- Name: auth_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_sessions (
    id bigint NOT NULL,
    authentication_generation bigint DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    credential_fingerprint character varying NOT NULL,
    ip_address character varying,
    last_seen_at timestamp(6) without time zone NOT NULL,
    remembered_until timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL,
    user_agent character varying,
    user_id bigint NOT NULL
);


--
-- Name: auth_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auth_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auth_sessions_id_seq OWNED BY public.auth_sessions.id;


--
-- Name: billing_invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing_invoices (
    id bigint NOT NULL,
    amount numeric NOT NULL,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    currency character varying DEFAULT 'EUR'::character varying NOT NULL,
    customer_reference character varying NOT NULL,
    customer_snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    description text NOT NULL,
    error text,
    external_id bigint,
    invoiceable_id bigint NOT NULL,
    invoiceable_type character varying NOT NULL,
    issue_date date NOT NULL,
    label character varying NOT NULL,
    number character varying,
    provider character varying DEFAULT 'pennylane'::character varying NOT NULL,
    requested_at timestamp(6) without time zone NOT NULL,
    state character varying DEFAULT 'pending'::character varying NOT NULL,
    sync_token uuid NOT NULL,
    transaction_reference jsonb,
    updated_at timestamp(6) without time zone NOT NULL,
    vat_rate character varying DEFAULT 'FR_200'::character varying NOT NULL
);


--
-- Name: billing_invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.billing_invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: billing_invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.billing_invoices_id_seq OWNED BY public.billing_invoices.id;


--
-- Name: camps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camps (
    id bigint NOT NULL,
    active boolean,
    capacity integer,
    created_at timestamp(6) without time zone NOT NULL,
    ends_at date,
    external_price numeric NOT NULL,
    open boolean DEFAULT false NOT NULL,
    open_to_externals boolean DEFAULT false NOT NULL,
    platform_id bigint NOT NULL,
    price numeric,
    starts_at date,
    title character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    visible_to_externals boolean DEFAULT false NOT NULL
);


--
-- Name: camps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.camps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: camps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.camps_id_seq OWNED BY public.camps.id;


--
-- Name: camps_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camps_subscriptions (
    id bigint NOT NULL,
    camp_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    subscription_id bigint,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: camps_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.camps_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: camps_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.camps_subscriptions_id_seq OWNED BY public.camps_subscriptions.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    max_age integer NOT NULL,
    min_age integer NOT NULL,
    platform_id bigint NOT NULL,
    title character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacts (
    id bigint NOT NULL,
    confirmed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    email character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courses (
    id bigint NOT NULL,
    active boolean DEFAULT true,
    capacity integer NOT NULL,
    category_id bigint,
    created_at timestamp without time zone NOT NULL,
    description character varying,
    discovery_capacity integer,
    discovery_enabled boolean DEFAULT false NOT NULL,
    discovery_price numeric,
    features_attendance_sheet boolean DEFAULT false NOT NULL,
    title character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    weekday integer NOT NULL
);


--
-- Name: courses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.courses_id_seq OWNED BY public.courses.id;


--
-- Name: courses_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courses_subscriptions (
    id bigint NOT NULL,
    course_id bigint,
    created_at timestamp without time zone NOT NULL,
    subscription_id bigint,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: courses_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.courses_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: courses_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.courses_subscriptions_id_seq OWNED BY public.courses_subscriptions.id;


--
-- Name: discovery_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discovery_sessions (
    id bigint NOT NULL,
    active boolean DEFAULT false NOT NULL,
    capacity integer NOT NULL,
    course_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    occurs_on date,
    open boolean DEFAULT false NOT NULL,
    price numeric NOT NULL,
    starts_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: discovery_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discovery_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discovery_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discovery_sessions_id_seq OWNED BY public.discovery_sessions.id;


--
-- Name: members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.members (
    id bigint NOT NULL,
    agreed_to_advertising_right boolean DEFAULT false NOT NULL,
    birthdate date,
    contact_name character varying,
    contact_phone_number character varying,
    contact_relationship character varying,
    created_at timestamp(6) without time zone NOT NULL,
    first_name character varying,
    last_name character varying,
    level public.member_level DEFAULT 'white'::public.member_level NOT NULL,
    platform_id bigint NOT NULL,
    tombstoned_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint
);


--
-- Name: members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.members_id_seq OWNED BY public.members.id;


--
-- Name: platforms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platforms (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    domain character varying NOT NULL,
    medical_certificate_validity_seasons integer DEFAULT 3 NOT NULL,
    name character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT platforms_medical_certificate_validity_seasons_positive CHECK ((medical_certificate_validity_seasons > 0))
);


--
-- Name: platforms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.platforms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: platforms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.platforms_id_seq OWNED BY public.platforms.id;


--
-- Name: pricings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pricings (
    id bigint NOT NULL,
    category_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    ends_at date NOT NULL,
    name character varying NOT NULL,
    prices jsonb DEFAULT '[]'::jsonb NOT NULL,
    starts_at date NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT pricings_starts_at_before_or_equal_ends_at CHECK ((starts_at <= ends_at))
);


--
-- Name: pricings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pricings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pricings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pricings_id_seq OWNED BY public.pricings.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id bigint NOT NULL,
    attendance_status public.attendance_record_status,
    created_at timestamp without time zone NOT NULL,
    discovery_session_id bigint,
    doctor_certified_at timestamp(6) without time zone,
    fee numeric NOT NULL,
    member_id bigint,
    paid_at timestamp(6) without time zone,
    parent_subscription_id bigint,
    payment_method public.payment_method,
    status integer DEFAULT 0,
    stripe_charge_id character varying,
    stripe_payment_intent_id character varying,
    terms_accepted_at timestamp(6) without time zone,
    type character varying DEFAULT 'AnnualSubscription'::character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    year integer NOT NULL
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    address character varying,
    admin boolean DEFAULT false NOT NULL,
    authentication_generation bigint DEFAULT 0 NOT NULL,
    city character varying,
    coach boolean DEFAULT false NOT NULL,
    confirmation_sent_at timestamp without time zone,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    country character varying,
    created_at timestamp without time zone NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    locked_at timestamp without time zone,
    pennylane_customer_id bigint,
    phone_number character varying,
    remember_created_at timestamp without time zone,
    reset_password_sent_at timestamp without time zone,
    reset_password_token character varying,
    stripe_customer_id character varying,
    terms_of_service boolean DEFAULT false,
    unconfirmed_email character varying,
    unlock_token character varying,
    updated_at timestamp without time zone NOT NULL,
    zip_code character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: action_mailbox_inbound_emails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_mailbox_inbound_emails ALTER COLUMN id SET DEFAULT nextval('public.action_mailbox_inbound_emails_id_seq'::regclass);


--
-- Name: action_text_rich_texts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_text_rich_texts ALTER COLUMN id SET DEFAULT nextval('public.action_text_rich_texts_id_seq'::regclass);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: attendance_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_records ALTER COLUMN id SET DEFAULT nextval('public.attendance_records_id_seq'::regclass);


--
-- Name: attendance_sheets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_sheets ALTER COLUMN id SET DEFAULT nextval('public.attendance_sheets_id_seq'::regclass);


--
-- Name: auth_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_sessions ALTER COLUMN id SET DEFAULT nextval('public.auth_sessions_id_seq'::regclass);


--
-- Name: billing_invoices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_invoices ALTER COLUMN id SET DEFAULT nextval('public.billing_invoices_id_seq'::regclass);


--
-- Name: camps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camps ALTER COLUMN id SET DEFAULT nextval('public.camps_id_seq'::regclass);


--
-- Name: camps_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camps_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.camps_subscriptions_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: courses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses ALTER COLUMN id SET DEFAULT nextval('public.courses_id_seq'::regclass);


--
-- Name: courses_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.courses_subscriptions_id_seq'::regclass);


--
-- Name: discovery_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discovery_sessions ALTER COLUMN id SET DEFAULT nextval('public.discovery_sessions_id_seq'::regclass);


--
-- Name: members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members ALTER COLUMN id SET DEFAULT nextval('public.members_id_seq'::regclass);


--
-- Name: platforms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platforms ALTER COLUMN id SET DEFAULT nextval('public.platforms_id_seq'::regclass);


--
-- Name: pricings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricings ALTER COLUMN id SET DEFAULT nextval('public.pricings_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: action_mailbox_inbound_emails action_mailbox_inbound_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_mailbox_inbound_emails
    ADD CONSTRAINT action_mailbox_inbound_emails_pkey PRIMARY KEY (id);


--
-- Name: action_text_rich_texts action_text_rich_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_text_rich_texts
    ADD CONSTRAINT action_text_rich_texts_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: attendance_records attendance_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_pkey PRIMARY KEY (id);


--
-- Name: attendance_sheets attendance_sheets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_sheets
    ADD CONSTRAINT attendance_sheets_pkey PRIMARY KEY (id);


--
-- Name: auth_sessions auth_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT auth_sessions_pkey PRIMARY KEY (id);


--
-- Name: billing_invoices billing_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_invoices
    ADD CONSTRAINT billing_invoices_pkey PRIMARY KEY (id);


--
-- Name: camps camps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camps
    ADD CONSTRAINT camps_pkey PRIMARY KEY (id);


--
-- Name: camps_subscriptions camps_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camps_subscriptions
    ADD CONSTRAINT camps_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: courses_subscriptions courses_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses_subscriptions
    ADD CONSTRAINT courses_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: discovery_sessions discovery_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discovery_sessions
    ADD CONSTRAINT discovery_sessions_pkey PRIMARY KEY (id);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);


--
-- Name: platforms platforms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platforms
    ADD CONSTRAINT platforms_pkey PRIMARY KEY (id);


--
-- Name: pricings pricings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricings
    ADD CONSTRAINT pricings_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_action_mailbox_inbound_emails_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_action_mailbox_inbound_emails_uniqueness ON public.action_mailbox_inbound_emails USING btree (message_id, message_checksum);


--
-- Name: index_action_text_rich_texts_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_action_text_rich_texts_uniqueness ON public.action_text_rich_texts USING btree (record_type, record_id, name);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_attendance_records_on_attendance_sheet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attendance_records_on_attendance_sheet_id ON public.attendance_records USING btree (attendance_sheet_id);


--
-- Name: index_attendance_records_on_attendance_sheet_id_and_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_attendance_records_on_attendance_sheet_id_and_member_id ON public.attendance_records USING btree (attendance_sheet_id, member_id);


--
-- Name: index_attendance_records_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attendance_records_on_member_id ON public.attendance_records USING btree (member_id);


--
-- Name: index_attendance_records_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attendance_records_on_status ON public.attendance_records USING btree (status);


--
-- Name: index_attendance_sheets_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attendance_sheets_on_course_id ON public.attendance_sheets USING btree (course_id);


--
-- Name: index_attendance_sheets_on_course_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_attendance_sheets_on_course_id_and_date ON public.attendance_sheets USING btree (course_id, date);


--
-- Name: index_auth_sessions_on_last_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auth_sessions_on_last_seen_at ON public.auth_sessions USING btree (last_seen_at);


--
-- Name: index_auth_sessions_on_remembered_until; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auth_sessions_on_remembered_until ON public.auth_sessions USING btree (remembered_until);


--
-- Name: index_auth_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auth_sessions_on_user_id ON public.auth_sessions USING btree (user_id);


--
-- Name: index_billing_invoices_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_billing_invoices_on_external_id ON public.billing_invoices USING btree (external_id);


--
-- Name: index_billing_invoices_on_invoiceable_type_and_invoiceable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_billing_invoices_on_invoiceable_type_and_invoiceable_id ON public.billing_invoices USING btree (invoiceable_type, invoiceable_id);


--
-- Name: index_billing_invoices_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_billing_invoices_on_state ON public.billing_invoices USING btree (state);


--
-- Name: index_camps_on_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_camps_on_platform_id ON public.camps USING btree (platform_id);


--
-- Name: index_camps_subscriptions_on_camp_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_camps_subscriptions_on_camp_id ON public.camps_subscriptions USING btree (camp_id);


--
-- Name: index_camps_subscriptions_on_camp_id_and_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_camps_subscriptions_on_camp_id_and_subscription_id ON public.camps_subscriptions USING btree (camp_id, subscription_id);


--
-- Name: index_camps_subscriptions_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_camps_subscriptions_on_subscription_id ON public.camps_subscriptions USING btree (subscription_id);


--
-- Name: index_categories_on_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_platform_id ON public.categories USING btree (platform_id);


--
-- Name: index_categories_on_title; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_categories_on_title ON public.categories USING btree (title);


--
-- Name: index_contacts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_user_id ON public.contacts USING btree (user_id);


--
-- Name: index_courses_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_category_id ON public.courses USING btree (category_id);


--
-- Name: index_courses_subscriptions_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_subscriptions_on_course_id ON public.courses_subscriptions USING btree (course_id);


--
-- Name: index_courses_subscriptions_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_subscriptions_on_subscription_id ON public.courses_subscriptions USING btree (subscription_id);


--
-- Name: index_discovery_sessions_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discovery_sessions_on_course_id ON public.discovery_sessions USING btree (course_id);


--
-- Name: index_discovery_sessions_on_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discovery_sessions_on_starts_at ON public.discovery_sessions USING btree (starts_at);


--
-- Name: index_members_on_first_name_and_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_first_name_and_last_name ON public.members USING btree (first_name, last_name);


--
-- Name: index_members_on_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_level ON public.members USING btree (level);


--
-- Name: index_members_on_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_platform_id ON public.members USING btree (platform_id);


--
-- Name: index_members_on_tombstoned_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_tombstoned_at ON public.members USING btree (tombstoned_at);


--
-- Name: index_members_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_user_id ON public.members USING btree (user_id);


--
-- Name: index_one_annual_subscription_per_member_and_year; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_one_annual_subscription_per_member_and_year ON public.subscriptions USING btree (member_id, year) WHERE (((type)::text = 'AnnualSubscription'::text) AND (parent_subscription_id IS NULL));


--
-- Name: index_one_discovery_session_per_course_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_one_discovery_session_per_course_and_date ON public.discovery_sessions USING btree (course_id, occurs_on) WHERE (occurs_on IS NOT NULL);


--
-- Name: index_one_subscription_per_discovery_session_and_member; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_one_subscription_per_discovery_session_and_member ON public.subscriptions USING btree (discovery_session_id, member_id) WHERE (discovery_session_id IS NOT NULL);


--
-- Name: index_platforms_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_platforms_on_domain ON public.platforms USING btree (domain);


--
-- Name: index_platforms_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_platforms_on_name ON public.platforms USING btree (name);


--
-- Name: index_pricings_on_category_and_period; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pricings_on_category_and_period ON public.pricings USING btree (category_id, starts_at, ends_at);


--
-- Name: index_pricings_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pricings_on_category_id ON public.pricings USING btree (category_id);


--
-- Name: index_subscriptions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_created_at ON public.subscriptions USING btree (created_at DESC);


--
-- Name: index_subscriptions_on_discovery_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_discovery_session_id ON public.subscriptions USING btree (discovery_session_id);


--
-- Name: index_subscriptions_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_member_id ON public.subscriptions USING btree (member_id);


--
-- Name: index_subscriptions_on_parent_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_parent_subscription_id ON public.subscriptions USING btree (parent_subscription_id);


--
-- Name: index_subscriptions_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_status ON public.subscriptions USING btree (status);


--
-- Name: index_subscriptions_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_type ON public.subscriptions USING btree (type);


--
-- Name: index_subscriptions_on_year; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_year ON public.subscriptions USING btree (year);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_pennylane_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_pennylane_customer_id ON public.users USING btree (pennylane_customer_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: users advance_authentication_generation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER advance_authentication_generation BEFORE UPDATE OF encrypted_password, locked_at ON public.users FOR EACH ROW EXECUTE FUNCTION public.advance_authentication_generation();


--
-- Name: subscriptions fk_rails_00624c55e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_00624c55e7 FOREIGN KEY (discovery_session_id) REFERENCES public.discovery_sessions(id);


--
-- Name: members fk_rails_2e88fb7ce9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT fk_rails_2e88fb7ce9 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auth_sessions fk_rails_4aba5b3f33; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT fk_rails_4aba5b3f33 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: categories fk_rails_4bac149577; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_rails_4bac149577 FOREIGN KEY (platform_id) REFERENCES public.platforms(id);


--
-- Name: courses_subscriptions fk_rails_64502239ad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses_subscriptions
    ADD CONSTRAINT fk_rails_64502239ad FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: attendance_records fk_rails_7e8366fc95; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT fk_rails_7e8366fc95 FOREIGN KEY (attendance_sheet_id) REFERENCES public.attendance_sheets(id);


--
-- Name: subscriptions fk_rails_89bbaf9523; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_89bbaf9523 FOREIGN KEY (parent_subscription_id) REFERENCES public.subscriptions(id);


--
-- Name: contacts fk_rails_8d2134e55e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT fk_rails_8d2134e55e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: attendance_records fk_rails_95d17a0164; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT fk_rails_95d17a0164 FOREIGN KEY (member_id) REFERENCES public.members(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: discovery_sessions fk_rails_b15624b2db; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discovery_sessions
    ADD CONSTRAINT fk_rails_b15624b2db FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: attendance_sheets fk_rails_b9825f1ab0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_sheets
    ADD CONSTRAINT fk_rails_b9825f1ab0 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: subscriptions fk_rails_bfac3ecd2f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_bfac3ecd2f FOREIGN KEY (member_id) REFERENCES public.members(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: pricings fk_rails_c940c0d856; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricings
    ADD CONSTRAINT fk_rails_c940c0d856 FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: courses_subscriptions fk_rails_d8808d526c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses_subscriptions
    ADD CONSTRAINT fk_rails_d8808d526c FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- Name: courses fk_rails_e072dca946; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_e072dca946 FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: members fk_rails_e0c1de62fe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT fk_rails_e0c1de62fe FOREIGN KEY (platform_id) REFERENCES public.platforms(id);


--
-- Name: camps_subscriptions fk_rails_e258b84f2f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camps_subscriptions
    ADD CONSTRAINT fk_rails_e258b84f2f FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- Name: camps_subscriptions fk_rails_e41d2abf73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camps_subscriptions
    ADD CONSTRAINT fk_rails_e41d2abf73 FOREIGN KEY (camp_id) REFERENCES public.camps(id);


--
-- Name: camps fk_rails_ede9cab803; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camps
    ADD CONSTRAINT fk_rails_ede9cab803 FOREIGN KEY (platform_id) REFERENCES public.platforms(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260825130000'),
('20260825120000'),
('20260822120100'),
('20260822120000'),
('20260822100000'),
('20260818100000'),
('20260817120000'),
('20260812190029'),
('20260810120200'),
('20260810120100'),
('20260810120000'),
('20260802160000'),
('20260731090000'),
('20250812123801'),
('20250810205306'),
('20250809121000'),
('20250809120000'),
('20250731132118'),
('20250731125720'),
('20250731123852'),
('20250731123636'),
('20250724130132'),
('20250723085746'),
('20250722120955'),
('20250108155611'),
('20241231165711'),
('20241231165608'),
('20241229144841'),
('20230921072926'),
('20230821092659'),
('20230809123942'),
('20220911111331'),
('20210107170816'),
('20210107170815'),
('20200905145004'),
('20200905144322'),
('20200824141207'),
('20200801165709'),
('20200729103124'),
('20200714190059'),
('20200714180422'),
('20200602092126'),
('20200502160928'),
('20200502093733'),
('20200420152330'),
('20200419101726'),
('20200416150158'),
('20200208114530'),
('20191114141345'),
('20190930091608'),
('20190926141743'),
('20190918134530'),
('20190916093435'),
('20190902095405'),
('20190815131712');

