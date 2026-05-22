<?php
error_reporting(E_ALL & ~E_DEPRECATED & ~E_NOTICE & ~E_STRICT); ini_set("display_errors", 0);
// Version
define('VERSION', '3.0.3.2');

// Configuration
if (is_file('config.php')) {
	require_once('config.php');
}

// Install
if (!defined('DIR_APPLICATION')) {
	header('Location: install/index.php');
	exit;
}

// Startup
require_once(DIR_SYSTEM . 'startup.php');

start('catalog');