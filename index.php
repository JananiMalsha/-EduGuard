<?php
session_start();

// Not logged in -> go to login page
if (empty($_SESSION['user_id'])) {
  header('Location: login.php');
  exit;
}

// Logged in -> go to the dashboard for the user's role
$redirects = [
  'admin'   => 'admin/index.php',
  'teacher' => 'teacher/index.php',
  'gate'    => 'gate/index.php',
  'parent'  => 'parent/index.php',
  'student' => 'student/index.php',
];

$role = $_SESSION['role'] ?? '';
header('Location: ' . ($redirects[$role] ?? 'login.php'));
exit;
