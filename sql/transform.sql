
-- 2018-06-05 pak joshua request update 18 ke 69
-- stasiun lama: https://inatide-hubla.com/owner/private_station/18?from=list
-- stasiun baru: https://inatide-hubla.com/owner/private_station/69?from=list
UPDATE station_logs SET station_id = 69 WHERE station_id = 18;
-- UPDATE 145032
UPDATE station_hours SET sid = 69 WHERE sid = 18;
-- UPDATE 928
UPDATE station_minutes SET sid = 69 WHERE sid = 18;
-- UPDATE 53812

-- backup and remove youtube

UPDATE stories26 
SET data=jsonb_merge(data,
('{"youtube":null,"youtube_backup":"' || (data->>'youtube') || '"}')::JSONB)
WHERE COALESCE(data->>'youtube','') <> ''
  AND is_deleted = false
;
UPDATE stories21
SET data=jsonb_merge(data,
('{"youtube":null,"youtube_backup":"' || (data->>'youtube') || '"}')::JSONB)
WHERE COALESCE(data->>'youtube','') <> ''
  AND is_deleted = false
;
UPDATE stories22 
SET data=jsonb_merge(data,
('{"youtube":null,"youtube_backup":"' || (data->>'youtube') || '"}')::JSONB)
WHERE COALESCE(data->>'youtube','') <> ''
  AND is_deleted = false
;
UPDATE stories20 
SET data=jsonb_merge(data,
('{"youtube":null,"youtube_backup":"' || (data->>'youtube') || '"}')::JSONB)
WHERE COALESCE(data->>'youtube','') <> ''
  AND is_deleted = false
;

-- restore

UPDATE stories26 
SET data=jsonb_merge(data,
('{"youtube_backup":null,"youtube":"' || (data->>'youtube_backup') || '"}')::JSONB)
WHERE COALESCE(data->>'youtube_backup','') <> ''
  AND is_deleted = false
;
UPDATE stories21
SET data=jsonb_merge(data,
('{"youtube_backup":null,"youtube":"' || (data->>'youtube_backup') || '"}')::JSONB)
WHERE COALESCE(data->>'youtube_backup','') <> ''
  AND is_deleted = false
;
UPDATE stories22
SET data=jsonb_merge(data,
('{"youtube_backup":null,"youtube":"' || (data->>'youtube_backup') || '"}')::JSONB)
WHERE COALESCE(data->>'youtube_backup','') <> ''
  AND is_deleted = false
;
UPDATE stories20
SET data=jsonb_merge(data,
('{"youtube_backup":null,"youtube":"' || (data->>'youtube_backup') || '"}')::JSONB)
WHERE COALESCE(data->>'youtube_backup','') <> ''
  AND is_deleted = false
;