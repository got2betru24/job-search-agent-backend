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

-- ── Shared title filters ─────────────────────────────────────
-- Applied to job title during scrape. Regex patterns start with ^
SET @filters = JSON_ARRAY(
  '^.*engineering manager.*$',
  '^.*(manager|mgr)[,\s].*(engineer|tech|cloud|platform|infrastructure|data|machine learning|ml|ai|analytics|software|intelligence|devinfra|ci.cd|system).*$',
  '^.*(engineer|tech|cloud|platform|infrastructure|data|machine learning|ml|ai|analytics|software|intelligence|devinfra|system).*(manager|mgr).*$',
  '^.*(sr\.?\s*|senior\s*)(manager|mgr).*(engineer|tech|cloud|platform|infrastructure|data|machine learning|ml|ai|analytics|software|intelligence|devinfra|ci.cd|system).*$',
  '^.*director.*(engineer|tech|product|data|analytics|platform|cloud|software|architecture|infrastructure|machine learning|ml|ai).*$',
  '^.*product manager.*$',
  '^.*(manager|mgr)[,\s].*product.*$',
  '^.*(senior|staff|principal).*(engineer|developer|architect|data|analytics).*$',
  '^.*(engineer|developer|architect).*(senior|staff|principal|iv|v|vi|[456]).*$',
  '^.*tech lead.*$',
  '^.*lead.*(engineer|developer|architect|software).*$',
  '^.*(senior|staff|principal|lead).*(data engineer|data scientist|data analyst).*$',
  '^.*data (engineer|scientist|analyst|manager).*(senior|staff|principal|lead|iv|v|[456]).*$',
  '^.*(bi|business intelligence).*(engineer|manager|analyst).*$',
  '^.*analytics engineer.*$'
);

-- ── Sources ──────────────────────────────────────────────────
INSERT IGNORE INTO sources (company, url, active, filters, requires_js, extractor_type) VALUES

  -- ── Phenom People ────────────────────────────────────────
  -- Custom domain — extractor_type must be set explicitly
  -- ('Adobe',         'https://careers.adobe.com/us/en/search-results?ak=qdtahjmabsc2',  TRUE, @filters, FALSE, 'phenom'),
  ('Qualtrics',     'https://www.qualtrics.com/careers/us/en/search-results?m=3&location=Provo%2C%20Utah%2C%20United%20States', TRUE, @filters, FALSE, 'phenom'),

  -- ── Greenhouse ───────────────────────────────────────────
  -- Standard API slugs — URL is the boards.greenhouse.io board page
  ('BambooHR',      'https://boards.greenhouse.io/bamboohr17',      TRUE, @filters, FALSE, 'greenhouse'),
  ('Airbnb',        'https://boards.greenhouse.io/airbnb',      TRUE, @filters, FALSE, 'greenhouse'),
  ('Coinbase',      'https://boards.greenhouse.io/coinbase',    TRUE, @filters, FALSE, 'greenhouse'),
  ('Greenhouse',    'https://boards.greenhouse.io/greenhouse',  TRUE, @filters, FALSE, 'greenhouse'),
  ('Hightouch',     'https://boards.greenhouse.io/hightouch',   TRUE, @filters, FALSE, 'greenhouse'),
  ('HubSpot',       'https://boards.greenhouse.io/hubspotjobs', TRUE, @filters, FALSE, 'greenhouse'),
  ('Instacart',     'https://boards.greenhouse.io/instacart',   TRUE, @filters, FALSE, 'greenhouse'),
  ('onX',           'https://boards.greenhouse.io/onxmaps', TRUE, @filters, FALSE, 'greenhouse'),
  ('Pinterest',     'https://boards.greenhouse.io/pinterest',   TRUE, @filters, FALSE, 'greenhouse'),
  ('Podium',        'https://boards.greenhouse.io/podium81', TRUE, @filters, FALSE, 'greenhouse'),
  ('Samsara',       'https://boards.greenhouse.io/samsara',     TRUE, @filters, FALSE, 'greenhouse'),
  ('SoFi',          'https://boards.greenhouse.io/sofi',        TRUE, @filters, FALSE, 'greenhouse'),
  ('Stripe',        'https://boards.greenhouse.io/stripe',      TRUE, @filters, FALSE, 'greenhouse'),
  ('Vercel',        'https://boards.greenhouse.io/vercel',      TRUE, @filters, FALSE, 'greenhouse'),

  -- ── Lever ────────────────────────────────────────────────
  ('Pattern',       'https://jobs.lever.co/pattern?location=Lehi%2C%20UT%2C%20US', TRUE, @filters, FALSE, 'lever'),

  -- ── Ashby ────────────────────────────────────────────────
  ('Ashby',         'https://jobs.ashbyhq.com/ashby',           TRUE, @filters, FALSE, 'ashby'),
  ('Flock Safety',  'https://jobs.ashbyhq.com/flock%20safety',     TRUE, @filters, FALSE, 'ashby'),
  ('Paxos',         'https://jobs.ashbyhq.com/paxos',           TRUE, @filters, FALSE, 'ashby'),
  ('Weave',         'https://jobs.ashbyhq.com/weave',       TRUE, @filters, FALSE, 'ashby'),

  -- ── Workday ──────────────────────────────────────────────
  -- Full filtered URLs with facets
  ('Adobe',         'https://adobe.wd5.myworkdayjobs.com/external_experienced/?locations=3ba4ecdf4893100bc84cc1f4dd686d51&locations=3ba4ecdf4893100bc84b76b36f6e6d00&jobFamilyGroup=591af8b812fa10737af39db3d96eed9f',  TRUE, @filters, FALSE, 'workday'),
  ('CHG Healthcare','https://chghealthcare.wd1.myworkdayjobs.com/External?locations=7fac191808da1000c95ea011e1b50000&locations=7fac191808da1000c914942215910000&locations=7fac191808da1000c91485ab661e0000&locations=7fac191808da1000c95f70044a210000&jobFamily=7fac191808da1000c89c7bbd4a7a0000&jobFamily=7fac191808da1000c89c7ec201a00000', TRUE, @filters, FALSE, 'workday'),
  ('Dataminr',      'https://dataminr.wd12.myworkdayjobs.com/Dataminr?locations=2b4a1545fce5100313ff0545e6dc0000&jobFamilyGroup=2b4a1545fce5100313d91bbc119b0000&jobFamilyGroup=2b4a1545fce5100313d918bb15fe0000', TRUE, @filters, FALSE, 'workday'),
  ('Domo',          'https://domo.wd12.myworkdayjobs.com/DomoCareers?locations=93be2167cc4e100cffc70f43ea530000&locations=f09b6d3b2614100158e157311a920000', TRUE, @filters, FALSE, 'workday'),
  ('Fidelity',      'https://wd1.myworkdaysite.com/recruiting/fmr/FidelityCareers?jobFamilyGroup=e39fd413f80c0104eb5775256a997b12&jobFamilyGroup=4c9bbf7088c401011719f359748d0000&jobFamilyGroup=e39fd413f80c01c8934aaa256a998f12&locationRegionStateProvince=9bf006cfb5a44c51b84138e1a0e7d805', TRUE, @filters, FALSE, 'workday'),
  ('NVIDIA',        'https://nvidia.wd5.myworkdayjobs.com/NVIDIAExternalCareerSite?locationHierarchy1=2fcb99c455831013ea52fb338f2932d8&jobFamilyGroup=0c40f6bd1d8f10ae43ffaefd46dc7e78&jobFamilyGroup=0c40f6bd1d8f10ae43ffc8817cf47e8e&jobFamilyGroup=0c40f6bd1d8f10ae43ffc668c6847e8c&workerSubType=0c40f6bd1d8f10adf6dae2cd57444a16', TRUE, @filters, FALSE, 'workday'),
  ('Zillow',        'https://zillow.wd5.myworkdayjobs.com/Zillow_Group_External?locations=bf3166a9227a01f8b514f0b00b147bc9&jobFamilyGroup=a90eab1aaed6105e8dcac61d33c32ee2&jobFamilyGroup=a90eab1aaed6105e8dd41df427a82ee6&jobFamilyGroup=a90eab1aaed6105e8d9dc5ba8a722ecc', TRUE, @filters, FALSE, 'workday'),
  ('Waystar',       'https://waystar.wd1.myworkdayjobs.com/Waystar?locations=65142bd647b001b5690df61cd906665a&locations=65142bd647b001c176fcf01cd9064c5a&locations=65142bd647b001929acc0f1dd906cb5a&remoteType=2a1b330166191001a0abe860844f0000&remoteType=2a1b330166191001a0abe8fa60010001', TRUE, @filters, FALSE, 'workday'),
  
  -- Currently inactive due to too many results --
  ('Capital One',   'https://capitalone.wd12.myworkdayjobs.com/Capital_One?jobFamilyGroup=a12c70bf789e105802e9f44b764529b7&jobFamilyGroup=a12c70bf789e105802e9e79458dc29ab&workerSubType=a12c70bf789e10572aab8e8909a619ae&timeType=2ed180e199081055c65d9d6853aa022d', FALSE, @filters, FALSE, 'workday'),
  
  -- ── Oracle HCM Cloud ─────────────────────────────────────
  ('Oracle',        'https://eeho.fa.us2.oraclecloud.com/hcmUI/CandidateExperience/en/sites/jobsearch/jobs?locationId=300000000149325&locationLevel=country&selectedCategoriesFacet=300000001917356&selectedPostingDatesFacet=14', TRUE, @filters, FALSE, 'oracle'),
 
 -- ── Eightfold AI ──────────────────────────────────────────
  ('Netflix',       'https://explore.jobs.netflix.net/careers?query=manager&Teams=Engineering&domain=netflix.com', TRUE, @filters, FALSE, 'netflix'),
                    'https://explore.jobs.netflix.net/careers?query=manager&Teams=Data%20%26%20Insights&Teams=Engineering&Work%20Type=remote&Region=ucan&domain=netflix.com&sort_by=new'

  -- ── Requires JS — skipped until Playwright service is built ──
  ('Apollo',        'https://www.apollographql.com/careers#positions',      TRUE, @filters, TRUE, 'generic'),
  ('Atlassian',     'https://www.atlassian.com/company/careers/all-jobs?team=Engineering&location=United%20States', TRUE, @filters, TRUE, 'generic'),
  ('Hashicorp',     'https://www.ibm.com/careers/search?field_keyword_08[0]=Infrastructure%20%26%20Technology&field_keyword_08[1]=Software%20Engineering&field_keyword_08[2]=Product%20Management&field_keyword_08[3]=Data%20%26%20Analytics&field_keyword_05[0]=United%20States&sort=dcdate_desc', TRUE, @filters, TRUE, 'generic'),
  ('Meta',          'https://www.metacareers.com/jobsearch?roles[0]=Full%20time%20employment&q=manager&offices[0]=Remote%2C%20US', TRUE, @filters, TRUE, 'generic'),
  ('ServiceNow',    'https://careers.servicenow.com/jobs/?search=manager&country=United%20States&remote=true&pagesize=20#results', TRUE, @filters, TRUE, 'generic'),
  ('Vivint',        'https://careers.nrgenergy.com/SMARTHOMES/search/?q=&location=UT&sortColumn=referencedate&sortDirection=desc', TRUE, @filters, TRUE, 'generic'),
  
-- ============================================================
-- Base resumes (content to be updated via the UI or directly)
-- ============================================================

-- INSERT INTO resumes (name, content, role, is_base) VALUES
--     ('Base Resume — Engineering Manager', '[Upload your EM base resume via the UI]',      'engineering_manager', TRUE),
--     ('Base Resume — Engineer',            '[Upload your Engineer base resume via the UI]', 'engineer',            TRUE),
--     ('Base Resume — Product Manager',     '[Upload your PM base resume via the UI]',       'product_manager',     TRUE);