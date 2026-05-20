-- OpenCart 3.x Admin User Setup
-- Default credentials: admin / Geau@3x$
-- Run this after OpenCart installation

INSERT INTO `oc_user` (`user_group_id`, `username`, `salt`, `password`, `firstname`, `lastname`, `email`, `code`, `ip`, `status`, `date_added`)
SELECT 1, 'admin', salt, password, 'Admin', 'User', 'admin@example.com', '', '0.0.0.0', 1, NOW()
FROM (SELECT SUBSTRING(MD5(RAND()), 1, 9) AS salt) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM `oc_user` WHERE username = 'admin');
