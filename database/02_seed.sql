-- ============================================================
-- Job Search Agent — Seed Data
-- Sources: curated career pages to monitor
--
-- Run after 01_schema.sql:
--   docker exec -i mysql mysql -u root -p < sql/02_seed.sql
-- ============================================================


-- ============================================================
-- Title filters
-- Applied to every source. Lowercase keyword strings.
-- A job title must match at least one filter to be promoted.
-- Filters are case-insensitive substring matches unless the
-- value starts with ^ in which case it is treated as regex.
--
-- Current filters target:
--   - Engineering Manager roles
--   - Product Manager roles
--   - Senior/Staff/Principal individual contributor roles
-- ============================================================

SET @filters = JSON_ARRAY(
    'director engineering',
    'senior engineering manager',
    'engineering manager',
    'staff product manager',
    'principal product manager',
    'senior product manager',
    'product manager',
    'senior engineer',
    'senior software',
    'staff engineer',
    'staff software',
    'principal engineer',
    'principal software',
    'senior backend',
    'senior frontend',
    'senior fullstack',
    'senior full-stack',
    'engineering lead',
    'tech lead'
);

-- ============================================================
-- Sources
-- Replace placeholder URLs with your actual bookmarked
-- career page URLs. Set requires_js = TRUE for any pages
-- that need the Playwright scraper service instead of httpx.
-- ============================================================

INSERT INTO sources (company, url, active, filters, requires_js) VALUES
    ('Adobe',  'https://careers.adobe.com/us/en/search-results?ak=qdtahjmabsc2',       TRUE, @filters, FALSE),
    ('BambooHR',  'https://www.bamboohr.com/careers/#explore-all-bamboohr-jobs',       TRUE, @filters, FALSE);
    -- ('Company 03',  'https://company03.com/jobs',          TRUE, @filters, FALSE),
    -- ('Company 04',  'https://company04.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 05',  'https://company05.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 06',  'https://company06.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 07',  'https://company07.com/jobs',          TRUE, @filters, FALSE),
    -- ('Company 08',  'https://company08.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 09',  'https://company09.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 10',  'https://company10.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 11',  'https://company11.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 12',  'https://company12.com/jobs',          TRUE, @filters, FALSE),
    -- ('Company 13',  'https://company13.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 14',  'https://company14.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 15',  'https://company15.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 16',  'https://company16.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 17',  'https://company17.com/jobs',          TRUE, @filters, FALSE),
    -- ('Company 18',  'https://company18.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 19',  'https://company19.com/careers',       TRUE, @filters, FALSE),
    -- ('Company 20',  'https://company20.com/careers',       TRUE, @filters, FALSE);

-- ============================================================
-- Base resumes (content to be updated via the UI or directly)
-- ============================================================

INSERT INTO resumes (name, content, role, is_base) VALUES
    ('Base Resume — Engineering Manager', '[Upload your EM base resume via the UI]',      'engineering_manager', TRUE),
    ('Base Resume — Engineer',            '[Upload your Engineer base resume via the UI]', 'engineer',            TRUE),
    ('Base Resume — Product Manager',     '[Upload your PM base resume via the UI]',       'product_manager',     TRUE);