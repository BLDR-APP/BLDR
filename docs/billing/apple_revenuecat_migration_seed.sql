-- FULL APPLE LEGACY COHORT — REVIEW-ONLY. THIS FILE ALWAYS ROLLS BACK.
-- Fresh read-only audit: 82 technical pairs, 81 eligible + 1 review_required.
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

CREATE TEMP TABLE apple_rc_expected_cohort (
  user_id UUID PRIMARY KEY,
  legacy_subscription_id UUID UNIQUE NOT NULL,
  migration_status TEXT NOT NULL CHECK (
    migration_status IN ('eligible', 'review_required')
  )
) ON COMMIT DROP;

INSERT INTO apple_rc_expected_cohort (
  user_id, legacy_subscription_id, migration_status
) VALUES
  ('02ff429e-7d0c-4961-8dfe-b805479ba91d', '2997fb84-aadb-469e-b700-4c5f5aec13a1', 'eligible'),
  ('04bba80b-e80b-48b4-8aec-1ec312276327', 'ec081794-b0f1-4c13-a5cb-1ddbcc660fb8', 'eligible'),
  ('077b247c-3ea9-4b5a-83b6-594babeb170b', '26193444-141f-432f-a478-b1263905b277', 'eligible'),
  ('093a835d-26ca-4fdb-bbe2-4f6e6d6d60b9', '81b4e840-d79c-4226-8960-2cd387a4712d', 'eligible'),
  ('0a819f70-6cde-493b-b742-7fc4ea270ad9', 'd4133e83-2422-4c3a-9555-3a65d3750de0', 'eligible'),
  ('0b36f63d-fd4f-4cc6-b499-b9ace907bdc4', 'b4e184a8-8a88-4288-bd22-5dccbe081bde', 'eligible'),
  ('0ec630aa-e991-4810-b9c1-00c5dcec2b02', 'cb94ca4d-e655-4f67-9816-78f9402449f6', 'eligible'),
  ('1145b166-e202-47ad-b744-e2a303f7426a', 'ec1ff26c-3bf8-434a-b92f-58720bec9ad6', 'eligible'),
  ('17e7cc28-4f56-443d-a528-4bd33992f58c', '1cadcb17-d81b-412c-8c71-22e4898a7b86', 'eligible'),
  ('24cee9da-9f02-4225-a1ec-364f1f42542c', 'f80c8f35-3824-4dd0-ae3b-6ab94dd5dc8e', 'eligible'),
  ('33401c46-1d20-4353-b2f9-d7aa94c6e0cb', 'bfa6b4c6-be4c-462f-973e-72aeaa0d099f', 'eligible'),
  ('345ca599-3bbb-4397-9461-123f702d4c6e', 'af1097eb-d319-4b24-8483-bb4d10382e3d', 'eligible'),
  ('405224ba-e492-4d8d-ad06-87b4b4887d47', '4ffd9b92-3493-402a-a16c-4b91b9ae176d', 'eligible'),
  ('423b0549-868b-4c75-9400-2ab30ac998d0', '05a77432-41a4-4d86-9f6f-b60d398bc19a', 'eligible'),
  ('42453f71-1e84-4660-bc6e-67f00410876e', 'e799d944-679c-48cb-a0bd-1ea5d18fa314', 'eligible'),
  ('4484a51f-f6cf-43fd-b999-784bd3040b04', '2f235d56-6ad2-4559-ae95-7d99548030b4', 'eligible'),
  ('4b597cb1-15c2-4be4-a8b6-2542d11a76be', 'a84a1af8-ce12-4b4b-b431-5ebd9105b2e1', 'eligible'),
  ('4c02f641-0123-4767-aa02-8dc8eb7c0f8e', '165a2511-12e7-4831-ae38-27ac6653026b', 'eligible'),
  ('4c844ba5-b7c7-4a65-b97c-5172f86fcc9a', '160dcd80-4c2c-4dde-8acc-22edf7c3cca5', 'eligible'),
  ('4e564e33-5145-4a6d-b8de-c2e8f002d64a', '584229a6-827d-4378-9753-b5fd46dcd4c8', 'eligible'),
  ('53545863-a5cd-4ae6-bdc0-611fc5ce5c0e', '83ad5c2a-14d5-4a60-89c8-cad5d45c1fba', 'eligible'),
  ('560c5891-36d5-4505-96fb-efe378ca907c', '5865b958-36cd-488a-b2ba-ec76fbd1f6af', 'eligible'),
  ('577a7484-a3ba-48ed-a35b-bdb1ccc27003', '66e52104-eba5-4d1d-bade-d3ff54fed4af', 'eligible'),
  ('5f384eac-4e80-4da8-bc86-52dee5b25a23', 'fcd75104-324b-4526-a4db-645d752cdf4a', 'eligible'),
  ('618ea7d4-8393-464c-bbd0-5adb1e276703', '28f4db37-a6a6-4cbf-8cce-b89b70bba143', 'eligible'),
  ('64ae12e4-bcbb-4bb3-ba0e-e170d451858d', '8d470d1e-cb3a-436e-bfb4-2229c3e2d472', 'eligible'),
  ('64af0cfb-ef5c-4d59-bd11-8927374850c7', '69fc4388-b2ca-49c1-b417-c3ce6f81b994', 'eligible'),
  ('64b564db-7328-4d4a-8c9b-cfaba5690717', '4f5a5dae-591e-485b-9eb3-1a8160abd550', 'eligible'),
  ('65cb3808-59cb-436c-834f-62e2cc9fdcc9', '3ff75afd-ffbf-4eee-9d28-9cd9c8ce84ba', 'eligible'),
  ('68c6029b-ae52-41a9-b62d-505bc808123a', '22597658-9e58-48d2-8506-50744a5877f6', 'eligible'),
  ('6af5dfd4-c7a3-4747-ae5d-b3c7cf8f7edc', '9cb7c6fd-a740-425c-ada7-e28496c64aeb', 'eligible'),
  ('704f4bf9-de7d-442b-8bb5-cd8f403fde40', '6281497a-b0ce-498e-936c-bd5f0216e585', 'eligible'),
  ('715b3833-bc63-496e-893e-7584bf8295a1', '8ab27e43-f575-4c9a-aa84-b0f7a154a4e8', 'eligible'),
  ('72e1cc43-10eb-425b-9ed1-695183173e79', 'd7b2c609-2e61-4da7-9ce7-2da9a324aadb', 'eligible'),
  ('734dc100-c7a3-4864-96ef-7617a8a5fd07', '2ff21943-d549-4cfc-89f2-4c1dccf1eaea', 'eligible'),
  ('73f314ed-8e43-49fb-ad37-78a3aeade8a1', '2f440151-47fb-444e-b12a-293b95159a1d', 'eligible'),
  ('76ec2665-048f-477a-9958-b960b41584d5', 'fa2b2021-a582-41ed-91b9-ccc0b08a6a87', 'eligible'),
  ('78f137ac-6a62-4a94-83e3-ceaec3fceff7', '23bf9780-788e-4e20-81b2-3e8d2dd8e882', 'eligible'),
  ('7bd1c12a-29e0-4f14-8ad2-93599c227470', 'eb01cb0d-7538-4b66-8d67-5b0f6469a0f7', 'eligible'),
  ('7dfbee85-2851-44de-ae47-87bf88719d13', 'b5615c5b-bc66-482d-8439-eecb2ecab20a', 'eligible'),
  ('7f02e443-2614-4cae-a1fc-61399c33e43d', '5138c31f-1b44-4a28-afe4-d3816343acb0', 'eligible'),
  ('81efe0b7-cd42-4d22-b603-ed03814e9941', '895e1d55-2fc2-493f-8466-12e22a538d31', 'eligible'),
  ('82273a0c-eaee-48b4-8760-67f5a244e357', '34edbf0a-6141-43c1-be6e-9a1746e0deb4', 'eligible'),
  ('8dcc2e81-c9b0-4f81-8483-c76ba6809110', '83ad9162-b729-4215-9414-7f39bcdcb386', 'eligible'),
  ('90f656ca-bd5f-4be1-9bfc-8a492b816d8c', 'e801056a-2ca1-4c25-aebb-796db03c14cd', 'eligible'),
  ('916a2bfe-73e0-4a58-9eba-b5c046e10753', '1c85cb60-f362-4663-92d0-af278d21eee9', 'eligible'),
  ('922b1d7a-1e21-4760-b2d7-94148ab47cf6', '75cb3d4f-6b03-44ff-9954-f776503caea1', 'eligible'),
  ('92b4564d-766f-433a-b1bc-f0596ceb4f71', '2c5ef8da-cd3e-4162-a7f5-f3b7e46f4922', 'eligible'),
  ('95eafe52-d3b1-431e-9af3-1936a51efccd', 'e473dfda-5d0a-4a9e-b889-8ef3c22cbb25', 'eligible'),
  ('a09f950c-b8d8-49f4-9864-378c8472d573', 'a371de1b-994e-48d3-b207-a1bb1d6266d8', 'eligible'),
  ('a3a894e3-b61b-4804-8bd9-ffa2014ff8d7', '161ce9fa-bc7f-4b3e-b21c-fbdd4f58c867', 'eligible'),
  ('a4043d8a-2e40-4354-9d13-03b33253a4f1', '754d3d9c-264a-4ccf-b000-d17cf8efdf58', 'eligible'),
  ('b583d012-5bab-4bd2-a087-e5ad2e9d981f', '9b12a041-0caf-4771-9258-97079eb89a95', 'eligible'),
  ('b7bcedd5-bb64-469b-8a36-f4dfcd18ec4e', 'e6ac9eb4-ed5b-422d-86a4-d625a71c1b8a', 'eligible'),
  ('b855fed5-4165-4047-ac89-127cffb9d205', '946ed29e-b717-4a2f-b193-41ab9149038c', 'eligible'),
  ('bc297254-f35f-4b47-a8fb-30a13a85e3d5', '2d1e2b0a-804b-4a79-aa03-7f2b101ce954', 'eligible'),
  ('bcd041dc-b107-4b8f-b27b-dee618f25645', '8a3ce5f3-842f-4144-b978-8ed737911e43', 'eligible'),
  ('c2780671-1484-4673-817a-7821e8746694', 'e0962ae1-1eb9-4f74-b48c-d6159b3d7dc1', 'eligible'),
  ('c9534d27-1f39-446b-aad2-e0248ba50a1e', '08676fba-2ede-419d-b28d-1c91ca4a1a94', 'eligible'),
  ('caf0e337-0fdd-4de8-beab-278a6d69b1dd', 'd7a56e6d-b9ad-418f-9bb0-1020b60cf7f1', 'eligible'),
  ('ce2513c1-a975-47b3-b986-969b827a6717', '1a7ce981-5e2c-43bf-8e7d-6f5593150603', 'eligible'),
  ('cefff55e-d330-4a61-a3ef-4d140ac48cd5', 'e40f155a-95d3-4cf7-810d-637ac39a9713', 'eligible'),
  ('d0f58533-0ee3-4f10-9c32-e4717f67e3ca', 'd0bb6d95-c245-40a8-b585-f8b2d89ca94a', 'eligible'),
  ('d2b6121b-6c87-4824-86a1-e311a582c9a1', '23654635-5b7d-4d7d-9a9d-5048ae1683bf', 'eligible'),
  ('d4ceab43-23f5-4af0-a102-cf94c31ef2df', 'bccbdc20-8cf0-43c9-a399-44844fa19c49', 'eligible'),
  ('d555bb86-4978-434e-8c37-f08b174520b7', '10695c7c-38ea-48b4-bb8a-076375d16f44', 'eligible'),
  ('d7097f0c-c368-4a7a-9f58-e6f5921cb203', '1ff87a53-fbd9-44ca-8af4-353a11e08f2f', 'eligible'),
  ('dfc867a4-5373-4237-99d4-32037796a8f5', '4a3bba56-aa0e-4d63-b9ec-34254fa3e785', 'eligible'),
  ('e14714e8-f17d-48a5-bb8f-6545985d94e6', 'f9ccbf4b-f83d-4218-b672-a98c8a1e7766', 'eligible'),
  ('e9d5e2ec-357c-4f93-aa10-da9f53d82f8a', '761285c4-66df-4b04-9296-70d79b4a0050', 'eligible'),
  ('ea6a3e14-1bec-44ec-a918-97e5168642d2', '1e45f066-bf95-49a4-bcc2-54e9a056eeb5', 'eligible'),
  ('ec9d796f-6e3d-470f-b11c-fde1bcf1f4bb', 'f3ff4586-581d-47f1-b3cb-b9c370b95b3c', 'eligible'),
  ('ed4212ea-3092-40b3-b96c-e4bbf636f4d2', '6b5ba417-d58a-46ff-bd76-abe824840ca8', 'eligible'),
  ('ef08eb05-98b8-4eb3-8c98-8b86a2ca2f22', '724a64fd-60b1-4eba-bb6e-25ccdd59626a', 'eligible'),
  ('efc261ed-7429-4692-b253-6916c7dec07b', '125defbc-f6cf-4814-85ea-bca54b4e8774', 'eligible'),
  ('f07554fd-d1f0-485e-868f-d8cff67a141d', 'd7e51335-0060-4450-94c9-0a813c5eec68', 'review_required'),
  ('f1d67b84-720e-48dc-be9e-6d6cadc48f6b', '93b00ff1-0ff9-4987-8082-41fcc9416c9c', 'eligible'),
  ('f3c6603f-bb39-4933-9c47-233c44d944f9', 'ce949b21-853d-4cd2-bc87-880f13f4f6b9', 'eligible'),
  ('f4dc7944-99e3-444d-b934-5fc55cd4d324', '0d2877e2-aade-4996-8f2e-41ceb50f5bee', 'eligible'),
  ('f643ca07-e4a7-4536-baf7-c03ed777bf52', '89a0c8b1-ad1c-4556-9995-5ac7ed3d168b', 'eligible'),
  ('f8c13602-1151-42e4-b9e2-9e5d6da73a40', '46764a4c-ea42-41f9-8e69-d38245baada6', 'eligible'),
  ('fba0e99d-9a7a-46aa-972d-a619b92b4eaf', 'ce267688-82c5-4f1a-9b1c-3b7d223dbcbf', 'eligible');

-- Exact state already committed by the earlier controlled three-row seed.
CREATE TEMP TABLE apple_rc_expected_existing (
  user_id UUID PRIMARY KEY,
  legacy_subscription_id UUID UNIQUE NOT NULL,
  migration_status TEXT NOT NULL
) ON COMMIT DROP;

INSERT INTO apple_rc_expected_existing (
  user_id, legacy_subscription_id, migration_status
) VALUES
  ('92b4564d-766f-433a-b1bc-f0596ceb4f71', '2c5ef8da-cd3e-4162-a7f5-f3b7e46f4922', 'eligible'),
  ('c2780671-1484-4673-817a-7821e8746694', 'e0962ae1-1eb9-4f74-b48c-d6159b3d7dc1', 'eligible'),
  ('f07554fd-d1f0-485e-868f-d8cff67a141d', 'd7e51335-0060-4450-94c9-0a813c5eec68', 'review_required');

CREATE TEMP TABLE apple_rc_live_cohort ON COMMIT DROP AS
SELECT
  us.user_id,
  us.id AS legacy_subscription_id,
  CASE WHEN us.stripe_subscription_id IS NOT NULL
    THEN 'review_required' ELSE 'eligible' END AS migration_status
FROM public.user_subscriptions us
JOIN auth.users au ON au.id = us.user_id
WHERE (us.payment_provider = 'apple_iap' OR us.apple_product_id IS NOT NULL)
  AND us.status IN ('active', 'trialing')
  AND us.apple_product_id IN ('MENSAL', 'ANUAL')
  AND us.revenuecat_app_user_id IS NULL;

DO $guard$
BEGIN
  IF EXISTS (
    (SELECT * FROM apple_rc_expected_cohort EXCEPT SELECT * FROM apple_rc_live_cohort)
    UNION ALL
    (SELECT * FROM apple_rc_live_cohort EXCEPT SELECT * FROM apple_rc_expected_cohort)
  ) THEN
    RAISE EXCEPTION 'Apple migration cohort differs from pinned full cohort';
  END IF;

  -- Production must contain exactly the three rows inserted by the earlier
  -- controlled seed. Missing, additional, reclassified or swapped rows abort.
  IF EXISTS (
    (
      SELECT user_id, legacy_subscription_id, status
      FROM public.apple_revenuecat_migrations
      EXCEPT
      SELECT user_id, legacy_subscription_id, migration_status
      FROM apple_rc_expected_existing
    )
    UNION ALL
    (
      SELECT user_id, legacy_subscription_id, migration_status
      FROM apple_rc_expected_existing
      EXCEPT
      SELECT user_id, legacy_subscription_id, status
      FROM public.apple_revenuecat_migrations
    )
  ) THEN
    RAISE EXCEPTION 'Existing Apple migration state differs from pinned three-row baseline';
  END IF;
END
$guard$;

-- Repeat the source query immediately before INSERT; current_period_end is
-- intentionally absent because the forensic audit proved it non-authoritative.
CREATE TEMP TABLE apple_rc_revalidated ON COMMIT DROP AS
SELECT
  us.user_id,
  us.id AS legacy_subscription_id,
  CASE WHEN us.stripe_subscription_id IS NOT NULL
    THEN 'review_required' ELSE 'eligible' END AS migration_status
FROM public.user_subscriptions us
JOIN auth.users au ON au.id = us.user_id
WHERE (us.payment_provider = 'apple_iap' OR us.apple_product_id IS NOT NULL)
  AND us.status IN ('active', 'trialing')
  AND us.apple_product_id IN ('MENSAL', 'ANUAL')
  AND us.revenuecat_app_user_id IS NULL;

DO $revalidate$
BEGIN
  IF EXISTS (
    (SELECT * FROM apple_rc_expected_cohort EXCEPT SELECT * FROM apple_rc_revalidated)
    UNION ALL
    (SELECT * FROM apple_rc_revalidated EXCEPT SELECT * FROM apple_rc_expected_cohort)
  ) THEN
    RAISE EXCEPTION 'Apple migration cohort changed before insert';
  END IF;
END
$revalidate$;

INSERT INTO public.apple_revenuecat_migrations (
  user_id, legacy_subscription_id, status
)
SELECT r.user_id, r.legacy_subscription_id, r.migration_status
FROM apple_rc_revalidated r
LEFT JOIN public.apple_revenuecat_migrations m ON m.user_id = r.user_id
WHERE m.user_id IS NULL;

DO $result_guard$
BEGIN
  IF EXISTS (
    (
      SELECT user_id, legacy_subscription_id, status
      FROM public.apple_revenuecat_migrations
      EXCEPT
      SELECT user_id, legacy_subscription_id, migration_status
      FROM apple_rc_expected_cohort
    )
    UNION ALL
    (
      SELECT user_id, legacy_subscription_id, migration_status
      FROM apple_rc_expected_cohort
      EXCEPT
      SELECT user_id, legacy_subscription_id, status
      FROM public.apple_revenuecat_migrations
    )
  ) THEN
    RAISE EXCEPTION 'Prepared Apple migration state does not equal full cohort';
  END IF;
END
$result_guard$;

ROLLBACK;
